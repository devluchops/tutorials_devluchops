# Git Advanced Workflows and Best Practices

Complete guide to advanced Git workflows, branching strategies, and collaboration patterns for enterprise development.

## What You'll Learn

- **Advanced Git Workflows** - GitFlow, GitHub Flow, GitLab Flow
- **Branching Strategies** - Feature branches, release branches, hotfixes
- **Collaboration Patterns** - Pull requests, code reviews, conflict resolution
- **Git Hooks** - Pre-commit, pre-push, post-receive hooks
- **Repository Management** - Submodules, subtrees, monorepos
- **Performance Optimization** - Large repositories, Git LFS, partial clones

## Git Workflow Comparison

### **GitFlow** 🌊
```
main ──────●──────●──────●─────▶
           │      │      │
develop ───●──●───●──●───●─────▶
           │  │   │  │   │
feature ───●──●   │  │   │
              │   │  │   │
release ──────────●──●   │
                     │   │
hotfix ──────────────────●
```

### **GitHub Flow** ⚡
```
main ──────●──────●──────●─────▶
           │      │      │
feature ───●──────●      │
           │      │      │
feature ───────●──────●──●
```

### **GitLab Flow** 🚀
```
main ──────●──────●──────●─────▶
           │      │      │
staging ───●──────●──────●─────▶
           │      │      │
production ●──────●──────●─────▶
```

## Advanced Git Commands

### **Interactive Rebase**
```bash
# Rewrite commit history
git rebase -i HEAD~3

# Squash commits
pick abc1234 First commit
squash def5678 Fix typo
squash ghi9012 Add tests

# Edit commit messages
git commit --amend

# Split commits
git reset HEAD~1
git add file1.js
git commit -m "Add feature A"
git add file2.js
git commit -m "Add feature B"
```

### **Advanced Merging**
```bash
# Merge strategies
git merge --strategy=ours feature-branch
git merge --strategy=recursive -X theirs feature-branch

# Merge with custom message
git merge --no-ff --edit feature-branch

# Merge specific files
git checkout feature-branch -- file1.js file2.js
git commit -m "Cherry-pick specific files"

# Three-way merge
git merge-base main feature-branch
```

### **Stash Management**
```bash
# Advanced stashing
git stash push -m "Work in progress on feature X"
git stash push --include-untracked -m "Include new files"

# Stash specific files
git stash push -m "Only CSS changes" styles.css

# Apply stash to different branch
git stash branch new-feature stash@{1}

# Stash with pathspec
git stash push -- "*.js" "*.ts"
```

## Git Hooks Implementation

### **Pre-commit Hook**
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running pre-commit checks..."

# Check for debugging statements
if git diff --cached --name-only | xargs grep -l "console.log\|debugger\|pdb.set_trace" 2>/dev/null; then
    echo "❌ Found debugging statements in staged files"
    echo "Please remove console.log, debugger, or pdb.set_trace statements"
    exit 1
fi

# Run linting
npm run lint
if [ $? -ne 0 ]; then
    echo "❌ Linting failed"
    exit 1
fi

# Run tests
npm test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi

echo "✅ All pre-commit checks passed"
```

### **Pre-push Hook**
```bash
#!/bin/bash
# .git/hooks/pre-push

protected_branch='main'
current_branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

if [ $current_branch = $protected_branch ]; then
    echo "❌ Direct push to $protected_branch branch is not allowed"
    echo "Please create a feature branch and submit a pull request"
    exit 1
fi

# Run full test suite
npm run test:full
if [ $? -ne 0 ]; then
    echo "❌ Full test suite failed"
    exit 1
fi

echo "✅ Pre-push checks passed"
```

### **Commit Message Hook**
```bash
#!/bin/bash
# .git/hooks/commit-msg

commit_regex='^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "❌ Invalid commit message format"
    echo "Format: type(scope): description"
    echo "Types: feat, fix, docs, style, refactor, test, chore"
    echo "Example: feat(auth): add JWT authentication"
    exit 1
fi

echo "✅ Commit message format is valid"
```

## Repository Management

### **Git Submodules**
```bash
# Add submodule
git submodule add https://github.com/user/repo.git lib/external

# Initialize submodules
git submodule init
git submodule update

# Update all submodules
git submodule update --recursive --remote

# Remove submodule
git submodule deinit lib/external
git rm lib/external
rm -rf .git/modules/lib/external
```

### **Git Subtrees**
```bash
# Add subtree
git subtree add --prefix=lib/external https://github.com/user/repo.git main --squash

# Update subtree
git subtree pull --prefix=lib/external https://github.com/user/repo.git main --squash

# Push changes back
git subtree push --prefix=lib/external https://github.com/user/repo.git main
```

### **Monorepo Management**
```bash
# Sparse checkout for large repos
git config core.sparseCheckout true
echo "frontend/*" > .git/info/sparse-checkout
echo "shared/*" >> .git/info/sparse-checkout
git read-tree -m -u HEAD

# Partial clone
git clone --filter=blob:none <url>
git clone --filter=tree:0 <url>

# Shallow clone with history
git clone --depth=50 <url>
git fetch --unshallow
```

## Advanced Collaboration

### **Pull Request Templates**
```markdown
<!-- .github/pull_request_template.md -->
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No merge conflicts
```

### **Code Review Best Practices**
```bash
# Review specific commits
git log --oneline feature-branch ^main
git show <commit-hash>

# Compare branches
git diff main...feature-branch
git diff main..feature-branch --stat

# Review changes by file
git diff main...feature-branch -- path/to/file

# Interactive review
git difftool main...feature-branch
```

## Git Performance Optimization

### **Large Repository Optimization**
```bash
# Garbage collection
git gc --aggressive --prune=now

# Remove old references
git remote prune origin
git branch --merged | grep -v "\*\|main\|develop" | xargs -n 1 git branch -d

# Repack repository
git repack -ad

# Check repository size
git count-objects -vH
```

### **Git LFS Setup**
```bash
# Install Git LFS
git lfs install

# Track large files
git lfs track "*.psd"
git lfs track "*.zip"
git lfs track "assets/**"

# Check LFS status
git lfs ls-files
git lfs status

# Migrate existing files
git lfs migrate import --include="*.zip"
```

## Git Configuration

### **Global Configuration**
```bash
# User information
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"

# Editor and diff tool
git config --global core.editor "code --wait"
git config --global merge.tool vimdiff

# Aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'

# Line ending configuration
git config --global core.autocrlf input  # Linux/Mac
git config --global core.autocrlf true   # Windows

# Push configuration
git config --global push.default simple
git config --global push.followTags true

# Rebase configuration
git config --global rebase.autoStash true
git config --global rebase.autoSquash true
```

### **Repository-specific Configuration**
```bash
# Work email for work repositories
git config user.email "work.email@company.com"

# Signing commits
git config commit.gpgsign true
git config user.signingkey <key-id>

# Custom hooks
git config core.hooksPath .githooks/
```

## Git Security

### **Signing Commits**
```bash
# Generate GPG key
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG

# Configure Git
git config --global user.signingkey <key-id>
git config --global commit.gpgsign true

# Sign commits
git commit -S -m "Signed commit"

# Verify signatures
git log --show-signature
git verify-commit HEAD
```

### **Security Best Practices**
```bash
# Remove sensitive data from history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch secrets.txt' \
  --prune-empty --tag-name-filter cat -- --all

# Using BFG Repo-Cleaner (faster alternative)
java -jar bfg.jar --delete-files secrets.txt
java -jar bfg.jar --replace-text passwords.txt

# Prevent accidental commits
echo "secrets.txt" >> .gitignore
echo "*.env" >> .gitignore
echo "config/database.yml" >> .gitignore
```

## Troubleshooting

### **Common Issues**
```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Recover lost commits
git reflog
git cherry-pick <commit-hash>

# Fix merge conflicts
git status
git mergetool
git commit

# Resolve detached HEAD
git checkout main
git branch temp-branch <commit-hash>
git merge temp-branch

# Clean working directory
git clean -fd
git reset --hard HEAD
```

### **Performance Issues**
```bash
# Check what's taking space
git rev-list --objects --all | sort -k 2 > allfileshas.txt
git gc && git verify-pack -v .git/objects/pack/pack-*.idx | egrep "^\w+ blob\W+[0-9]+ [0-9]+ [0-9]+$" | sort -k 3 -n -r > bigobjects.txt

# Find large files
git rev-list --all --objects | grep "$(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -5 | awk '{print$1}')"
```

## Useful Links

- [Git Documentation](https://git-scm.com/doc)
- [Pro Git Book](https://git-scm.com/book)
- [Git Workflows](https://www.atlassian.com/git/tutorials/comparing-workflows)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [GitLab Flow](https://docs.gitlab.com/ee/topics/gitlab_flow.html)
