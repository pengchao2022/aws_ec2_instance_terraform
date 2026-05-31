# Terraform AWS EC2 Module

This repository creates an EC2 instance using an existing VPC, configures security groups, sets up SSH key authentication, and stores Terraform state in S3 with GitHub Actions OIDC authentication


## Features

- ✅ **Existing VPC** - Use an existing VPC and subnets (no VPC creation)
- ✅ **Security Group** - Configurable rules for SSH, HTTP, HTTPS, and custom ports
- ✅ **SSH Key Pair** - Create or use existing key pair for secure access
- ✅ **S3 Backend** - Terraform state stored remotely in S3 with DynamoDB locking
- ✅ **OIDC Authentication** - No AWS credentials in GitHub Secrets, uses `AWS_ROLE_ARN` instead
- ✅ **GitHub Actions** - Automatic deployment on merge to main

## Prerequisites

### AWS Requirements
- Existing VPC with public/private subnets
- IAM role with EC2 creation permissions (for GitHub OIDC)
- S3 bucket for Terraform state (can be created separately)

### GitHub Requirements
- `AWS_ROLE_ARN` configured in GitHub Secrets (no Access Keys needed!)
- Repository secrets (optional, for variables)

### Local Requirements (for testing)
- Terraform 1.0+
- AWS CLI configured (optional, for testing)

## Authentication with GitHub OIDC

**No AWS Access Keys stored in GitHub Secrets!** This repository uses OIDC (OpenID Connect) to assume an IAM role.

### GitHub Secrets Required

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `AWS_ROLE_ARN` | ARN of the IAM role for GitHub Actions to assume | ✅ Yes |
| `AWS_REGION` | AWS region (default: us-east-1) | ❌ No |
| `TF_STATE_BUCKET` | S3 bucket name for Terraform state | ✅ Yes |
| `TF_STATE_KEY` | Path for state file in S3 | ❌ No |

### IAM Role Trust Policy (Prerequisite)

The IAM role (`AWS_ROLE_ARN`) must have a trust policy allowing your GitHub repository:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
