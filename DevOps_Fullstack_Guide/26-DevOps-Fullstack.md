# DevOps for Fullstack Applications

## Table of Contents
1. [Fullstack DevOps Overview](#fullstack-devops-overview)
2. [Repository Strategies](#repository-strategies)
3. [Environment Management](#environment-management)
4. [End-to-End CI/CD Pipeline](#end-to-end-cicd-pipeline)
5. [Database Management](#database-management)
6. [Testing Strategy](#testing-strategy)
7. [Deployment Patterns](#deployment-patterns)

---

## Fullstack DevOps Overview

### Typical Fullstack Architecture

```
Frontend (React/Vue/Angular)
     ↓
API Gateway / Backend (Node.js/Python/Go)
     ↓
Database (PostgreSQL/MongoDB)
     ↓
Cache (Redis)
Message Queue (RabbitMQ)
```

### DevOps Challenges

**1. Multiple Technologies:**
```
- Frontend: npm, webpack, React
- Backend: Node.js, Express, TypeScript
- Database: PostgreSQL migrations
- Infrastructure: Docker, Kubernetes, Terraform
```

**2. Coordinated Deployments:**
```
Problem: Frontend v2 + Backend v1 = Break!
Solution: Versioning, compatibility, feature flags
```

**3. End-to-End Testing:**
```
Unit → Integration → API → E2E → Performance
```

---

## Repository Strategies

### Monorepo

**Structure:**
```
myapp/
├── apps/
│   ├── frontend/        (React app)
│   ├── backend/         (Node API)
│   └── admin/           (Admin panel)
├── packages/
│   ├── shared-types/    (TypeScript types)
│   ├── ui-components/   (Shared components)
│   └── utils/           (Common utilities)
├── infrastructure/
│   └── terraform/
├── .github/workflows/
│   ├── frontend-ci.yml
│   ├── backend-ci.yml
│   └── deploy.yml
└── package.json
```

**Tools:**
- **Nx**: `npx create-nx-workspace@latest`
- **Turborepo**: `npx create-turbo@latest`
- **Lerna**: Classic monorepo tool

**Pros:**
- Share code easily
- Atomic commits across stack
- Single CI/CD setup
- Easier refactoring

**Cons:**
- Larger repository
- Longer CI times (without caching)
- Team permissions complexity

---

### Multi-Repo (Polyrepo)

**Structure:**
```
myapp-frontend/      (Separate repo)
myapp-backend/       (Separate repo)
myapp-infrastructure/(Separate repo)
```

**Pros:**
- Independent deployment
- Smaller repositories
- Team autonomy
- Technology flexibility

**Cons:**
- Code sharing harder
- Version coordination
- Multiple CI/CD setups

---

## Environment Management

### Environment Hierarchy

```
Development (Local)
   ↓
Development (Shared)
   ↓
Staging
   ↓
Production
```

### Configuration Strategy

**Environment-specific configs:**
```javascript
// config/index.js
const configs = {
  development: {
    api: 'http://localhost:3000',
    database: 'postgres://localhost/myapp_dev',
    redis: 'redis://localhost:6379',
    logLevel: 'debug'
  },
  
  staging: {
    api: 'https://api.staging.myapp.com',
    database: process.env.DATABASE_URL,
    redis: process.env.REDIS_URL,
    logLevel: 'info'
  },
  
  production: {
    api: 'https://api.myapp.com',
    database: process.env.DATABASE_URL,
    redis: process.env.REDIS_URL,
    logLevel: 'error'
  }
};

export default configs[process.env.NODE_ENV|| 'development'];
```

**Kubernetes ConfigMaps per Environment:**
```yaml
# config/dev/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: development
data:
  API_URL: "https://api.dev.myapp.com"
  LOG_LEVEL: "debug"
  CACHE_TTL: "60"

---
# config/prod/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  API_URL: "https://api.myapp.com"
  LOG_LEVEL: "error"
  CACHE_TTL: "3600"
```

---

## End-to-End CI/CD Pipeline

### Complete Workflow

```yaml
# .github/workflows/fullstack-cicd.yml
name: Fullstack CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # 1. Frontend CI
  frontend-ci:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./frontend
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Unit tests
        run: npm test
      
      - name: Build
        run: npm run build
        env:
          REACT_APP_API_URL: ${{ secrets.API_URL }}
      
      - name: Upload build
        uses: actions/upload-artifact@v3
        with:
          name: frontend-build
          path: frontend/build/

  # 2. Backend CI
  backend-ci:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./backend
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Run migrations
        run: npm run migrate
        env:
          DATABASE_URL: postgresql://postgres:postgres@postgres:5432/test
      
      - name: Unit tests
        run: npm test
      
      - name: Integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://postgres:postgres@postgres:5432/test
          REDIS_URL: redis://redis:6379
      
      - name: Build
        run: npm run build

  # 3. E2E Tests
  e2e-tests:
    needs: [frontend-ci, backend-ci]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Download frontend build
        uses: actions/download-artifact@v3
        with:
          name: frontend-build
          path: frontend/build
      
      - name: Start services
        run: docker-compose -f docker-compose.test.yml up -d
      
      - name: Wait for services
        run: ./scripts/wait-for-services.sh
      
      - name: Run E2E tests
        run: npm run test:e2e
        working-directory: ./e2e
      
      - name: Upload screenshots
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-screenshots
          path: e2e/screenshots/

  # 4. Build Docker Images
  build-images:
    needs: [e2e-tests]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push frontend
        uses: docker/build-push-action@v4
        with:
          context: ./frontend
          push: true
          tags: |
            ghcr.io/${{ github.repository }}/frontend:${{ github.sha }}
            ghcr.io/${{ github.repository }}/frontend:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Build and push backend
        uses: docker/build-push-action@v4
        with:
          context: ./backend
          push: true
          tags: |
            ghcr.io/${{ github.repository }}/backend:${{ github.sha }}
            ghcr.io/${{ github.repository }}/backend:latest

  # 5. Deploy to Staging
  deploy-staging:
    needs: [build-images]
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.myapp.com
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBE_CONFIG_STAGING }}
      
      - name: Deploy
        run: |
          kubectl set image deployment/frontend \
            frontend=ghcr.io/${{ github.repository }}/frontend:${{ github.sha }} \
            -n staging
          
          kubectl set image deployment/backend \
            backend=ghcr.io/${{ github.repository }}/backend:${{ github.sha }} \
            -n staging
          
          kubectl rollout status deployment/frontend -n staging
          kubectl rollout status deployment/backend -n staging
      
      - name: Run smoke tests
        run: ./scripts/smoke-test.sh staging

  # 6. Deploy to Production (Manual)
  deploy-production:
    needs: [deploy-staging]
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.com
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBE_CONFIG_PROD }}
      
      - name: Deploy with canary
        run: |
          # Deploy canary (10% traffic)
          kubectl apply -f k8s/prod/canary.yaml
          
          # Wait 10 minutes
          sleep 600
          
          # Check metrics
          ./scripts/check-canary-metrics.sh
          
          # If OK, proceed with full rollout
          kubectl set image deployment/frontend \
            frontend=ghcr.io/${{ github.repository }}/frontend:${{ github.sha }} \
            -n production
          
          kubectl set image deployment/backend \
            backend=ghcr.io/${{ github.repository }}/backend:${{ github.sha }} \
            -n production
```

---

## Database Management

### Migration Strategy

**Tools:**
- **Prisma**: Modern ORM with migrations
- **Flyway**: Java-based (supports any SQL)
- **Liquibase**: XML/YAML-based
- **Knex.js**: JavaScript migrations

**Prisma Example:**
```bash
# Create migration
npx prisma migrate dev --name add_user_table

# Apply to production
npx prisma migrate deploy
```

**Migration File:**
```sql
-- migrations/001_add_user_table.sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

### Zero-Downtime Migrations

**Pattern: Expand-Migrate-Contract**

**Step 1: Expand (Add new column):**
```sql
ALTER TABLE users ADD COLUMN name VARCHAR(255);
```

**Step 2: Dual-write (App writes to both):**
```javascript
// Deploy this BEFORE removing old column
await db.users.update({
  username: 'john',    // Old column
  name: 'john'         // New column
});
```

**Step 3: Backfill data:**
```sql
UPDATE users SET name = username WHERE name IS NULL;
```

**Step 4: Contract (Remove old column):**
```sql
ALTER TABLE users DROP COLUMN username;
```

---

## Testing Strategy

### Test Pyramid for Fullstack

```
           /\         E2E (5%)
          /  \        Full user flows
         /────\       
        /      \      Integration (15%)
       / ────── \     API + DB tests
      /          \    
     / ────────── \   Unit (80%)
    /              \  Component + function tests
   /────────────────\
```

### Test Examples

**Frontend Unit (React):**
```javascript
import { render, screen } from '@testing-library/react';
import UserProfile from './UserProfile';

test('renders user profile', () => {
  const user = { name: 'John', email: 'john@example.com' };
  render(<UserProfile user={user} />);
  
  expect(screen.getByText('John')).toBeInTheDocument();
  expect(screen.getByText('john@example.com')).toBeInTheDocument();
});
```

**Backend Integration:**
```javascript
import request from 'supertest';
import app from './app';
import { setupTestDB, teardownTestDB } from './test-utils';

beforeAll(() => setupTestDB());
afterAll(() => teardownTestDB());

describe('POST /api/users', () => {
  it('creates a new user', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ email: 'test@example.com', name: 'Test User' });
    
    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      email: 'test@example.com',
      name: 'Test User'
    });
  });
});
```

**E2E (Playwright):**
```javascript
import { test, expect } from '@playwright/test';

test('user registration and login flow', async ({ page }) => {
  // Register
  await page.goto('https://myapp.com/register');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'SecurePass123');
  await page.click('button[type="submit"]');
  
  // Verify redirect
  await expect(page).toHaveURL(/.*dashboard/);
  
  // Logout
  await page.click('[data-testid="logout"]');
  
  // Login
  await page.goto('https://myapp.com/login');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'SecurePass123');
  await page.click('button[type="submit"]');
  
  await expect(page).toHaveURL(/.*dashboard/);
});
```

---

## Deployment Patterns

### Feature Flags

```typescript
// feature-flags.ts
export const features = {
  newCheckout: process.env.FEATURE_NEW_CHECKOUT === 'true',
  darkMode: true,
  betaFeatures: (userId: string) => 
    betaUsers.includes(userId)
};

// Usage in frontend
function CheckoutPage() {
  if (features.newCheckout) {
    return <NewCheckout />;
  }
  return <LegacyCheckout />;
}

// Usage in backend
app.post('/api/orders', async (req, res) => {
  if (features.newCheckout) {
    return await newOrderProcessor.process(req.body);
  }
  return await legacyOrderProcessor.process(req.body);
});
```

### Blue-Green for Fullstack

```
Blue (v1):
  Frontend v1 → Backend v1 → DB
  
Green (v2):
  Frontend v2 → Backend v2 → DB (shared!)
  
Switch:
  Route 100% traffic to Green
  
Keep Blue for 24h, then destroy
```

**Database Compatibility:**
```
Backend v1 and v2 must work with same DB schema!
Use expand-migrate-contract pattern
```

---

## Summary

**Key Takeaways:**

✅ **Monorepo** for code sharing, **multi-repo** for autonomy
✅ **Environment management** with ConfigMaps/Secrets
✅ **End-to-end CI/CD** covers frontend, backend, E2E
✅ **Zero-downtime migrations** with expand-migrate-contract
✅ **Test pyramid**: 80% unit, 15% integration, 5% E2E
✅ **Feature flags** for progressive rollouts
✅ **Blue-green** requires DB compatibility

**Next Steps:**
- **Related**: [24-DevOps-Frontend.md](./24-DevOps-Frontend.md)
- **Related**: [25-DevOps-Backend.md](./25-DevOps-Backend.md)

---

*Remember: DevOps for fullstack means coordinating multiple moving parts!*
