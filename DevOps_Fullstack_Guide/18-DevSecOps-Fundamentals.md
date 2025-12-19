# DevSecOps Fundamentals

## Table of Contents
1. [Introduction to DevSecOps](#introduction-to-devsecops)
2. [Shift-Left Security](#shift-left-security)
3. [Security in CI/CD Pipeline](#security-in-cicd-pipeline)
4. [Static Application Security Testing (SAST)](#static-application-security-testing-sast)
5. [Dynamic Application Security Testing (DAST)](#dynamic-application-security-testing-dast)
6. [Container Security](#container-security)
7. [Secrets Management](#secrets-management)
8. [Dependency Scanning](#dependency-scanning)
9. [Infrastructure Security](#infrastructure-security)
10. [Security Best Practices](#security-best-practices)

---

## Introduction to DevSecOps

### What is DevSecOps?

**DevSecOps** = Development + Security + Operations

```
Traditional:
Dev → Ops → Security (at the end)
           ↑
    "Security bottleneck"

DevSecOps:
Dev + Security + Ops (integrated throughout)
         ↓
  "Security as Code"
```

**Core Principle:** Security is everyone's responsibility, not just a separate team.

---

### Why DevSecOps?

**Traditional Security:**
```
Week 1-8:  Development
Week 9:    Security review (finds 50 vulnerabilities!)
Week 10:   Scramble to fix
Week 11:   Retest
Week 12:   Finally deploy

Problems:
- Late discovery of issues
- Security as a bottleneck
- Stressful last-minute fixes
```

**DevSecOps:**
```
Day 1: Code → Automated security scan → Pass → Continue
Day 2: Code → Automated security scan → Fail → Fix immediately
Day 3: Code → Automated security scan → Pass → Deploy

Benefits:
✓ Early issue detection
✓ Automated security checks
✓ Fast feedback
✓ Continuous security
```

---

## Shift-Left Security

### What is Shift-Left?

Moving security earlier in the development lifecycle:

```
Traditional (Shift-Right):
Plan → Code → Build → Test → [SECURITY] → Deploy
                                    ↑
                          Security audit here

Shift-Left:
Plan → [SECURITY] → Code → [SECURITY] → Build → [SECURITY] → Deploy
         ↓                    ↓                    ↓
   Threat Model      Secure Code      Security Scan
   Design Review     Static Analysis  Dependency Check
```

---

### Benefits of Shift-Left

**1. Lower Cost:**
```
Cost to Fix Security Bug:

Development:    $100
Testing:        $1,000
Production:     $10,000

Fix early = Save money!
```

**2. Faster Delivery:**
- No security bottleneck
- Automated checks
- Continuous deployment

**3. Better Security:**
- Security by design
- Continuous verification
- Developers learn security

---

## Security in CI/CD Pipeline

### Comprehensive Security Pipeline

```yaml
# .github/workflows/security.yml
name: Security Pipeline

on: [push, pull_request]

jobs:
  # 1. Secret Scanning
  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Gitleaks scan
        uses: gitleaks/gitleaks-action@v2
  
  # 2. Static Analysis (SAST)
  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      
      - name: Semgrep SAST
        uses: returntocorp/semgrep-action@v1
  
  # 3. Dependency Scanning (SCA)
  dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: npm audit
        run: npm audit --audit-level=moderate
      
      - name: Snyk scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  
  # 4. Container Scanning
  container:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build image
        run: docker build -t myapp:latest .
      
      - name: Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:latest
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
  
  # 5. IaC Scanning
  infrastructure:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Checkov scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: infrastructure/
          framework: terraform
  
  # 6. License Compliance
  licenses:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: License check
        run: npx license-checker --production --onlyAllow "MIT;Apache-2.0;BSD-3-Clause"
```

---

## Static Application Security Testing (SAST)

### What is SAST?

**White-box testing** that analyzes source code for vulnerabilities.

**Advantages:**
- Early detection (during development)
- No running application needed
- Line-specific findings

**Limitations:**
- False positives
- Can't detect runtime issues
- Language-specific

---

### SAST Tools

**Popular Options:**
- **SonarQube/SonarCloud**
- **Semgrep**
- **Checkmarx**
- **Veracode**
- **CodeQL (GitHub)**

---

### Semgrep Example

**Configuration (.semgrep.yml):**
```yaml
rules:
  # SQL Injection
  - id: sql-injection
    pattern: |
      db.query($SQL)
    message: Potential SQL injection
    severity: ERROR
    languages: [javascript]
  
  # Hardcoded secrets
  - id: hardcoded-password
    pattern: |
      password = "..."
    message: Hardcoded password detected
    severity: ERROR
    languages: [javascript, python]
  
  # Insecure random
  - id: insecure-random
    pattern: Math.random()
    message: Use crypto.randomBytes() for security-sensitive operations
    severity: WARNING
    languages: [javascript]
```

**Run Semgrep:**
```bash
# Local scan
semgrep --config=auto .

# CI/CD
semgrep ci
```

---

### ESLint Security Plugin

```javascript
// .eslintrc.js
module.exports = {
  plugins: ['security'],
  extends: ['plugin:security/recommended'],
  rules: {
    'security/detect-eval-with-expression': 'error',
    'security/detect-non-literal-fs-filename': 'warn',
    'security/detect-non-literal-regexp': 'warn',
    'security/detect-object-injection': 'warn',
    'security/detect-possible-timing-attacks': 'warn',
    'security/detect-unsafe-regex': 'error'
  }
};
```

---

## Dynamic Application Security Testing (DAST)

### What is DAST?

**Black-box testing** that tests running applications.

**Advantages:**
- Tests actual runtime behavior
- Platform/language agnostic
- Finds configuration issues

**Limitations:**
- Requires running application
- Later in pipeline
- Can be slow

---

### OWASP ZAP Example

```yaml
# .github/workflows/dast.yml
name: DAST Scan

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  dast:
    runs-on: ubuntu-latest
    steps:
      - name: OWASP ZAP Scan
        uses: zaproxy/action-baseline@v0.7.0
        with:
          target: 'https://staging.myapp.com'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'
```

**ZAP Rules (.zap/rules.tsv):**
```
# Ignore rules
10021	IGNORE	(X-Content-Type-Options Header Missing)
10020	IGNORE	(X-Frame-Options Header Not Set)

# Alert rules
40012	FAIL	(Cross Site Scripting)
40014	FAIL	(SQL Injection)
90022	FAIL	(Application Error Disclosure)
```

---

## Container Security

### Container Security Layers

```
┌────────────────────────────────┐
│     Runtime Security           │ ← Monitor running containers
├────────────────────────────────┤
│     Image Scanning             │ ← Scan for vulnerabilities
├────────────────────────────────┤
│     Dockerfile Best Practices  │ ← Secure build
├────────────────────────────────┤
│     Base Image Selection       │ ← Trusted sources
└────────────────────────────────┘
```

---

### Secure Dockerfile

```dockerfile
# ✅ Use specific, minimal base image
FROM node:18-alpine AS builder

# ✅ Run as non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# ✅ Set working directory
WORKDIR /app

# ✅ Copy only necessary files
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

COPY --chown=nodejs:nodejs . .

# ✅ Remove unnecessary packages
RUN apk del npm

# ✅ Switch to non-root user
USER nodejs

# ✅ Expose specific port
EXPOSE 3000

# ✅ Use exec form for CMD
CMD ["node", "index.js"]

# ✅ Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD node healthcheck.js || exit 1
```

---

### Container Scanning

**Trivy:**
```bash
# Scan local image
trivy image myapp:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL myapp:latest

# Scan and fail on vulnerabilities
trivy image --exit-code 1 --severity CRITICAL myapp:latest

# Generate report
trivy image --format json --output results.json myapp:latest
```

**Snyk Container:**
```bash
# Scan and get recommendations
snyk container test myapp:latest

# Monitor image in Snyk
snyk container monitor myapp:latest
```

---

### Container Runtime Security

**Falco (Runtime Monitoring):**
```yaml
# falco_rules.yml
- rule: Unexpected Network Connection
  desc: Detect unexpected outbound connections
  condition: >
    outbound and
    container and
    not allowed_domains
  output: >
    Unexpected outbound connection
    (container=%container.name dest=%fd.rip)
  priority: WARNING

- rule: Write to /etc
  desc: Detect writes to /etc directory
  condition: >
    write and
    container and
    fd.name startswith /etc
  output: >
    Write to /etc detected
    (container=%container.name file=%fd.name)
  priority: ERROR
```

---

## Secrets Management

### Never Commit Secrets

❌ **Bad:**
```javascript
// config.js
const dbPassword = "SuperSecret123";
const apiKey = "sk_live_abc123xyz";
```

✅ **Good:**
```javascript
// config.js
const dbPassword = process.env.DB_PASSWORD;
const apiKey = process.env.API_KEY;
```

---

### Pre-commit Hooks

**git-secrets:**
```bash
# Install
brew install git-secrets

# Initialize
git secrets --install

# Add patterns to detect
git secrets --register-aws

# Scan repository
git secrets --scan
```

**Gitleaks:**
```bash
# Install pre-commit hook
gitleaks protect --staged --verbose

# Scan entire repo
gitleaks detect --verbose
```

**pre-commit config:**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.16.0
    hooks:
      - id: gitleaks
```

---

### HashiCorp Vault

**Architecture:**
```
Application
    ↓ (request secret)
Vault Agent/SDK
    ↓ (authenticate)
Vault Server
    ↓ (retrieve)
Secret Storage (encrypted)
```

**Node.js Example:**
```javascript
const vault = require('node-vault')({
  endpoint: 'http://vault:8200',
  token: process.env.VAULT_TOKEN
});

async function getSecret(path) {
  try {
    const result = await vault.read(path);
    return result.data;
  } catch (error) {
    console.error('Failed to read secret:', error);
    throw error;
  }
}

// Usage
const dbCreds = await getSecret('secret/database');
const dbPassword = dbCreds.password;
```

**Vault in Kubernetes:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "myapp"
    vault.hashicorp.com/agent-inject-secret-db: "secret/database"
spec:
  serviceAccountName: myapp
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: DB_PASSWORD
      value: /vault/secrets/db
```

---

### AWS Secrets Manager

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

async function getSecret(secretName) {
  try {
    const data = await secretsManager.getSecretValue({
      SecretId: secretName
    }).promise();
    
    if ('SecretString' in data) {
      return JSON.parse(data.SecretString);
    }
  } catch (error) {
    console.error('Failed to retrieve secret:', error);
    throw error;
  }
}

// Usage
const dbCreds = await getSecret('prod/database/credentials');
```

---

## Dependency Scanning

### npm audit

```bash
# Check for vulnerabilities
npm audit

# Fix automatically
npm audit fix

# Force fix (may introduce breaking changes)
npm audit fix --force

# Get detailed report
npm audit --json

# Fail CI if vulnerabilities found
npm audit --audit-level=moderate
```

---

### Snyk

```bash
# Install
npm install -g snyk

# Authenticate
snyk auth

# Test project
snyk test

# Monitor project (continuous monitoring)
snyk monitor

# Test and fix
snyk test --fix
```

**Snyk in CI/CD:**
```yaml
- name: Snyk test
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  with:
    args: --severity-threshold=high
```

---

### Dependabot

**GitHub Dependabot config:**
```yaml
# .github/dependabot.yml
version: 2
updates:
  # npm dependencies
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"
  
  # Docker dependencies
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
  
  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## Infrastructure Security

### Terraform Security Scanning

**Checkov:**
```bash
# Scan Terraform files
checkov -d infrastructure/

# Scan specific file
checkov -f main.tf

# Output as JSON
checkov -d infrastructure/ --output json

# Fail on specific severity
checkov -d infrastructure/ --compact --quiet --framework terraform
```

**Example Rules:**
```hcl
# ❌ Bad: S3 bucket publicly accessible
resource "aws_s3_bucket" "bad_bucket" {
  bucket = "my-bucket"
  acl    = "public-read"  # Security risk!
}

# ✅ Good: S3 bucket with proper access control
resource "aws_s3_bucket" "good_bucket" {
  bucket = "my-bucket"
  acl    = "private"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  versioning {
    enabled = true
  }
  
  logging {
    target_bucket = aws_s3_bucket.logs.id
    target_prefix = "access-logs/"
  }
}

resource "aws_s3_bucket_public_access_block" "good_bucket" {
  bucket = aws_s3_bucket.good_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

---

### Network Security

**Security Groups (AWS):**
```hcl
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  
  # ✅ Specific ingress rules
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from bastion only"
  }
  
  # ❌ Never do this
  # ingress {
  #   from_port   = 0
  #   to_port     = 65535
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## Security Best Practices

### 1. Principle of Least Privilege

```yaml
# ❌ Bad: Admin access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: myapp
subjects:
- kind: ServiceAccount
  name: myapp
roleRef:
  kind: ClusterRole
  name: cluster-admin  # Too much access!

# ✅ Good: Minimal necessary permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: myapp
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["myapp-secrets"]
  verbs: ["get"]
```

---

### 2. Defense in Depth

```
Multiple layers of security:

┌────────────────────────────────┐
│  WAF (Web Application Firewall)│
├────────────────────────────────┤
│  Network Security (Firewall)   │
├────────────────────────────────┤
│  Application Security (Auth)   │
├────────────────────────────────┤
│  Data Encryption (at rest)     │
└────────────────────────────────┘

If one layer fails, others protect.
```

---

### 3. Security Monitoring

```javascript
// Log security events
logger.warn('Failed login attempt', {
  userId: req.body.username,
  ip: req.ip,
  userAgent: req.headers['user-agent'],
  timestamp: new Date()
});

// Alert on suspicious activity
if (failedAttempts > 5) {
  alertSecurityTeam({
    event: 'Multiple failed logins',
    user: username,
    ip: req.ip,
    count: failedAttempts
  });
}
```

---

### 4. Regular Security Audits

```bash
# Scheduled security scans
0 2 * * * /usr/local/bin/security-scan.sh

# Monthly penetration testing
# Quarterly security reviews
# Annual third-party audits
```

---

### 5. Incident Response Plan

```
1. Detection
   ↓
2. Containment (isolate affected systems)
   ↓
3. Eradication (remove threat)
   ↓
4. Recovery (restore services)
   ↓
5. Lessons Learned (post-mortem)
```

---

### 6. Security Training

```
- Developers: Secure coding practices
- Ops: Security configuration
- Everyone: Phishing awareness, password management
- Regular: Security workshops, CTF challenges
```

---

## Summary

**Key Takeaways:**

✅ **DevSecOps** integrates security throughout SDLC
✅ **Shift-left** security catches issues early
✅ **Automate** security scans in CI/CD pipeline
✅ **Never commit secrets** to version control
✅ **Scan dependencies** regularly
✅ **Secure containers** from build to runtime
✅ **Infrastructure as Code** security scanning
✅ **Defense in depth** with multiple security layers

**Security Checklist:**
- [ ] SAST in CI/CD
- [ ] DAST for running apps
- [ ] Dependency scanning
- [ ] Container image scanning
- [ ] Secrets management solution
- [ ] IaC security scanning
- [ ] Runtime security monitoring
- [ ] Regular security audits

**Next Steps:**
- **Next**: [19-Secrets-Management.md](./19-Secrets-Management.md) - Deep dive into secrets
- **Related**: [20-Security-Best-Practices.md](./20-Security-Best-Practices.md) - Advanced security

---

*Remember: Security is not a feature, it's a requirement. Bake it into everything you do!*
