#!/usr/bin/env python3
"""
Script to add CNAME records to Route53
Automatically finds the appropriate hosted zone based on the domain
"""

import boto3
import argparse
import sys
from botocore.exceptions import ClientError, NoCredentialsError


def find_hosted_zone(route53_client, domain_name):
    """Find the hosted zone for the given domain"""
    try:
        response = route53_client.list_hosted_zones()
        hosted_zones = response['HostedZones']
        
        # Remove trailing dot from domain if present
        domain_name = domain_name.rstrip('.')
        
        # Find matching hosted zones (exact match or parent domain)
        matches = []
        for zone in hosted_zones:
            zone_name = zone['Name'].rstrip('.')
            if domain_name.endswith(zone_name):
                matches.append((zone, len(zone_name)))
        
        if not matches:
            return None
        
        # Return the most specific match (longest zone name)
        best_match = max(matches, key=lambda x: x[1])
        return best_match[0]
        
    except ClientError as e:
        print(f"Error listing hosted zones: {e}")
        return None


def check_existing_record(route53_client, hosted_zone_id, cname):
    """Check if CNAME record already exists"""
    try:
        response = route53_client.list_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            StartRecordName=cname,
            StartRecordType='CNAME'
        )
        
        # Ensure cname ends with dot for comparison
        if not cname.endswith('.'):
            cname += '.'
        
        for record_set in response['ResourceRecordSets']:
            if record_set['Name'] == cname and record_set['Type'] == 'CNAME':
                return {
                    'exists': True,
                    'current_value': record_set['ResourceRecords'][0]['Value'],
                    'current_ttl': record_set['TTL']
                }
        
        return {
            'exists': False,
            'current_value': None,
            'current_ttl': None
        }
        
    except ClientError as e:
        print(f"Warning: Could not check existing records: {e}")
        return {
            'exists': False,
            'current_value': None,
            'current_ttl': None
        }


def get_relative_record_name(cname, zone_name):
    """Get the record name relative to the hosted zone"""
    # Remove trailing dots and convert to lowercase for comparison
    cname_clean = cname.rstrip('.').lower()
    zone_clean = zone_name.rstrip('.').lower()
    
    # If the cname ends with the zone name, remove it to show only the relative part
    if cname_clean.endswith('.' + zone_clean):
        relative_name = cname_clean[:-len('.' + zone_clean)]
        return relative_name if relative_name else '@'  # '@' represents the zone apex
    elif cname_clean == zone_clean:
        return '@'  # Zone apex
    else:
        return cname_clean  # Return as-is if it doesn't match the zone


def confirm_action(cname, cname_value, zone_name, zone_id, ttl, existing_record=None):
    """Ask for user confirmation before making changes"""
    relative_name = get_relative_record_name(cname, zone_name)
    full_name = f"{relative_name}.{zone_name}" if relative_name != '@' else zone_name
    
    print("\n" + "="*70)
    print("CONFIRMATION - Review the changes to be made:")
    print("="*70)
    print(f"Hosted Zone:     {zone_name}")
    print(f"Zone ID:         {zone_id}")
    print(f"Record Type:     CNAME")
    print(f"Record Name:     {relative_name}")
    print(f"Full Name:       {full_name}")
    
    if existing_record and existing_record['exists']:
        print(f"Current Value:   {existing_record['current_value']}")
        print(f"Current TTL:     {existing_record['current_ttl']} seconds")
        print(f"New Value:       {cname_value}")
        print(f"New TTL:         {ttl} seconds")
        print(f"Action:          UPDATE (Overwrite existing record)")
        print("="*70)
        print("⚠️  WARNING: This will OVERWRITE the existing CNAME record!")
    else:
        print(f"Record Value:    {cname_value}")
        print(f"TTL:             {ttl} seconds")
        print(f"Action:          CREATE (New record)")
        print("="*70)
        print("✅ This will CREATE a new CNAME record.")
    
    print("="*70)
    
    while True:
        if existing_record and existing_record['exists']:
            response = input("\nDo you want to OVERWRITE the existing record? (y/N): ").strip().lower()
        else:
            response = input("\nDo you want to CREATE this record? (y/N): ").strip().lower()
            
        if response in ['y', 'yes']:
            return True
        elif response in ['n', 'no', '']:
            return False
        else:
            print("Please enter 'y' for yes or 'n' for no.")


def add_cname_record(route53_client, hosted_zone_id, cname, cname_value, ttl=300):
    """Add CNAME record to Route53"""
    try:
        # Ensure cname ends with a dot (Route53 requirement)
        if not cname.endswith('.'):
            cname += '.'
        # Ensure cname_value ends with a dot (Route53 requirement)
        if not cname_value.endswith('.'):
            cname_value += '.'
        
        change_batch = {
            'Comment': f'Adding CNAME record for {cname}',
            'Changes': [
                {
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': cname,
                        'Type': 'CNAME',
                        'TTL': ttl,
                        'ResourceRecords': [
                            {
                                'Value': cname_value
                            }
                        ]
                    }
                }
            ]
        }
        
        response = route53_client.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch=change_batch
        )
        
        return response['ChangeInfo']
        
    except ClientError as e:
        print(f"Error adding CNAME record: {e}")
        return None


def get_user_input():
    """Collect all required information from user interactively"""
    print("Route53 CNAME Record Manager")
    print("=" * 40)
    
    # Get CNAME record name
    while True:
        cname = input("Enter CNAME record name (e.g., www.example.com): ").strip()
        if cname:
            break
        print("CNAME record name cannot be empty. Please try again.")
    
    # Get CNAME record value
    while True:
        cname_value = input("Enter CNAME record value (e.g., example.amazonaws.com): ").strip()
        if cname_value:
            break
        print("CNAME record value cannot be empty. Please try again.")
    
    # Get TTL (optional)
    while True:
        ttl_input = input("Enter TTL in seconds (default: 300): ").strip()
        if not ttl_input:
            ttl = 300
            break
        try:
            ttl = int(ttl_input)
            if ttl > 0:
                break
            else:
                print("TTL must be a positive integer. Please try again.")
        except ValueError:
            print("TTL must be a valid number. Please try again.")
    
    # Get AWS profile (optional)
    profile = input("Enter AWS profile (default: cmi-security): ").strip() or "cmi-security"
    
    # Get AWS region (optional)
    region = input("Enter AWS region (default: us-east-1): ").strip() or "us-east-1"
    
    return cname, cname_value, ttl, profile, region


def main():
    parser = argparse.ArgumentParser(description='Add CNAME record to Route53')
    parser.add_argument('cname', nargs='?', help='CNAME record name (e.g., www.example.com)')
    parser.add_argument('cname_value', nargs='?', help='CNAME record value (e.g., example.amazonaws.com)')
    parser.add_argument('--ttl', type=int, default=300, help='TTL in seconds (default: 300)')
    parser.add_argument('--profile', default='cmi-security', help='AWS profile to use (default: cmi-security)')
    parser.add_argument('--region', default='us-east-1', help='AWS region (default: us-east-1)')
    parser.add_argument('--yes', '-y', action='store_true', help='Skip confirmation prompt')
    parser.add_argument('--interactive', '-i', action='store_true', help='Interactive mode (prompt for all inputs)')
    
    args = parser.parse_args()
    
    # Use interactive mode if no arguments provided or --interactive flag is used
    if args.interactive or (not args.cname or not args.cname_value):
        cname, cname_value, ttl, profile, region = get_user_input()
    else:
        cname = args.cname
        cname_value = args.cname_value
        ttl = args.ttl
        profile = args.profile or "cmi-security"
        region = args.region
    
    try:
        # Initialize boto3 session
        session_kwargs = {'region_name': region}
        if profile:
            session_kwargs['profile_name'] = profile
            
        session = boto3.Session(**session_kwargs)
        route53_client = session.client('route53')
        
        print(f"\nLooking for hosted zone for domain: {cname}")
        
        # Find the appropriate hosted zone
        hosted_zone = find_hosted_zone(route53_client, cname)
        
        if not hosted_zone:
            print(f"Error: No hosted zone found for domain {cname}")
            sys.exit(1)
        
        zone_name = hosted_zone['Name'].rstrip('.')
        zone_id = hosted_zone['Id'].replace('/hostedzone/', '')
        
        print(f"Found hosted zone: {zone_name} (ID: {zone_id})")
        
        # Check if record already exists
        print("Checking for existing CNAME record...")
        existing_record = check_existing_record(route53_client, zone_id, cname)
        
        if existing_record['exists']:
            current_value = existing_record['current_value'].rstrip('.')
            new_value = cname_value.rstrip('.')
            
            if current_value == new_value and existing_record['current_ttl'] == ttl:
                print(f"✅ Record already exists with the same value and TTL.")
                print(f"   {cname} -> {current_value} (TTL: {ttl}s)")
                print("No changes needed. Exiting.")
                sys.exit(0)
        
        # Ask for confirmation unless --yes flag is used
        if not args.yes:
            if not confirm_action(cname, cname_value, zone_name, zone_id, ttl, existing_record):
                print("Operation cancelled by user.")
                sys.exit(0)
        
        print(f"\nProceeding to add CNAME record: {cname} -> {cname_value}")
        
        change_info = add_cname_record(
            route53_client, 
            zone_id, 
            cname, 
            cname_value, 
            ttl
        )
        
        if change_info:
            print(f"Success! CNAME record added.")
            print(f"Change ID: {change_info['Id']}")
            print(f"Status: {change_info['Status']}")
            print(f"Submitted at: {change_info['SubmittedAt']}")
        else:
            print("Failed to add CNAME record")
            sys.exit(1)
            
    except NoCredentialsError:
        print("Error: AWS credentials not found. Please configure your credentials.")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()