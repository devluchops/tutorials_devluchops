# 🚀 Tutorial Template

Use this template when creating new tutorials for the DevLuchOps repository.

## 📁 Directory Structure

```
lessons/XX-category/###-tutorial-name/
├── README.md              # Main tutorial content
├── assets/               # Images, diagrams, screenshots
│   ├── architecture.png
│   └── screenshots/
├── code/                 # Source code and examples
│   ├── main.tf          # Infrastructure code
│   ├── app.py           # Application code
│   └── scripts/         # Helper scripts
├── configs/             # Configuration files
│   ├── config.yaml
│   └── secrets.example.yaml
└── docs/               # Additional documentation
    ├── troubleshooting.md
    └── references.md
```

## 📝 README Template

```markdown
# Tutorial ###: [Tutorial Title]

## 🎯 Overview

Brief description of what this tutorial covers and what learners will achieve.

### What You'll Learn
- ✅ Key learning objective 1
- ✅ Key learning objective 2  
- ✅ Key learning objective 3

### Prerequisites
- Requirement 1
- Requirement 2
- Requirement 3

### Time to Complete
⏱️ Approximately XX minutes

## 🏗️ Architecture

![Architecture Diagram](assets/architecture.png)

Brief explanation of the architecture and components.

## 🛠️ Setup

### Step 1: Environment Preparation
```bash
# Commands to set up environment
```

### Step 2: Install Dependencies
```bash
# Installation commands
```

## 📋 Implementation

### Phase 1: [Phase Name]
Detailed explanation of the first phase.

```bash
# Code examples with explanations
```

### Phase 2: [Phase Name]
Detailed explanation of the second phase.

```yaml
# Configuration examples
```

## ✅ Verification

How to verify the implementation works correctly.

```bash
# Verification commands
```

Expected output:
```
Expected command output
```

## 🧹 Cleanup

Important: Clean up resources to avoid costs.

```bash
# Cleanup commands
```

## 🔍 Troubleshooting

| Issue | Solution |
|-------|----------|
| Common error 1 | Fix description |
| Common error 2 | Fix description |

## 📚 Additional Resources

- [Link 1](url) - Description
- [Link 2](url) - Description

## 🏆 Challenge

Optional challenge or next steps for advanced learners.

## 📝 Notes

- Important note 1
- Important note 2

---

### 🔗 Navigation
- [← Previous Tutorial](../###-previous-tutorial/)
- [→ Next Tutorial](../###-next-tutorial/)
- [📚 Category Index](../README.md)
- [🏠 Main Index](../../README.md)
```

## 📋 Content Guidelines

### ✅ Writing Best Practices

1. **Clear Objectives** - Start with what learners will achieve
2. **Step-by-Step** - Break complex tasks into manageable steps
3. **Code Examples** - Provide complete, working examples
4. **Explanations** - Explain WHY, not just HOW
5. **Verification** - Include ways to verify success
6. **Cleanup** - Always include cleanup steps

### 🎯 Technical Standards

1. **Tested Code** - All code must be tested and working
2. **Security** - Use placeholder credentials, never real secrets
3. **Best Practices** - Follow industry standards
4. **Comments** - Well-commented code examples
5. **Error Handling** - Include error scenarios and solutions

### 📸 Visual Guidelines

1. **Screenshots** - High quality, consistent styling
2. **Diagrams** - Clear architecture diagrams when needed
3. **Alt Text** - Include alt text for accessibility
4. **File Size** - Optimize images for fast loading

## 🏷️ Naming Conventions

### Directory Names
```
###-descriptive-tutorial-name
```
- Use 3-digit numbers (001, 002, etc.)
- Use kebab-case (lowercase with hyphens)
- Be descriptive but concise

### File Names
```
README.md           # Main tutorial
config.yaml         # Configuration files
main.tf            # Infrastructure code
app.py             # Application code
architecture.png    # Architecture diagram
```

## 🔍 Review Checklist

Before submitting a tutorial, ensure:

- [ ] All prerequisites are clearly listed
- [ ] Code examples are complete and tested
- [ ] Screenshots are clear and relevant
- [ ] Cleanup instructions are provided
- [ ] Navigation links are working
- [ ] No real credentials or secrets
- [ ] Follows the template structure
- [ ] Grammar and spelling checked

## 📚 Examples

Great examples to follow:
- `lessons/01-aws/176-crossplane-tutorial-vs-terraform-create-aws-vpc-eks-irsa-cluster-autoscaler-csi-driver/`
- `lessons/02-kubernetes/179-argocd-notifications-successfulfailed-deployments/`

---

<div align="center">

**Ready to create an amazing tutorial? Follow this template and help the community learn! 🚀**

</div>
