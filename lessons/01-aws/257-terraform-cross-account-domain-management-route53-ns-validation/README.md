# Terraform Cross-Account Domain Management with Route53 and NS Validation

This tutorial demonstrates how to set up cross-account domain management using Terraform, where you have a central domain in one AWS account (devluchops.com) and create subdomains in other AWS accounts (app.devluchops.com) with automatic NS validation.

## Architecture Overview

```
Central Account (Account A)
├── Route53 Hosted Zone: devluchops.com
├── NS records for subdomains
└── Cross-account IAM role

Subdomain Account (Account B)
├── Route53 Hosted Zone: app.devluchops.com
├── Assume role to central account
└── Create NS records in central account
```

## Prerequisites

- Two AWS accounts (Central and Subdomain accounts)
- Access to both accounts via either:
  - **IAM Identity Center** (recommended) with admin permission sets
  - **Single IAM user** with administrative access to both accounts
- AWS CLI configured with your credentials
- Terraform installed (v1.0+)
- Domain registered in Route53 or external registrar pointed to Route53

## Account Setup Requirements

### Central Account (Where main domain resides)
- Account ID: `111111111111` (replace with your actual account)
- Domain: `devluchops.com`
- Profile name: `central-account`

### Subdomain Account (Where subdomain will be created)
- Account ID: `222222222222` (replace with your actual account)
- Subdomain: `app.devluchops.com`
- Profile name: `subdomain-account`

## Step-by-Step Implementation

### Step 1: Configure AWS Profiles

You can use either **IAM User** or **IAM Identity Center** (recommended):

#### Option A: IAM Identity Center (Recommended)

```ini
# ~/.aws/config
[profile central-account]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-east-1
sso_account_id = 111111111111
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[profile subdomain-account]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-east-1
sso_account_id = 222222222222
sso_role_name = AdministratorAccess
region = us-east-1
output = json
```

Then login once:
```bash
aws sso login --profile central-account
```

#### Option B: IAM User with Cross-Account Role

```ini
# ~/.aws/config
[default]
region = us-east-1
output = json

[profile central-account]
region = us-east-1
output = json

[profile subdomain-account]
region = us-east-1
output = json
role_arn = arn:aws:iam::222222222222:role/CrossAccountAccessRole
source_profile = default

# ~/.aws/credentials
[default]
aws_access_key_id = YOUR_MAIN_ACCESS_KEY
aws_secret_access_key = YOUR_MAIN_SECRET_KEY
```

**IAM Identity Center Benefits:**
- ✅ Temporary credentials (more secure)
- ✅ Centralized access management
- ✅ No long-term access keys
- ✅ Built-in MFA support
- ✅ Automatic credential rotation

### Important Notes for IAM Identity Center:

#### 1. Permission Sets Required
You need **AdministratorAccess** or custom permission set with these permissions in both accounts:
- `route53:*`
- `iam:*` (for creating cross-account roles)
- `cloudwatch:*` (if using logging)
- `s3:*` (if using audit logging)

#### 2. Cross-Account Role Still Needed
Even with IAM Identity Center, you still need the cross-account IAM role because:
- Terraform providers need explicit role assumption
- Provides additional security boundary
- Enables fine-grained permissions for Route53

#### 3. Session Duration
IAM Identity Center sessions last 1-12 hours (configurable). For long Terraform operations, ensure your session doesn't expire:

```bash
# Check session status
aws sts get-caller-identity --profile central-account

# Re-authenticate if needed
aws sso login --profile central-account
```

### Step 2: Deploy IAM Cross-Account Role

First, we need to create the cross-account IAM role in the central account that allows the subdomain account to manage DNS records.

```bash
cd iam-roles
```

1. Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your account IDs and user ARN:
```hcl
central_account_id = "111111111111"
subdomain_account_id = "222222222222"
domain_name = "devluchops.com"
trusted_user_arn = "arn:aws:iam::111111111111:user/your-username"
```

3. Initialize and apply Terraform:

**If using IAM Identity Center:**
```bash
aws sso login --profile central-account  # Login once
terraform init
AWS_PROFILE=central-account terraform plan
AWS_PROFILE=central-account terraform apply
```

**If using IAM User:**
```bash
terraform init
AWS_PROFILE=central-account terraform plan
AWS_PROFILE=central-account terraform apply
```

4. Note the role ARN from the output - you'll need it for the next steps.

### Step 3: Deploy Central Domain Account Configuration

Navigate to the central account configuration:

```bash
cd ../central-account
```

1. Copy and edit the variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Update `terraform.tfvars`:
```hcl
domain_name = "devluchops.com"
subdomain_account_id = "222222222222"
environment = "production"
```

3. Initialize and apply:

**If using IAM Identity Center:**
```bash
aws sso login --profile central-account  # Login if needed
terraform init
AWS_PROFILE=central-account terraform plan
AWS_PROFILE=central-account terraform apply
```

**If using IAM User:**
```bash
terraform init
AWS_PROFILE=central-account terraform plan
AWS_PROFILE=central-account terraform apply
```

4. Note the hosted zone ID from the output.

### Step 4: Deploy Subdomain Account Configuration

Navigate to the subdomain account configuration:

```bash
cd ../subdomain-account
```

1. Copy and edit the variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Update `terraform.tfvars` with the cross-account role ARN from Step 2:
```hcl
subdomain_name = "app.devluchops.com"
parent_domain = "devluchops.com"
central_account_id = "111111111111"
cross_account_role_arn = "arn:aws:iam::111111111111:role/Route53CrossAccountRole"
environment = "production"
```

3. Initialize and apply:

**If using IAM Identity Center:**
```bash
aws sso login --profile subdomain-account  # Login if needed (or reuse central-account session)
terraform init
AWS_PROFILE=subdomain-account terraform plan
AWS_PROFILE=subdomain-account terraform apply
```

**If using IAM User:**
```bash
terraform init
AWS_PROFILE=subdomain-account terraform plan
AWS_PROFILE=subdomain-account terraform apply
```

### Step 5: Verify the Setup

1. **Check the central account hosted zone:**
```bash
AWS_PROFILE=central-account aws route53 list-resource-record-sets --hosted-zone-id Z1234567890ABC
```

2. **Check the subdomain account hosted zone:**
```bash
AWS_PROFILE=subdomain-account aws route53 list-resource-record-sets --hosted-zone-id Z0987654321XYZ
```

3. **Test DNS resolution:**
```bash
dig NS app.devluchops.com
dig NS devluchops.com
```

4. **Test subdomain delegation:**
```bash
nslookup app.devluchops.com
```

## How It Works

### Cross-Account Access Flow

1. **Central Account Setup:**
   - Creates the main hosted zone for `devluchops.com`
   - Creates IAM role that can be assumed by the subdomain account
   - Grants Route53 permissions to manage records in the central hosted zone

2. **Subdomain Account Setup:**
   - Creates hosted zone for `app.devluchops.com`
   - Assumes the cross-account role in the central account
   - Creates NS records in the central account pointing to the subdomain's name servers

3. **NS Validation:**
   - Terraform automatically creates the NS records in the parent domain
   - DNS delegation is established from `devluchops.com` to `app.devluchops.com`
   - The subdomain account gains full control over `app.devluchops.com` records

### Security Considerations

- **Least Privilege:** The cross-account role only has permissions to manage Route53 records
- **Account Isolation:** Each account manages its own subdomain independently
- **Audit Trail:** All DNS changes are logged in CloudTrail for both accounts
- **Resource-Level Permissions:** The role is restricted to specific hosted zones

## Troubleshooting

### Common Issues

1. **"Access Denied" when assuming role:**
   - Check that the trust policy includes the correct subdomain account ID
   - Verify the role ARN is correct in terraform.tfvars
   - Ensure the subdomain account has permission to assume the role

2. **NS records not created in central account:**
   - Verify the cross-account role has Route53 permissions
   - Check that the hosted zone ID is correct
   - Ensure the role session name is unique

3. **DNS resolution not working:**
   - Wait for DNS propagation (can take up to 48 hours)
   - Check NS records are correctly set in the parent domain
   - Verify the subdomain hosted zone exists and has correct NS records

### Debugging Commands

#### General Debugging
```bash
# Check if role can be assumed
AWS_PROFILE=subdomain-account aws sts assume-role \
  --role-arn "arn:aws:iam::111111111111:role/Route53CrossAccountRole" \
  --role-session-name "test-session"

# List all hosted zones in central account
AWS_PROFILE=central-account aws route53 list-hosted-zones

# Check specific record sets
AWS_PROFILE=central-account aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --query "ResourceRecordSets[?Name=='app.devluchops.com.']"
```

#### IAM Identity Center Specific Issues

1. **Session Expired Error:**
```bash
# Check current session
aws sts get-caller-identity --profile central-account

# If expired, re-login
aws sso login --profile central-account
```

2. **"Unable to locate credentials" Error:**
```bash
# Check SSO configuration
aws configure list --profile central-account

# Verify SSO configuration
aws sso list-accounts --profile central-account
```

3. **Permission Denied:**
```bash
# Check what permissions you have
aws sts get-caller-identity --profile central-account

# Verify permission set in IAM Identity Center console
```

## Cleanup

To destroy the resources in reverse order:

1. **Destroy subdomain account resources:**
```bash
cd subdomain-account
AWS_PROFILE=subdomain-account terraform destroy
```

2. **Destroy central account resources:**
```bash
cd ../central-account
AWS_PROFILE=central-account terraform destroy
```

3. **Destroy IAM roles:**
```bash
cd ../iam-roles
AWS_PROFILE=central-account terraform destroy
```

## Advanced Use Cases

### Multiple Subdomains
You can create multiple subdomains by duplicating the subdomain-account configuration:
- `api.devluchops.com`
- `admin.devluchops.com`
- `staging.devluchops.com`

### Different Regions
Each subdomain account can be in different AWS regions while maintaining the same cross-account access pattern.

### Environment-Specific Subdomains
Create separate subdomain accounts for different environments:
- `prod.devluchops.com` (Production Account)
- `dev.devluchops.com` (Development Account)
- `test.devluchops.com` (Testing Account)

## Best Practices

1. **Use separate AWS accounts** for different environments or applications
2. **Implement proper tagging** for all resources to track ownership and cost
3. **Set up monitoring and alerts** for DNS resolution failures
4. **Document the delegation chain** for troubleshooting purposes
5. **Regular security audits** of cross-account roles and permissions
6. **Use Terraform workspaces** for managing multiple environments
7. **Implement automated testing** for DNS resolution and delegation

## Security Best Practices

1. **Enable CloudTrail** in all accounts for audit logging
2. **Use least privilege principle** for IAM roles and policies
3. **Regularly rotate AWS access keys** for service accounts
4. **Monitor cross-account assume role activities**
5. **Set up alerts for unexpected DNS changes**
6. **Use resource-based policies** where possible to limit access scope

This setup provides a scalable and secure way to manage domains across multiple AWS accounts while maintaining proper delegation and security boundaries.

