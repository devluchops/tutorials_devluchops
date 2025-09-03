# AWS IAM Identity Center Setup Guide

Complete guide to set up IAM Identity Center (AWS SSO) for managing multiple AWS accounts with single sign-on.

## Prerequisites

- **AWS Organization** set up (required for Identity Center)
- **Management account** access (where you'll enable Identity Center)
- Multiple AWS accounts in your organization
- A domain for email addresses (optional but recommended)

## Step 1: Enable AWS Organizations (if not already enabled)

### 1.1 Create AWS Organization

```bash
# From your management account
aws organizations create-organization --feature-set ALL
```

Or via AWS Console:
1. Go to **AWS Organizations** console
2. Click **Create organization**
3. Select **Enable all features**

### 1.2 Add Accounts to Organization

You can either:
- **Create new accounts** within the organization
- **Invite existing accounts** to join

```bash
# Create a new account
aws organizations create-account \
    --email devops@yourdomain.com \
    --account-name "Production Account"

# Invite existing account
aws organizations invite-account-to-organization \
    --target Id=111111111111,Type=ACCOUNT
```

## Step 2: Enable IAM Identity Center

### 2.1 Enable Identity Center

1. Go to **IAM Identity Center** console in your management account
2. Choose your preferred region (us-east-1 recommended)
3. Click **Enable**

```bash
# Via CLI (optional)
aws sso-admin create-instance \
    --region us-east-1
```

### 2.2 Choose Identity Source

**Option A: Identity Center Directory (Recommended for small teams)**
- Built-in user directory
- Simple to manage
- Good for up to 50-100 users

**Option B: External Identity Provider (For larger organizations)**
- Microsoft Active Directory
- Azure AD
- Google Workspace
- Other SAML 2.0 providers

For this guide, we'll use **Identity Center Directory**.

## Step 3: Create Users and Groups

### 3.1 Create Groups

1. Go to **Groups** in Identity Center console
2. Create groups based on your organizational structure:

```
DevOps-Admins        # Full admin access to all accounts
Developers           # Development environment access
Production-Admins    # Production account access only
Security-Team        # Security and compliance access
Finance-Team         # Billing and cost management
```

### 3.2 Create Users

1. Go to **Users** in Identity Center console
2. Click **Add user**
3. Fill in user details:
   - **Username**: `john.doe`
   - **Email**: `john.doe@yourdomain.com`
   - **First name**: `John`
   - **Last name**: `Doe`
4. Assign users to appropriate groups

### 3.3 Bulk User Creation (Optional)

Create CSV file for bulk import:
```csv
Username,Email,FirstName,LastName,DisplayName
john.doe,john.doe@company.com,John,Doe,John Doe
jane.smith,jane.smith@company.com,Jane,Smith,Jane Smith
devops.team,devops@company.com,DevOps,Team,DevOps Team
```

Import via console or CLI.

## Step 4: Create Permission Sets

Permission sets define what users can do in AWS accounts. Create these common permission sets:

### 4.1 AdministratorAccess (Full Admin)

1. Go to **Permission sets** in Identity Center console
2. Click **Create permission set**
3. Choose **Predefined permission set**
4. Select **AdministratorAccess**
5. Name: `AdministratorAccess`
6. Session duration: `4 hours` (adjust as needed)

### 4.2 Route53-CrossAccount-Admin (For our domain management)

1. Create **Custom permission set**
2. Name: `Route53-CrossAccount-Admin`
3. Add inline policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:*",
                "route53domains:*",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetRole",
                "iam:GetPolicy",
                "iam:ListRoles",
                "iam:ListPolicies",
                "iam:PassRole",
                "sts:AssumeRole",
                "cloudwatch:*",
                "logs:*",
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetBucketPolicy",
                "s3:PutBucketPolicy",
                "s3:GetBucketVersioning",
                "s3:PutBucketVersioning",
                "cloudtrail:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 4.3 Developer-ReadOnly

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:Get*",
                "route53:List*",
                "ec2:Describe*",
                "s3:GetObject",
                "s3:ListBucket",
                "cloudwatch:Get*",
                "cloudwatch:List*",
                "logs:Get*",
                "logs:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
```

## Step 5: Assign Access to Accounts

### 5.1 Assign Permission Sets to Groups

1. Go to **AWS accounts** in Identity Center
2. Select an account (e.g., Production Account - 111111111111)
3. Click **Assign users or groups**
4. Select **Groups** tab
5. Choose `DevOps-Admins`
6. Select permission set: `AdministratorAccess`
7. Repeat for other accounts and groups:

```
Central Account (111111111111):
├── DevOps-Admins → AdministratorAccess
├── DevOps-Admins → Route53-CrossAccount-Admin
└── Developers → Developer-ReadOnly

Subdomain Account (222222222222):
├── DevOps-Admins → AdministratorAccess
├── DevOps-Admins → Route53-CrossAccount-Admin
└── Developers → Developer-ReadOnly

Production Account (333333333333):
├── Production-Admins → AdministratorAccess
└── DevOps-Admins → Route53-CrossAccount-Admin
```

## Step 6: Configure AWS CLI for SSO

### 6.1 Install AWS CLI v2

```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Windows
# Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
```

### 6.2 Configure SSO Profiles

Get your **SSO start URL** from Identity Center console (looks like `https://d-1234567890.awsapps.com/start`).

```bash
# Configure your first profile
aws configure sso
```

Follow the prompts:
- **SSO start URL**: `https://d-1234567890.awsapps.com/start`
- **SSO region**: `us-east-1`
- **Account**: Select Central Account (111111111111)
- **Role**: Select AdministratorAccess
- **CLI default region**: `us-east-1`
- **CLI default output**: `json`
- **Profile name**: `central-account`

Repeat for subdomain account:
```bash
aws configure sso --profile subdomain-account
```

### 6.3 Manual Profile Configuration

Alternatively, edit `~/.aws/config` directly:

```ini
[profile central-account]
sso_start_url = https://d-1234567890.awsapps.com/start
sso_region = us-east-1
sso_account_id = 111111111111
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[profile subdomain-account]
sso_start_url = https://d-1234567890.awsapps.com/start
sso_region = us-east-1
sso_account_id = 222222222222
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[profile prod-admin]
sso_start_url = https://d-1234567890.awsapps.com/start
sso_region = us-east-1
sso_account_id = 333333333333
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[profile route53-manager]
sso_start_url = https://d-1234567890.awsapps.com/start
sso_region = us-east-1
sso_account_id = 111111111111
sso_role_name = Route53-CrossAccount-Admin
region = us-east-1
output = json
```

## Step 7: Test SSO Setup

### 7.1 Login and Test Access

```bash
# Login to SSO (opens browser)
aws sso login --profile central-account

# Test access
aws sts get-caller-identity --profile central-account
aws sts get-caller-identity --profile subdomain-account

# Test Route53 access
aws route53 list-hosted-zones --profile central-account
```

### 7.2 Login to AWS Console

1. Go to your SSO start URL: `https://d-1234567890.awsapps.com/start`
2. Login with your credentials
3. See all accounts and permission sets you have access to
4. Click on account + role to access AWS Console

## Step 8: Advanced Configuration

### 8.1 Custom Session Duration

Different permission sets can have different session durations:
- **Development**: 8-12 hours
- **Production**: 1-4 hours (more secure)
- **Emergency access**: 1 hour

### 8.2 Multi-Factor Authentication (MFA)

1. Go to **Authentication** in Identity Center
2. Configure MFA requirements:
   - **Always require MFA**
   - **Require MFA only for high-risk actions**
   - **Context-aware MFA** (based on location, device, etc.)

### 8.3 External Identity Provider Integration

For Active Directory or other providers:
1. Go to **Settings** → **Identity source**
2. Choose **External identity provider**
3. Configure SAML 2.0 or Microsoft AD connection

## Step 9: Monitoring and Compliance

### 9.1 Enable CloudTrail for Identity Center

```bash
# Create CloudTrail for SSO events
aws cloudtrail create-trail \
    --name identity-center-audit \
    --s3-bucket-name my-org-audit-logs \
    --include-global-service-events \
    --is-multi-region-trail
```

### 9.2 Set up Access Logging

Identity Center automatically logs:
- Sign-in activities
- Permission set assignments
- Account access patterns
- Failed authentication attempts

View logs in **CloudTrail** and **Identity Center** console.

## Best Practices

### Security
1. **Enable MFA** for all users
2. **Use short session durations** for sensitive accounts
3. **Implement least privilege** with custom permission sets
4. **Regular access reviews** (quarterly)
5. **Monitor sign-in patterns** for anomalies

### Organization
1. **Consistent naming**: Use clear, consistent names for accounts, groups, and permission sets
2. **Group-based access**: Assign permissions to groups, not individual users
3. **Environment separation**: Different permission sets for dev/staging/prod
4. **Documentation**: Document who has what access and why

### Operational
1. **Automation**: Use CloudFormation/Terraform for permission set management
2. **Rotation**: Regular rotation of emergency access credentials
3. **Backup**: Document recovery procedures for Identity Center
4. **Training**: Ensure users know how to use SSO effectively

## Costs

IAM Identity Center is **free** for:
- Up to 50,000 sign-in events per month
- Basic user management
- Standard permission sets

Additional costs only for:
- External identity providers (if used)
- Advanced features in large organizations

## Common Issues and Solutions

1. **"Unable to locate credentials"**
   - Run `aws sso login --profile your-profile`
   - Check profile configuration in `~/.aws/config`

2. **Session expired**
   - Sessions expire based on permission set configuration
   - Re-run `aws sso login` when needed

3. **Permission denied**
   - Check permission set assignments in Identity Center console
   - Verify you're using the correct profile

4. **MFA issues**
   - Ensure MFA device is properly registered
   - Check time synchronization on your device

This setup gives you centralized, secure access to all your AWS accounts with proper audit trails and fine-grained permissions!