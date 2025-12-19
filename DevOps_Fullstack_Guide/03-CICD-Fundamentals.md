# CI/CD Fundamentals

## Table of Contents
1. [Introduction to CI/CD](#introduction-to-cicd)
2. [Continuous Integration (CI)](#continuous-integration-ci)
3. [Continuous Delivery (CD)](#continuous-delivery-cd)
4. [Continuous Deployment](#continuous-deployment)
5. [CI/CD Pipeline Components](#cicd-pipeline-components)
6. [Pipeline Design Patterns](#pipeline-design-patterns)
7. [Testing in CI/CD](#testing-in-cicd)
8. [Deployment Strategies](#deployment-strategies)
9. [CI/CD Best Practices](#cicd-best-practices)

---

## Introduction to CI/CD

### What is CI/CD?

**CI/CD** is a method to frequently deliver apps to customers by introducing automation into the stages of app development. The main concepts are:

- **CI**: Continuous Integration
- **CD**: Continuous Delivery **OR** Continuous Deployment

```
Developer → Commit → CI Pipeline → CD Pipeline → Production
   ↓           ↓          ↓             ↓            ↓
 Code      Version     Build/Test    Package     Deploy
           Control     Automated     Release    Automated
```

---

### The Evolution of Software Deployment

**Traditional (Manual):**
```
Week 1-4:  Development
Week 5:    Integration (pain!)
Week 6:    Testing
Week 7:    Manual deployment preparation
Week 8:    Deploy on Friday night (pray!)
Weekend:   Fix production issues

Result: Quarterly releases, high stress, many failures
```

**With CI/CD:**
```
Day 1:  Code → Commit → Build → Test → Deploy to Dev → Monitor
Day 2:  Code → Commit → Build → Test → Deploy to Staging → Monitor
Day 3:  Code → Commit → Build → Test → Deploy to Prod → Monitor

Result: Daily/hourly releases, low stress, quick fixes
```

---

### Benefits of CI/CD

**1. Faster Time to Market:**
- Automate repetitive tasks
- Deploy multiple times per day
- Quick feature delivery

**2. Improved Code Quality:**
- Automated testing on every commit
- Early bug detection
- Consistent quality checks

**3. Reduced Risk:**
- Small, incremental changes
- Easy rollbacks
- Quick recovery

**4. Better Collaboration:**
- Immediate feedback
- Shared responsibility
- Transparent process

**5. Increased Productivity:**
- Developers focus on coding
- Less time on manual tasks
- Automated workflows

---

## Continuous Integration (CI)

### What is Continuous Integration?

**Definition:** The practice of frequently merging all developers' working copies to a shared mainline (main/master branch), multiple times a day.

### Core Principles

**1. Maintain a Single Source Repository:**
```
GitHub/GitLab/Bitbucket
         ↓
   main branch
    (single source of truth)
```

**2. Automate the Build:**
```javascript
// package.json
{
  "scripts": {
    "build": "webpack --mode production",
    "test": "jest",
    "lint": "eslint src/"
  }
}
```

**3. Make Build Self-Testing:**
```bash
npm run build && npm run test
# If either fails, build fails
```

**4. Everyone Commits to Mainline Every Day:**
```bash
# Multiple commits per day
git commit -m "feat: add user validation"
git push origin main
# Triggers CI pipeline
```

**5. Every Commit Builds Mainline on Integration Machine:**
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: npm install
      - run: npm run build
      - run: npm test
```

**6. Fix Broken Builds Immediately:**
```
Build Status: ❌ FAILED
Action: Stop everything, fix NOW
Priority: Highest
```

**7. Keep Build Fast:**
```
Target: < 10 minutes
Ideal:  < 5 minutes
```

---

### CI Workflow

```mermaid
graph LR
    A[Developer Commits Code] --> B[Trigger CI Pipeline]
    B --> C[Checkout Code]
    C --> D[Install Dependencies]
    D --> E[Lint Code]
    E --> F{Lint Pass?}
    F -->|No| G[Notify Developer]
    F -->|Yes| H[Build Application]
    H --> I{Build Success?}
    I -->|No| G
    I -->|Yes| J[Run Unit Tests]
    J --> K{Tests Pass?}
    K -->|No| G
    K -->|Yes| L[Run Integration Tests]
    L --> M{Tests Pass?}
    M -->|No| G
    M -->|Yes| N[Security Scan]
    N --> O{Scan Pass?}
    O -->|No| G
    O -->|Yes| P[Build Artifact]
    P --> Q[Upload to Registry]
    Q --> R[✅ CI Success]
```

---

### Example CI Pipeline

**GitHub Actions Example:**
```yaml
# .github/workflows/ci.yml
name: Continuous Integration

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [16.x, 18.x, 20.x]
    
    steps:
      # 1. Checkout code
      - name: Checkout repository
        uses: actions/checkout@v3
      
      # 2. Setup Node.js
      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      
      # 3. Install dependencies
      - name: Install dependencies
        run: npm ci
      
      # 4. Lint code
      - name: Run linter
        run: npm run lint
      
      # 5. Run tests
      - name: Run unit tests
        run: npm run test:unit
      
      - name: Run integration tests
        run: npm run test:integration
      
      # 6. Generate coverage report
      - name: Generate coverage
        run: npm run test:coverage
      
      # 7. Upload coverage to Codecov
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/coverage-final.json
      
      # 8. Build application
      - name: Build application
        run: npm run build
      
      # 9. Run security audit
      - name: Security audit
        run: npm audit --audit-level=moderate
      
      # 10. Build Docker image
      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .
      
      # 11. Scan Docker image
      - name: Scan Docker image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'

  # Separate job for code quality
  code-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

## Continuous Delivery (CD)

### What is Continuous Delivery?

**Definition:** An extension of CI where code changes are automatically built, tested, and prepared for production release.

**Key Difference from CI:**
- **CI**: Code is built and tested
- **CD**: Code is also packaged and **ready to deploy**
- **Deployment**: Manual, requires human approval

```
CI Pipeline → Artifact Ready → Manual Approval → Deploy
```

---

### CD Workflow

```
Developer Commit
      ↓
CI Pipeline (Build, Test)
      ↓
Create Release Candidate
      ↓
Deploy to Staging Environment
      ↓
Automated Acceptance Tests
      ↓
Manual Approval/Review
      ↓
Deploy to Production (Manual trigger)
      ↓
Monitor and Validate
```

---

### Example CD Pipeline

**GitLab CI/CD Example:**
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - package
  - deploy-staging
  - deploy-production

variables:
  DOCKER_IMAGE: registry.gitlab.com/mycompany/myapp

# Build Stage
build:
  stage: build
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

# Test Stage
test:unit:
  stage: test
  script:
    - npm run test:unit
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'

test:integration:
  stage: test
  script:
    - npm run test:integration

# Package Stage
package:
  stage: package
  script:
    - docker build -t $DOCKER_IMAGE:$CI_COMMIT_SHA .
    - docker tag $DOCKER_IMAGE:$CI_COMMIT_SHA $DOCKER_IMAGE:latest
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHA
    - docker push $DOCKER_IMAGE:latest
  only:
    - main

# Deploy to Staging
deploy:staging:
  stage: deploy-staging
  script:
    - kubectl config use-context staging
    - kubectl set image deployment/myapp myapp=$DOCKER_IMAGE:$CI_COMMIT_SHA
    - kubectl rollout status deployment/myapp
  environment:
    name: staging
    url: https://staging.myapp.com
  only:
    - main

# Deploy to Production (Manual)
deploy:production:
  stage: deploy-production
  script:
    - kubectl config use-context production
    - kubectl set image deployment/myapp myapp=$DOCKER_IMAGE:$CI_COMMIT_SHA
    - kubectl rollout status deployment/myapp
  environment:
    name: production
    url: https://myapp.com
  when: manual  # Requires manual trigger
  only:
    - main
```

---

## Continuous Deployment

### What is Continuous Deployment?

**Definition:** Every change that passes automated tests is automatically deployed to production **without manual intervention**.

**The Full Pipeline:**
```
Code → CI → Automated Tests → Automated Deploy to Prod → Monitor
```

**Difference from Continuous Delivery:**
```
Continuous Delivery:
Code → Build → Test → Package → [MANUAL GATE] → Production

Continuous Deployment:
Code → Build → Test → Package → AUTOMATIC → Production
```

---

### Requirements for Continuous Deployment

**1. Comprehensive Automated Testing:**
```
Testing Pyramid:
        /\        E2E (Few)
       /  \       
      /────\      Integration (Some)
     /      \     
    /────────\    Unit (Many)
   /          \   
  /────────────\  
```

**2. Monitoring and Observability:**
```javascript
// Real-time monitoring
const metrics = {
  errorRate: 0.01,      // 1% error rate
  latency: 150,         // 150ms average
  throughput: 1000,     // 1000 req/sec
  availability: 99.99   // 99.99% uptime
};

if (metrics.errorRate > 0.05) {
  rollback();
  alert('High error rate detected!');
}
```

**3. Feature Flags:**
```javascript
// Deploy code, enable features gradually
const featureFlags = {
  newCheckout: process.env.ENABLE_NEW_CHECKOUT === 'true',
  betaFeature: getUserBetaStatus(user.id)
};

function renderCheckout() {
  if (featureFlags.newCheckout) {
    return <NewCheckoutUI />;
  }
  return <LegacyCheckoutUI />;
}
```

**4. Automated Rollback:**
```yaml
# Automatic rollback on failure
deploy:
  script:
    - deploy-new-version.sh
    - monitor-metrics.sh 5m  # Monitor for 5 minutes
    - |
      if [ $? -ne 0 ]; then
        echo "Metrics degraded, rolling back"
        rollback-to-previous.sh
      fi
```

---

## CI/CD Pipeline Components

### 1. **Source Stage**

**Trigger Events:**
```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:  # Manual trigger
```

---

### 2. **Build Stage**

**Compilation and Packaging:**
```yaml
build:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    
    # Install dependencies
    - run: npm ci
    
    # Build application
    - run: npm run build
    
    # Create production bundle
    - run: tar -czf app-${{ github.sha }}.tar.gz dist/
    
    # Upload artifact
    - uses: actions/upload-artifact@v3
      with:
        name: production-bundle
        path: app-${{ github.sha }}.tar.gz
```

---

### 3. **Test Stage**

**Multi-Level Testing:**
```yaml
test:
  needs: build
  strategy:
    matrix:
      test-type: [unit, integration, e2e]
  steps:
    - uses: actions/checkout@v3
    - uses: actions/download-artifact@v3
    
    - name: Run ${{ matrix.test-type }} tests
      run: npm run test:${{ matrix.test-type }}
    
    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-results-${{ matrix.test-type }}
        path: test-results/
```

---

### 4. **Quality Stage**

**Code Quality Checks:**
```yaml
quality:
  runs-on: ubuntu-latest
  steps:
    # Linting
    - name: ESLint
      run: npm run lint
    
    # Code complexity
    - name: Code complexity check
      run: npx complexity-report
    
    # Duplicate code detection
      run: npx jscpd
    
    # Security vulnerabilities
    - name: npm audit
      run: npm audit --audit-level=high
    
    # SAST (Static Application Security Testing)
    - name: Snyk security scan
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

---

### 5. **Artifact Stage**

**Create and Store Artifacts:**
```yaml
artifact:
  needs: [test, quality]
  steps:
    # Build Docker image
    - name: Build Docker image
      run: |
        docker build \
          -t myapp:${{ github.sha }} \
          -t myapp:latest \
          .
    
    # Push to container registry
    - name: Push to registry
      run: |
        echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
        docker push myapp:${{ github.sha }}
        docker push myapp:latest
    
    # Create GitHub release
    - name: Create release
      if: startsWith(github.ref, 'refs/tags/')
      uses: actions/create-release@v1
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
```

---

### 6. **Deploy Stage**

**Environment Deployment:**
```yaml
deploy:
  needs: artifact
  strategy:
    matrix:
      environment: [dev, staging, production]
  environment:
    name: ${{ matrix.environment }}
    url: https://${{ matrix.environment }}.myapp.com
  steps:
    - name: Deploy to ${{ matrix.environment }}
      run: |
        kubectl set image deployment/myapp \
          myapp=myapp:${{ github.sha }} \
          --namespace=${{ matrix.environment }}
        
        kubectl rollout status deployment/myapp \
          --namespace=${{ matrix.environment }}
```

---

## Pipeline Design Patterns

### 1. **Fan-Out Pattern**

Run multiple jobs in parallel for speed:
```yaml
test:
  strategy:
    matrix:
      os: [ubuntu-latest, windows-latest, macos-latest]
      node-version: [16, 18, 20]
  # Runs 9 jobs in parallel (3 OS × 3 versions)
```

---

### 2. **Fan-In Pattern**

Wait for multiple jobs before proceeding:
```yaml
deploy:
  needs: [test-unit, test-integration, test-e2e, security-scan]
  # Runs only after all dependencies complete
```

---

### 3. **Pipeline as Code**

Store pipeline definition in version control:
```
myproject/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── cd.yml
│       └── nightly.yml
├── src/
└── package.json
```

---

### 4. **Multi-Stage Pipeline**

Separate concerns into distinct stages:
```yaml
stages:
  - validate      # Quick checks (< 5 min)
  - build         # Compilation (< 10 min)
  - test          # All tests (< 15 min)
  - scan          # Security scans (< 10 min)
  - package       # Create artifacts
  - deploy-dev    # Auto deploy to dev
  - deploy-stage  # Auto deploy to staging
  - deploy-prod   # Manual deploy to prod
```

---

### 5. **Trunk-Based Pipeline**

Optimized for frequent commits to main:
```yaml
on:
  push:
    branches: [main]

jobs:
  fast-feedback:
    # Run quick checks first
    steps:
      - run: npm run lint
      - run: npm run test:unit
  
  full-pipeline:
    needs: fast-feedback
    # Run comprehensive checks
```

---

## Testing in CI/CD

### Test Pyramid

```
                E2E Tests
               (Slow, Brittle)
               Few tests
        ┌──────────────────┐
        │  User Interface  │
        │   API Contract   │
        └──────────────────┘
    
       Integration Tests
       (Medium Speed)
       Some tests
   ┌─────────────────────────┐
   │   Component Integration │
   │   Database Integration  │
   │   API Integration       │
   └─────────────────────────┘

          Unit Tests
        (Fast, Stable)
        Many tests
┌──────────────────────────────────┐
│   Functions, Methods, Classes    │
│   Business Logic                 │
│   Utilities                      │
└──────────────────────────────────┘
```

---

### Unit Tests in Pipeline

```yaml
test:unit:
  script:
    - npm run test:unit
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
```

**Example Unit Test:**
```javascript
// user.test.js
describe('User Service', () => {
  test('should create user with valid data', async () => {
    const user = await UserService.create({
      email: 'test@example.com',
      password: 'SecurePass123'
    });
    
    expect(user.id).toBeDefined();
    expect(user.email).toBe('test@example.com');
    expect(user.password).not.toBe('SecurePass123'); // Should be hashed
  });
  
  test('should reject invalid email', async () => {
    await expect(
      UserService.create({
        email: 'invalid-email',
        password: 'SecurePass123'
      })
    ).rejects.toThrow('Invalid email format');
  });
});
```

---

### Integration Tests in Pipeline

```yaml
test:integration:
  services:
    - postgres:14
    - redis:7
  variables:
    DATABASE_URL: postgres://user:pass@postgres:5432/testdb
    REDIS_URL: redis://redis:6379
  script:
    - npm run migrate  # Run database migrations
    - npm run test:integration
```

**Example Integration Test:**
```javascript
// api.integration.test.js
describe('User API Integration', () => {
  beforeAll(async () => {
    await setupTestDatabase();
  });
  
  afterAll(async () => {
    await teardownTestDatabase();
  });
  
  test('should register and login user', async () => {
    // Register
    const registerResponse = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'SecurePass123'
      });
    
    expect(registerResponse.status).toBe(201);
    expect(registerResponse.body.user.email).toBe('test@example.com');
    
    // Login
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'SecurePass123'
      });
    
    expect(loginResponse.status).toBe(200);
    expect(loginResponse.body.token).toBeDefined();
  });
});
```

---

### E2E Tests in Pipeline

```yaml
test:e2e:
  image: cypress/included:12.0.0
  script:
    - npm run start:test &  # Start app in background
    - wait-on http://localhost:3000
    - npm run test:e2e
  artifacts:
    when: always
    paths:
      - cypress/videos/
      - cypress/screenshots/
```

**Example E2E Test:**
```javascript
// cypress/e2e/user-flow.cy.js
describe('User Registration and Login Flow', () => {
  it('should complete full user journey', () => {
    // Visit homepage
    cy.visit('/');
    
    // Click register
    cy.contains('Sign Up').click();
    
    // Fill registration form
    cy.get('[data-testid="email-input"]').type('test@example.com');
    cy.get('[data-testid="password-input"]').type('SecurePass123');
    cy.get('[data-testid="submit-button"]').click();
    
    // Verify redirect to dashboard
    cy.url().should('include', '/dashboard');
    cy.contains('Welcome, test@example.com');
    
    // Logout
    cy.get('[data-testid="logout-button"]').click();
    
    // Login again
    cy.get('[data-testid="login-link"]').click();
    cy.get('[data-testid="email-input"]').type('test@example.com');
    cy.get('[data-testid="password-input"]').type('SecurePass123');
    cy.get('[data-testid="submit-button"]').click();
    
    // Verify logged in
    cy.url().should('include', '/dashboard');
  });
});
```

---

## Deployment Strategies

### 1. **Recreate Deployment**

```
Old Version: [V1] [V1] [V1] → Stop all
Downtime: ⏸️
New Version: [V2] [V2] [V2] → Start all
```

**Pros:**
- Simple
- Clean cutover

**Cons:**
- Downtime required
- High risk

**Use Case:** Development/staging environments

---

### 2. **Rolling Deployment**

```
Step 1: [V2] [V1] [V1] [V1]
Step 2: [V2] [V2] [V1] [V1]
Step 3: [V2] [V2] [V2] [V1]
Step 4: [V2] [V2] [V2] [V2]
```

**Pros:**
- No downtime
- Gradual rollout

**Cons:**
- Mixed versions running
- Slower deployment

**Kubernetes Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max 1 extra pod
      maxUnavailable: 1  # Max 1 unavailable
```

---

### 3. **Blue-Green Deployment**

```
Blue (V1):  [V1] [V1] [V1] ← 100% traffic
Green (V2): [V2] [V2] [V2] ← 0% traffic

Switch Router:
Blue (V1):  [V1] [V1] [V1] ← 0% traffic
Green (V2): [V2] [V2] [V2] ← 100% traffic
```

**Pros:**
- Zero downtime
- Instant rollback
- Testing in production environment

**Cons:**
- Double resources required
- Database migrations tricky

**Implementation:**
```bash
# Deploy green environment
kubectl apply -f deployment-v2.yaml

# Wait for green to be ready
kubectl wait --for=condition=available deployment/myapp-v2

# Switch traffic
kubectl patch service myapp -p '{"spec":{"selector":{"version":"v2"}}}'

# Keep blue for rollback, delete later
kubectl delete deployment myapp-v1
```

---

### 4. **Canary Deployment**

```
Production: [V1] [V1] [V1] [V1] ← 95% traffic
Canary:     [V2]                 ← 5% traffic

If successful, gradually increase:
[V1] [V1] [V1] [V2] ← 75% / 25%
[V1] [V1] [V2] [V2] ← 50% / 50%
[V1] [V2] [V2] [V2] ← 25% / 75%
[V2] [V2] [V2] [V2] ← 100%
```

**Pros:**
- Low risk
- Real production testing
- Gradual rollout

**Cons:**
- Complex setup
- Requires monitoring

**Istio Example:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
    - myapp.com
  http:
    - match:
        - headers:
            user-agent:
              regex: ".*Chrome.*"
      route:
        - destination:
            host: myapp
            subset: v2
          weight: 10
        - destination:
            host: myapp
            subset: v1
          weight: 90
```

---

### 5. **A/B Testing Deployment**

Similar to canary, but based on user criteria:
```yaml
# Route based on user attributes
- match:
    - headers:
        user-type:
          exact: "beta-tester"
  route:
    - destination:
        host: myapp
        subset: v2
```

---

## CI/CD Best Practices

### 1. **Keep Pipelines Fast**

**Targets:**
```
Lint/Quick checks:  < 2 minutes
Unit tests:         < 5 minutes
Full CI pipeline:   < 10 minutes
Full CD pipeline:   < 30 minutes
```

**Optimize:**
- Run tests in parallel
- Cache dependencies
- Use incremental builds
- Optimize test suite

```yaml
# Cache dependencies
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

---

### 2. **Fail Fast**

Run quick checks first:
```yaml
stages:
  - lint          # 1 minute
  - unit-test     # 3 minutes
  - build         # 5 minutes
  - integration   # 10 minutes
  - e2e           # 15 minutes
```

---

### 3. **Version Everything**

```yaml
# Tag Docker images
docker build -t myapp:$VERSION .
docker tag myapp:$VERSION myapp:latest

# Tag git commits
git tag -a v1.2.3 -m "Release 1.2.3"
```

---

### 4. **Immutable Artifacts**

```
Build once, deploy everywhere:

Build → myapp:abc123
         ↓
Deploy to Dev (myapp:abc123)
         ↓
Deploy to Staging (myapp:abc123)
         ↓
Deploy to Production (myapp:abc123)

Same artifact, different environments!
```

---

### 5. **Automate Testing**

**Test Coverage Target:** 70-80%

```javascript
// jest.config.js
module.exports = {
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  }
};
```

---

### 6. **Monitor Deployments**

```javascript
// Monitor after deployment
const healthCheck = async () => {
  const metrics = await getMetrics();
  
  if (metrics.errorRate > 0.05) {
    await rollback();
    alert('Deployment rolled back due to high error rate');
  }
};

// Run health checks for 10 minutes after deployment
for (let i = 0; i < 10; i++) {
  await healthCheck();
  await sleep(60000); // Wait 1 minute
}
```

---

### 7. **Use Environment Variables**

```yaml
# Never hardcode secrets!
env:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
  API_KEY: ${{ secrets.API_KEY }}
  
  # Environment-specific configs
  NODE_ENV: production
  LOG_LEVEL: info
```

---

### 8. **Implement Rollback Strategy**

```yaml
deploy:
  script:
    - deploy-new-version.sh
  on_failure:
    - rollback-to-previous.sh
    - notify-team.sh
```

---

### 9. **Pipeline as Code**

Store pipeline definitions in version control:
```
Pros:
- Version controlled
- Code reviewed
- Collaborative
- Reproducible
```

---

## Summary

**Key Takeaways:**

✅ **CI/CD automates** the software delivery process
✅ **Continuous Integration** = frequent merges + automated builds/tests
✅ **Continuous Delivery** = always ready to deploy (manual trigger)
✅ **Continuous Deployment** = fully automated deployment
✅ **Test thoroughly** at every stage
✅ **Deploy strategically** (rolling, blue-green, canary)
✅ **Monitor and rollback** when needed
✅ **Keep pipelines fast** and fail fast

**Next Steps:**
- **Next**: [04-Build-Tools-Automation.md](./04-Build-Tools-Automation.md) - Learn about build tools
- **Related**: [05-CICD-Platforms.md](./05-CICD-Platforms.md) - Explore CI/CD platforms

---

*Remember: The goal of CI/CD is to make software delivery boring and predictable!*
