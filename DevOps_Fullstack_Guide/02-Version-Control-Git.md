# Version Control with Git

## Table of Contents
1. [Introduction to Version Control](#introduction-to-version-control)
2. [Git Fundamentals](#git-fundamentals)
3. [Git Workflow Basics](#git-workflow-basics)
4. [Branching and Merging](#branching-and-merging)
5. [Advanced Git Operations](#advanced-git-operations)
6. [Branching Strategies](#branching-strategies)
7. [Git Best Practices](#git-best-practices)
8. [Collaboration with Git](#collaboration-with-git)
9. [Troubleshooting Common Issues](#troubleshooting-common-issues)

---

## Introduction to Version Control

### What is Version Control?

**Version Control** (also known as Source Control) is a system that tracks changes to files over time, allowing you to:
- Recall specific versions later
- Collaborate with multiple developers
- Track who made what changes and when
- Experiment without fear of breaking things
- Maintain multiple versions simultaneously

### Why Version Control Matters

**Without Version Control:**
```
project_final.zip
project_final_v2.zip
project_final_v2_ACTUAL.zip
project_final_v2_ACTUAL_THIS_ONE.zip
project_final_v2_ACTUAL_THIS_ONE_I_SWEAR.zip
```

**With Version Control:**
```bash
git log --oneline
a1b2c3d (HEAD -> main) Fix: resolve login bug
e4f5g6h feat: add user profile page
i7j8k9l refactor: optimize database queries
```

---

### Types of Version Control Systems

#### **1. Local Version Control**
```
Your Computer:
  ├── Database of Changes
  ├── File Version 1
  ├── File Version 2
  └── File Version 3
```

**Example**: RCS (Revision Control System)

**Limitations:**
- No collaboration
- No remote backup

---

#### **2. Centralized Version Control (CVCS)**
```
Central Server:
  └── Repository (all versions)
       ↑          ↑          ↑
       │          │          │
   Developer   Developer  Developer
      A           B          C
   (checkout) (checkout) (checkout)
```

**Examples**: SVN, Perforce

**Advantages:**
- Everyone knows what others are doing
- Fine-grained access control

**Limitations:**
- Single point of failure
- Requires network access
- Slower operations

---

#### **3. Distributed Version Control (DVCS)**
```
Remote Repository (GitHub/GitLab)
       ↓          ↓          ↓
   Developer   Developer  Developer
      A           B          C
   (full repo) (full repo) (full repo)
```

**Examples**: Git, Mercurial

**Advantages:**
- Every dev has full history
- Work offline
- Fast operations
- Multiple backups
- Flexible workflows

---

## Git Fundamentals

### Installing Git

**Windows:**
```powershell
# Using winget
winget install Git.Git

# Or download from git-scm.com
```

**macOS:**
```bash
# Using Homebrew
brew install git

# Or use Xcode command line tools
xcode-select --install
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install git
```

**Verify Installation:**
```bash
git --version
# Output: git version 2.42.0
```

---

### Initial Configuration

**Set Your Identity:**
```bash
# Required for commits
git config --global user.name "Your Name"
git config --global user.email "youremail@example.com"

# Verify
git config --list
```

**Configure Default Editor:**
```bash
# Use VS Code
git config --global core.editor "code --wait"

# Use Vim
git config --global core.editor "vim"

# Use Nano
git config --global core.editor "nano"
```

**Configure Default Branch Name:**
```bash
# Use 'main' instead of 'master'
git config --global init.defaultBranch main
```

**Useful Aliases:**
```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual 'log --oneline --graph --decorate --all'
```

---

### How Git Works

#### **The Three States**

Git has three main states that files can be in:

```
Working Directory    Staging Area        Repository
   (Modified)       (Staged/Index)       (Committed)
       │                   │                   │
       │    git add        │   git commit      │
       │─────────────────→ │─────────────────→ │
       │                   │                   │
       │←──────────────────┴───────────────────│
       │          git checkout / restore       │
```

**1. Modified:** Changed but not committed
**2. Staged:** Marked to go into next commit
**3. Committed:** Safely stored in database

---

#### **The Three Trees**

```
HEAD                  Index             Working Directory
(last commit)     (proposed commit)    (sandbox)
    │                   │                   │
    │                   │                   │
file.txt v2         file.txt v3         file.txt v3
                                        (editing...)
```

---

#### **Git Object Model**

Git stores four types of objects:

**1. Blob (Binary Large Object):**
```
Content of a file
Hash: a1b2c3d4...
```

**2. Tree:**
```
Directory listing
├── file1.txt (blob: a1b2c3)
├── file2.js  (blob: e4f5g6)
└── src/      (tree: i7j8k9)
```

**3. Commit:**
```
Commit: x1y2z3
Author: John Doe
Date:   2024-01-15
Message: "Add user authentication"
Tree:   a1b2c3
Parent: d4e5f6
```

**4. Tag:**
```
Tag:    v1.0.0
Commit: x1y2z3
Author: Jane Smith
Message: "Release v1.0.0"
```

---

## Git Workflow Basics

### Creating a Repository

**Initialize a New Repository:**
```bash
# Create project directory
mkdir my-project
cd my-project

# Initialize Git
git init

# Output:
# Initialized empty Git repository in /path/to/my-project/.git/
```

**Clone an Existing Repository:**
```bash
# Clone from GitHub
git clone https://github.com/username/repo.git

# Clone to specific directory
git clone https://github.com/username/repo.git my-folder

# Clone specific branch
git clone -b develop https://github.com/username/repo.git
```

---

### Basic Git Workflow

#### **1. Check Status**
```bash
git status

# Output example:
# On branch main
# Changes not staged for commit:
#   modified:   index.html
# Untracked files:
#   new-feature.js
```

---

#### **2. Stage Changes**

**Stage Specific Files:**
```bash
git add index.html
git add src/app.js
```

**Stage All Changes:**
```bash
git add .
# or
git add -A
```

**Stage by Patch (Interactive):**
```bash
git add -p

# Git will show each change and ask:
# Stage this hunk [y,n,q,a,d,e,?]?
# y = yes
# n = no
# q = quit
# a = this and all remaining
# d = don't stage this or any remaining
# e = manually edit the hunk
```

---

#### **3. Commit Changes**

**Basic Commit:**
```bash
git commit -m "Add user authentication feature"
```

**Commit with Description:**
```bash
git commit -m "Add user authentication" -m "
- Implemented JWT-based auth
- Added login/logout endpoints
- Created user session management
"
```

**Commit All Modified Files (skip staging):**
```bash
git commit -am "Quick fix for typo"
```

**Amend Last Commit:**
```bash
# Forgot to add a file
git add forgotten-file.js
git commit --amend --no-edit

# Change commit message
git commit --amend -m "New commit message"
```

---

#### **4. View History**

**Basic Log:**
```bash
git log

# Output:
# commit a1b2c3d4e5f6... (HEAD -> main)
# Author: John Doe <john@example.com>
# Date:   Mon Jan 15 10:30:00 2024 +0530
#
#     Add user authentication
```

**Concise Log:**
```bash
git log --oneline

# Output:
# a1b2c3d Add user authentication
# e4f5g6h Fix login bug
# i7j8k9l Update README
```

**Visual Log:**
```bash
git log --oneline --graph --decorate --all

# Output:
# * a1b2c3d (HEAD -> main) Add user authentication
# * e4f5g6h (origin/main) Fix login bug
# |\
# | * i7j8k9l (feature/user-profile) Add profile page
# |/
# * l1m2n3o Initial commit
```

**Filter Logs:**
```bash
# Commits by author
git log --author="John Doe"

# Commits in date range
git log --since="2 weeks ago"
git log --after="2024-01-01" --before="2024-01-31"

# Commits that modified specific file
git log -- src/app.js

# Search commit messages
git log --grep="authentication"
```

---

#### **5. View Differences**

**Unstaged Changes:**
```bash
git diff
```

**Staged Changes:**
```bash
git diff --staged
# or
git diff --cached
```

**Between Commits:**
```bash
git diff commit1 commit2

# Between branches
git diff main feature/new-feature

# Specific file
git diff main feature/new-feature -- src/app.js
```

---

## Branching and Merging

### Understanding Branches

**What is a Branch?**
A branch is a lightweight movable pointer to a commit.

```
main:     A --- B --- C
                       ↑
                      HEAD

Create branch:
main:     A --- B --- C
                       ↑
                      main
feature:               ↑
                      HEAD

After commit:
main:     A --- B --- C
                       
feature:               D
                       ↑
                      HEAD
```

---

### Branch Operations

**Create Branch:**
```bash
# Create new branch
git branch feature/user-auth

# Create and switch to branch
git checkout -b feature/user-auth
# or (Git 2.23+)
git switch -c feature/user-auth
```

**List Branches:**
```bash
# Local branches
git branch

# Remote branches
git branch -r

# All branches
git branch -a

# With last commit
git branch -v
```

**Switch Branches:**
```bash
# Old way
git checkout main

# New way (Git 2.23+)
git switch main
```

**Delete Branch:**
```bash
# Delete merged branch
git branch -d feature/user-auth

# Force delete (even if not merged)
git branch -D feature/user-auth

# Delete remote branch
git push origin --delete feature/user-auth
```

---

### Merging Branches

#### **Fast-Forward Merge**

When target branch hasn't diverged:
```
Before:
main:    A --- B
                 ↑
                main

feature:         C --- D
                       ↑
                    feature

After merge:
main:    A --- B --- C --- D
                            ↑
                          main
                          feature
```

**Command:**
```bash
git checkout main
git merge feature/user-auth
```

---

#### **Three-Way Merge**

When branches have diverged:
```
Before:
         C --- D  (feature)
        /
main:  A --- B --- E
                    ↑
                   main

After merge:
         C --- D  (feature)
        /         \
main:  A --- B --- E --- M
                          ↑
                         main
```

**Command:**
```bash
git checkout main
git merge feature/user-auth
```

---

#### **Merge Conflicts**

**When Conflicts Occur:**
```bash
git merge feature/user-auth

# Output:
# Auto-merging src/app.js
# CONFLICT (content): Merge conflict in src/app.js
# Automatic merge failed; fix conflicts and then commit the result.
```

**Conflict Markers:**
```javascript
// src/app.js
function login(credentials) {
<<<<<<< HEAD (Current Change)
  return authenticateWithOAuth(credentials);
=======
  return authenticateWithJWT(credentials);
>>>>>>> feature/user-auth (Incoming Change)
}
```

**Resolving Conflicts:**
```bash
# 1. Open conflicted files
# 2. Choose which changes to keep
# 3. Remove conflict markers

# After resolving:
git add src/app.js
git commit -m "Merge feature/user-auth into main"
```

**Conflict Resolution Tools:**
```bash
# Use merge tool
git mergetool

# Abort merge
git merge --abort

# Continue after resolving
git merge --continue
```

---

### Rebasing

**What is Rebase?**
Reapply commits on top of another base commit.

```
Before:
         C --- D  (feature)
        /
main:  A --- B --- E

After rebase:
                    C' --- D'  (feature)
                   /
main:  A --- B --- E
```

**Command:**
```bash
git checkout feature/user-auth
git rebase main

# Or in one command:
git rebase main feature/user-auth
```

**Interactive Rebase:**
```bash
# Rebase last 3 commits
git rebase -i HEAD~3

# Opens editor with:
# pick a1b2c3d Add feature A
# pick e4f5g6h Fix typo
# pick i7j8k9l Add feature B

# Change to:
# pick a1b2c3d Add feature A
# squash e4f5g6h Fix typo
# pick i7j8k9l Add feature B
```

**Rebase Commands:**
- `pick`: Keep commit as is
- `reword`: Keep commit, edit message
- `edit`: Stop for amending
- `squash`: Combine with previous commit
- `fixup`: Like squash, discard message
- `drop`: Remove commit

---

## Advanced Git Operations

### Stashing Changes

**Save Work in Progress:**
```bash
# Stash changes
git stash

# Stash with message
git stash save "WIP: user authentication"

# Include untracked files
git stash -u
```

**View Stashes:**
```bash
git stash list

# Output:
# stash@{0}: WIP: user authentication
# stash@{1}: On main: quick fix
```

**Apply Stash:**
```bash
# Apply most recent stash
git stash apply

# Apply specific stash
git stash apply stash@{1}

# Apply and remove from stash list
git stash pop
```

**Delete Stash:**
```bash
# Delete specific stash
git stash drop stash@{0}

# Clear all stashes
git stash clear
```

---

### Cherry-Picking

**Apply Specific Commit:**
```bash
# Cherry-pick a commit
git cherry-pick a1b2c3d

# Cherry-pick multiple commits
git cherry-pick commit1 commit2 commit3

# Cherry-pick without committing
git cherry-pick -n a1b2c3d
```

**Use Case:**
```
main:     A --- B --- C
                       
hotfix:   A --- B --- X (critical fix)

# Pick X to main:
main:     A --- B --- C --- X'
```

---

### Resetting and Reverting

#### **Git Reset**

**Soft Reset:**
```bash
# Move HEAD, keep changes staged
git reset --soft HEAD~1
```

**Mixed Reset (default):**
```bash
# Move HEAD, unstage changes
git reset HEAD~1
# or
git reset --mixed HEAD~1
```

**Hard Reset:**
```bash
# Move HEAD, discard all changes (DANGEROUS!)
git reset --hard HEAD~1
```

**Visual Example:**
```
Before: main → A → B → C → D (HEAD)

After git reset --soft HEAD~2:
main → A → B (HEAD)
Changes from C and D are staged

After git reset --mixed HEAD~2:
main → A → B (HEAD)
Changes from C and D are in working directory

After git reset --hard HEAD~2:
main → A → B (HEAD)
Changes from C and D are GONE
```

---

#### **Git Revert**

**Safe Way to Undo:**
```bash
# Create new commit that undoes changes
git revert a1b2c3d

# Revert without committing
git revert -n a1b2c3d
```

**Difference between Reset and Revert:**
```
Original: A → B → C → D

git reset --hard C:
Result:   A → B → C
(D is removed from history)

git revert D:
Result:   A → B → C → D → D'
(D' undoes D's changes)
```

**When to Use:**
- **Reset**: Private branches, haven't pushed
- **Revert**: Public branches, already pushed

---

### Tags

**Create Tag:**
```bash
# Lightweight tag
git tag v1.0.0

# Annotated tag (recommended)
git tag -a v1.0.0 -m "Release version 1.0.0"

# Tag specific commit
git tag -a v0.9.0 a1b2c3d -m "Beta release"
```

**List Tags:**
```bash
# All tags
git tag

# Search tags
git tag -l "v1.0.*"
```

**Push Tags:**
```bash
# Push specific tag
git push origin v1.0.0

# Push all tags
git push origin --tags
```

**Delete Tag:**
```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0
```

---

## Branching Strategies

### GitFlow

**Best for:** Projects with scheduled releases

```
main      ────●────────────●────────────●──→ (production)
               │            │            │
release        └──●──●──●──┘            │
                  │                      │
develop   ───●───●────●────●────●───●───●──→ (development)
              │       │         │       │
feature       └──●──●─┘         └──●──●─┘
```

**Branch Types:**

**1. main (or master):**
- Production-ready code
- Tagged with version numbers
- Never commit directly

**2. develop:**
- Integration branch
- Latest delivered development changes
- Base for releases

**3. feature/* branches:**
```bash
# Create feature branch
git checkout -b feature/user-auth develop

# Merge back to develop when complete
git checkout develop
git merge --no-ff feature/user-auth
git branch -d feature/user-auth
```

**4. release/* branches:**
```bash
# Create release branch
git checkout -b release/v1.2.0 develop

# Bug fixes only on release branch
git commit -am "Bump version to 1.2.0"

# Merge to main and develop
git checkout main
git merge --no-ff release/v1.2.0
git tag -a v1.2.0

git checkout develop
git merge --no-ff release/v1.2.0
git branch -d release/v1.2.0
```

**5. hotfix/* branches:**
```bash
# Create hotfix from main
git checkout -b hotfix/critical-bug main

# Fix and merge back to main and develop
git checkout main
git merge --no-ff hotfix/critical-bug
git tag -a v1.2.1

git checkout develop
git merge --no-ff hotfix/critical-bug
git branch -d hotfix/critical-bug
```

---

### GitHub Flow

**Best for:** Continuous deployment, web applications

```
main  ──●──●──●──●──●──●──●──●──●──→
         │     │     │     │
feature  └─●─●─┘     │     │
               └─●─●─┘     │
                     └─●─●─┘
```

**Workflow:**

**1. Branch from main:**
```bash
git checkout main
git pull origin main
git checkout -b feature/add-payment
```

**2. Commit changes:**
```bash
git add .
git commit -m "Add PayPal integration"
git push origin feature/add-payment
```

**3. Open Pull Request:**
- On GitHub, create PR
- Request code review
- Discuss and review code
- CI/CD runs automatically

**4. Deploy to test environment:**
```bash
# Deploy PR to staging
kubectl apply -f deployment-staging.yaml
```

**5. Merge to main:**
```bash
# After approval
git checkout main
git merge feature/add-payment
git push origin main
```

**6. Deploy to production:**
- Triggered automatically on push to main
- Or manual deployment

---

### Trunk-Based Development

**Best for:** High-performing teams with strong CI/CD

```
main  ──●──●──●──●──●──●──●──●──●──→
         │  │  │  │  │  │
         └──┘  └──┘  └──┘
      (short-lived branches, < 1 day)
```

**Principles:**

1. **Commit frequently to main** (or very short-lived branches)
2. **Small, incremental changes**
3. **Feature flags** for incomplete features
4. **Comprehensive automated testing**
5. **Continuous Integration**

**With Feature Flags:**
```javascript
// Feature flag example
const features = {
  newPaymentSystem: process.env.ENABLE_NEW_PAYMENT === 'true'
};

function processPayment(order) {
  if (features.newPaymentSystem) {
    return newPaymentProcessor.process(order);
  } else {
    return legacyPaymentProcessor.process(order);
  }
}
```

---

### Git Environment Release Flow (GERF)

**Best for:** Multiple environments (dev, staging, prod)

```
production  ──●────────●────────→
               │        │
staging     ──●──●──●──●──●──●──→
                 │  │  │  │
develop     ──●──●──●──●──●──●──→
```

**Workflow:**
1. Code on `develop` branch
2. Merge to `staging` for testing
3. Promote to `production` when stable

---

## Git Best Practices

### Commit Message Conventions

**Conventional Commits Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**
```bash
git commit -m "feat(auth): add JWT token refresh"

git commit -m "fix(api): resolve timeout issue in user endpoint"

git commit -m "docs(readme): update installation instructions"

git commit -m "refactor(database): optimize query performance

- Added database indexes
- Implemented connection pooling
- Reduced query complexity

Closes #123"
```

---

### Atomic Commits

**One logical change per commit:**

❌ **Bad:**
```bash
git commit -m "Add feature, fix bugs, update docs"
```

✅ **Good:**
```bash
git commit -m "feat: add user authentication"
git commit -m "fix: resolve login timeout"
git commit -m "docs: update API documentation"
```

---

### .gitignore Best Practices

**Example .gitignore:**
```bash
# Dependencies
node_modules/
vendor/

# Build outputs
dist/
build/
*.min.js

# Environment variables
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Test coverage
coverage/

# Secrets
*.pem
*.key
secrets.yml
```

---

### Security Best Practices

**1. Never commit secrets:**
```bash
# Check for secrets before committing
git diff

# Remove accidentally committed secrets
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/secret" \
  --prune-empty --tag-name-filter cat -- --all
```

**2. Sign commits:**
```bash
# Configure GPG signing
git config --global user.signingkey YOUR_GPG_KEY
git config --global commit.gpgsign true

# Signed commit
git commit -S -m "Add feature"
```

**3. Verify commit signatures:**
```bash
git log --show-signature
```

---

## Collaboration with Git

### Remote Repositories

**Add Remote:**
```bash
git remote add origin https://github.com/user/repo.git

# View remotes
git remote -v
```

**Fetch vs Pull:**
```bash
# Fetch (download, don't merge)
git fetch origin

# Pull (fetch + merge)
git pull origin main

# Pull with rebase
git pull --rebase origin main
```

**Push:**
```bash
# Push to remote
git push origin main

# Push new branch
git push -u origin feature/new-feature

# Force push (DANGEROUS!)
git push --force origin main
# Safer alternative:
git push --force-with-lease origin main
```

---

### Pull Requests / Merge Requests

**Best Practices:**

**1. Small, focused PRs:**
- One feature or fix per PR
- Easier to review
- Faster to merge

**2. Descriptive titles and descriptions:**
```markdown
## Description
Add JWT-based authentication system

## Changes
- Implemented JWT token generation
- Added middleware for token validation
- Created login/logout endpoints

## Testing
- Unit tests: ✅
- Integration tests: ✅
- Manual testing: ✅

## Screenshots
[Add screenshots if UI changes]

## Closes #123
```

**3. Request appropriate reviewers:**
- Domain experts
- Team leads
- Security reviewers (for auth/security changes)

**4. Respond to feedback:**
- Be open to suggestions
- Explain your decisions
- Make requested changes

---

## Troubleshooting Common Issues

### Undo Last Commit (not pushed)
```bash
git reset --soft HEAD~1
```

### Changed a File by Mistake
```bash
# Discard changes to specific file
git checkout -- filename
# or (Git 2.23+)
git restore filename
```

### Need to Unstage File
```bash
git reset HEAD filename
# or (Git 2.23+)
git restore --staged filename
```

### Pushed Sensitive Data
```bash
# Use BFG Repo-Cleaner or git-filter-branch
# BFG is faster
bfg --delete-files secrets.txt

# Or git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch secrets.txt" \
  --prune-empty -- --all

# Force push
git push --force
```

### Merge Conflict
```bash
# See conflicts
git status

# Edit files, then:
git add resolved-file.js
git commit
```

### Accidentally Deleted Branch
```bash
# Find commit hash
git reflog

# Recreate branch
git branch recovered-branch commit-hash
```

### Detached HEAD State
```bash
# Create branch from current state
git switch -c new-branch-name
```

---

## Summary

**Key Takeaways:**

✅ Git is essential for modern software development
✅ Use meaningful commit messages (Conventional Commits)
✅ Keep branches short-lived
✅ Choose appropriate branching strategy for your team
✅ Use pull requests for code review
✅ Never commit secrets or sensitive data
✅ Commit early, commit often, push regularly

**Next Steps:**
- **Next**: [03-CICD-Fundamentals.md](./03-CICD-Fundamentals.md) - Learn CI/CD concepts
- **Related**: [05-CICD-Platforms.md](./05-CICD-Platforms.md) - Explore CI/CD tools

---

*Remember: Git is like a time machine for your code. Use it wisely!*
