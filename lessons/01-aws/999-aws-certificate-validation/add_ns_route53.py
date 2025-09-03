#!/usr/bin/env python3
"""
Script to add NS records to Route53
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


def check_existing_record(route53_client, hosted_zone_id, ns_name):
    """Check if NS record already exists"""
    try:
        response = route53_client.list_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            StartRecordName=ns_name,
            StartRecordType='NS'
        )
        
        # Ensure ns_name ends with dot for comparison
        if not ns_name.endswith('.'):
            ns_name += '.'
        
        for record_set in response['ResourceRecordSets']:
            if record_set['Name'] == ns_name and record_set['Type'] == 'NS':
                return {
                    'exists': True,
                    'current_values': [rr['Value'] for rr in record_set['ResourceRecords']],
                    'current_ttl': record_set['TTL']
                }
        
        return {
            'exists': False,
            'current_values': None,
            'current_ttl': None
        }
        
    except ClientError as e:
        print(f"Warning: Could not check existing records: {e}")
        return {
            'exists': False,
            'current_values': None,
            'current_ttl': None
        }


def get_relative_record_name(ns_name, zone_name):
    """Get the record name relative to the hosted zone"""
    # Remove trailing dots and convert to lowercase for comparison
    ns_name_clean = ns_name.rstrip('.').lower()
    zone_clean = zone_name.rstrip('.').lower()
    
    # If the ns_name ends with the zone name, remove it to show only the relative part
    if ns_name_clean.endswith('.' + zone_clean):
        relative_name = ns_name_clean[:-len('.' + zone_clean)]
        return relative_name if relative_name else '@'  # '@' represents the zone apex
    elif ns_name_clean == zone_clean:
        return '@'  # Zone apex
    else:
        return ns_name_clean  # Return as-is if it doesn't match the zone


def confirm_action(ns_name, ns_values, zone_name, zone_id, ttl, existing_record=None):
    """Ask for user confirmation before making changes"""
    relative_name = get_relative_record_name(ns_name, zone_name)
    full_name = f"{relative_name}.{zone_name}" if relative_name != '@' else zone_name
    
    print("\n" + "="*70)
    print("CONFIRMATION - Review the changes to be made:")
    print("="*70)
    print(f"Hosted Zone:     {zone_name}")
    print(f"Zone ID:         {zone_id}")
    print(f"Record Type:     NS")
    print(f"Record Name:     {relative_name}")
    print(f"Full Name:       {full_name}")
    
    if existing_record and existing_record['exists']:
        print(f"Current Values:  {', '.join(existing_record['current_values'])}")
        print(f"Current TTL:     {existing_record['current_ttl']} seconds")
        print(f"New Values:      {', '.join(ns_values)}")
        print(f"New TTL:         {ttl} seconds")
        print(f"Action:          UPDATE (Overwrite existing record)")
        print("="*70)
        print("⚠️  WARNING: This will OVERWRITE the existing NS record!")
    else:
        print(f"Record Values:   {', '.join(ns_values)}")
        print(f"TTL:             {ttl} seconds")
        print(f"Action:          CREATE (New record)")
        print("="*70)
        print("✅ This will CREATE a new NS record.")
    
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


def add_ns_record(route53_client, hosted_zone_id, ns_name, ns_values, ttl=300):
    """Add NS record to Route53"""
    try:
        # Ensure ns_name ends with a dot (Route53 requirement)
        if not ns_name.endswith('.'):
            ns_name += '.'
        
        # Ensure all ns_values end with a dot (Route53 requirement)
        ns_values_formatted = []
        for value in ns_values:
            if not value.endswith('.'):
                value += '.'
            ns_values_formatted.append(value)
        
        change_batch = {
            'Comment': f'Adding NS record for {ns_name}',
            'Changes': [
                {
                    'Action': 'UPSERT',
                    'ResourceRecordSet': {
                        'Name': ns_name,
                        'Type': 'NS',
                        'TTL': ttl,
                        'ResourceRecords': [
                            {'Value': value} for value in ns_values_formatted
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
        print(f"Error adding NS record: {e}")
        return None


def get_user_input():
    """Collect all required information from user interactively"""
    print("Route53 NS Record Manager")
    print("=" * 40)
    
    # Get NS record name
    while True:
        ns_name = input("Enter NS record name (e.g., subdomain.example.com): ").strip()
        if ns_name:
            break
        print("NS record name cannot be empty. Please try again.")
    
    # Get NS record values
    ns_values = []
    print("\nEnter NS record values (nameservers):")
    print("Option 1: Enter one per line (empty line to finish)")
    print("Option 2: Enter all on one line separated by commas or spaces")
    print("Option 3: Paste multiline text with nameservers")
    
    first_input = input("Enter NS values: ").strip()
    
    if not first_input:
        # Option 1: One per line
        print("Enter one nameserver per line (empty line when done):")
        while True:
            ns_value = input(f"NS value #{len(ns_values) + 1} (e.g., ns1.example.com): ").strip()
            if not ns_value:
                if ns_values:
                    break
                else:
                    print("You must enter at least one NS record value.")
                    continue
            ns_values.append(ns_value)
    else:
        # Check if it contains commas or multiple words (Option 2)
        if ',' in first_input or len(first_input.split()) > 1:
            # Split by comma first, then by whitespace
            for part in first_input.replace(',', ' ').split():
                if part.strip():
                    ns_values.append(part.strip())
        else:
            # Single nameserver on first line
            ns_values.append(first_input)
            
            # Continue reading additional lines for multiline input (Option 3)
            print("Continue entering nameservers (empty line to finish):")
            while True:
                try:
                    additional_line = input().strip()
                    if not additional_line:
                        break
                    
                    # Handle multiple nameservers in one line
                    if ',' in additional_line or len(additional_line.split()) > 1:
                        for part in additional_line.replace(',', ' ').split():
                            if part.strip():
                                ns_values.append(part.strip())
                    else:
                        ns_values.append(additional_line)
                except EOFError:
                    # Handle Ctrl+D or EOF
                    break
    
    if not ns_values:
        print("Error: No nameservers provided.")
        return get_user_input()
    
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
    
    return ns_name, ns_values, ttl, profile, region


def main():
    parser = argparse.ArgumentParser(description='Add NS record to Route53')
    parser.add_argument('ns_name', nargs='?', help='NS record name (e.g., subdomain.example.com)')
    parser.add_argument('ns_values', nargs='*', help='NS record values (nameservers)')
    parser.add_argument('--ttl', type=int, default=300, help='TTL in seconds (default: 300)')
    parser.add_argument('--profile', default='cmi-security', help='AWS profile to use (default: cmi-security)')
    parser.add_argument('--region', default='us-east-1', help='AWS region (default: us-east-1)')
    parser.add_argument('--yes', '-y', action='store_true', help='Skip confirmation prompt')
    parser.add_argument('--interactive', '-i', action='store_true', help='Interactive mode (prompt for all inputs)')
    
    args = parser.parse_args()
    
    # Use interactive mode if no arguments provided or --interactive flag is used
    if args.interactive or (not args.ns_name or not args.ns_values):
        ns_name, ns_values, ttl, profile, region = get_user_input()
    else:
        ns_name = args.ns_name
        ns_values = args.ns_values
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
        
        print(f"\nLooking for hosted zone for domain: {ns_name}")
        
        # Find the appropriate hosted zone
        hosted_zone = find_hosted_zone(route53_client, ns_name)
        
        if not hosted_zone:
            print(f"Error: No hosted zone found for domain {ns_name}")
            sys.exit(1)
        
        zone_name = hosted_zone['Name'].rstrip('.')
        zone_id = hosted_zone['Id'].replace('/hostedzone/', '')
        
        print(f"Found hosted zone: {zone_name} (ID: {zone_id})")
        
        # Check if record already exists
        print("Checking for existing NS record...")
        existing_record = check_existing_record(route53_client, zone_id, ns_name)
        
        if existing_record['exists']:
            current_values = [v.rstrip('.') for v in existing_record['current_values']]
            new_values = [v.rstrip('.') for v in ns_values]
            
            if set(current_values) == set(new_values) and existing_record['current_ttl'] == ttl:
                print(f"✅ Record already exists with the same values and TTL.")
                print(f"   {ns_name} -> {', '.join(current_values)} (TTL: {ttl}s)")
                print("No changes needed. Exiting.")
                sys.exit(0)
        
        # Ask for confirmation unless --yes flag is used
        if not args.yes:
            if not confirm_action(ns_name, ns_values, zone_name, zone_id, ttl, existing_record):
                print("Operation cancelled by user.")
                sys.exit(0)
        
        print(f"\nProceeding to add NS record: {ns_name} -> {', '.join(ns_values)}")
        
        change_info = add_ns_record(
            route53_client, 
            zone_id, 
            ns_name, 
            ns_values, 
            ttl
        )
        
        if change_info:
            print(f"Success! NS record added.")
            print(f"Change ID: {change_info['Id']}")
            print(f"Status: {change_info['Status']}")
            print(f"Submitted at: {change_info['SubmittedAt']}")
        else:
            print("Failed to add NS record")
            sys.exit(1)
            
    except NoCredentialsError:
        print("Error: AWS credentials not found. Please configure your credentials.")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()