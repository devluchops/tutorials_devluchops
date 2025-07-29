# 🔧 Development Setup Guide

This guide helps contributors set up a local development environment for testing and creating tutorials.

## 📋 Prerequisites

### Required Tools
- **Git** (2.30+) - Version control
- **Docker** (20.10+) - Container runtime  
- **Docker Compose** (1.29+) - Multi-container applications
- **VS Code** or preferred editor
- **Python** (3.8+) - For scripting and automation

### Cloud Accounts (Optional)
Set up free tier accounts for hands-on tutorials:
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Google Cloud Free Tier](https://cloud.google.com/free)
- [Azure Free Account](https://azure.microsoft.com/free/)

## 🛠️ Local Environment Setup

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/devluchops/tutorials_devluchops.git
cd tutorials_devluchops

# Set up git hooks (optional)
cp scripts/hooks/* .git/hooks/
chmod +x .git/hooks/*
```

### 2. Install Development Tools

```bash
# Install Python dependencies
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install

# Install markdown linter
npm install -g markdownlint-cli
```

### 3. VS Code Extensions

Recommended extensions for tutorial development:

```json
{
  "recommendations": [
    "ms-vscode.vscode-markdown",
    "yzhang.markdown-all-in-one", 
    "davidanson.vscode-markdownlint",
    "ms-vscode.vscode-yaml",
    "hashicorp.terraform",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "amazonwebservices.aws-toolkit-vscode"
  ]
}
```

## 🧪 Testing Tutorials

### Local Testing

```bash
# Test markdown formatting
markdownlint lessons/**/*.md

# Test links
markdown-link-check lessons/**/*.md

# Validate YAML files
yamllint lessons/**/*.yaml

# Test shell scripts
shellcheck lessons/**/*.sh
```

### Docker Testing Environment

Use our Docker setup for isolated testing:

```bash
# Build test environment
docker-compose -f docker/test-env.yml up -d

# Run tutorial in container
docker exec -it devluchops-test bash
cd /tutorials/lessons/01-aws/001-example
./run.sh
```

## 📝 Content Guidelines

### Tutorial Structure

Each tutorial should follow this structure:

```
lessons/XX-category/###-tutorial-name/
├── README.md              # Main content
├── assets/               
│   └── images/           # Screenshots, diagrams
├── code/                 # Source code
├── configs/              # Configuration files  
├── scripts/              # Automation scripts
└── tests/                # Validation tests
```

### Code Standards

#### Terraform
```hcl
# Use consistent formatting
terraform fmt

# Validate syntax
terraform validate

# Use meaningful names
resource "aws_instance" "web_server" {
  # Configuration
}
```

#### Kubernetes
```yaml
# Use proper indentation (2 spaces)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
```

#### Shell Scripts
```bash
#!/bin/bash
set -euo pipefail

# Use error handling
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is required but not installed."
    exit 1
fi
```

## 🔍 Quality Checklist

Before submitting:

### Content Review
- [ ] Tutorial follows template structure
- [ ] All code examples are tested
- [ ] Screenshots are current and clear
- [ ] Links are working and relevant
- [ ] Grammar and spelling checked

### Technical Review  
- [ ] No real credentials in code
- [ ] Proper error handling
- [ ] Resource cleanup included
- [ ] Security best practices followed
- [ ] Cross-platform compatibility considered

### Documentation Review
- [ ] Clear learning objectives
- [ ] Prerequisites listed
- [ ] Step-by-step instructions
- [ ] Troubleshooting section included
- [ ] Navigation links working

## 🚀 Automation Scripts

### Tutorial Creation Helper

```bash
# Create new tutorial structure
./scripts/create-tutorial.sh "aws" "setup-ec2-with-terraform"

# This creates:
# lessons/01-aws/XXX-setup-ec2-with-terraform/
# ├── README.md (from template)
# ├── assets/
# ├── code/
# └── configs/
```

### Validation Scripts

```bash
# Run all checks
./scripts/validate-all.sh

# Check specific tutorial
./scripts/validate-tutorial.sh lessons/01-aws/001-example

# Update tutorial numbers
./scripts/renumber-tutorials.sh
```

## 📊 Metrics and Analytics

### Tutorial Performance

Track tutorial effectiveness:

```bash
# Generate tutorial stats
python scripts/generate-stats.py

# Output:
# - Completion time estimates
# - Difficulty ratings  
# - Popular tutorials
# - Missing prerequisites
```

### Contribution Metrics

```bash
# Contributor statistics
git shortlog -sn

# Tutorial additions by month
git log --pretty=format:"%ai %s" | grep "add tutorial"
```

## 🐛 Debugging Common Issues

### Markdown Rendering

```bash
# Test markdown locally
grip README.md

# Fix common issues
markdownlint --fix **/*.md
```

### Code Examples

```bash
# Test shell scripts
bash -n script.sh

# Test Python scripts  
python -m py_compile script.py

# Test YAML syntax
python -c "import yaml; yaml.safe_load(open('config.yaml'))"
```

## 🔒 Security Guidelines

### Secrets Management

```bash
# Never commit real secrets
git-secrets --install
git-secrets --register-aws

# Use environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Or use placeholder files
cp config.example.yaml config.yaml
# Edit config.yaml with your values
```

### Safe Testing

1. **Use separate accounts** for testing
2. **Set billing alerts** to avoid unexpected charges
3. **Clean up resources** after testing
4. **Use IAM roles** with minimal permissions
5. **Never test in production** environments

## 📚 Resources

### Documentation
- [GitHub Markdown Guide](https://guides.github.com/features/mastering-markdown/)
- [YAML Specification](https://yaml.org/spec/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Tools
- [Terraform Docs](https://www.terraform.io/docs/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)

### Communities  
- [DevOps Subreddit](https://reddit.com/r/devops)
- [CNCF Slack](https://slack.cncf.io/)
- [AWS Community](https://aws.amazon.com/developer/community/)

---

<div align="center">

**Need help with setup? [Open an issue](https://github.com/devluchops/tutorials_devluchops/issues) or ask in [Discussions](https://github.com/devluchops/tutorials_devluchops/discussions)!**

</div>
