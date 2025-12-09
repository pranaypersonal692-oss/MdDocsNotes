# Part 5: Production Deployment & Scaling Strategies

## Table of Contents
1 [Production Readiness Checklist](#production-readiness-checklist)
2. [Resource Management](#resource-management)
3. [High Availability Patterns](#high-availability-patterns)
4. [CI/CD with Docker](#cicd-with-docker)
5. [Monitoring and Logging](#monitoring-and-logging)
6. [Performance Optimization](#performance-optimization)

---

## Production Readiness Checklist

```
✅ Non-root user in containers
✅ Health checks configured
✅ Resource limits set (CPU, memory)
✅ Secrets management
✅ Image scanning for vulnerabilities
✅ Multi-replica deployment
✅ Rolling update strategy
✅ Logging configured
✅ Monitoring and alerting
✅ Backup and disaster recovery
```

---

## Resource Management

### Setting Resource Requests and Limits

```yaml
# Kubernetes
spec:
  containers:
  - name: app
    image: myapp:latest
    resources:
      requests:        # Minimum guaranteed
        memory: "256Mi"
        cpu: "250m"    # 0.25 CPU core
      limits:          # Maximum allowed
        memory: "512Mi"
        cpu: "500m"    # 0.5 CPU core
```

**What happens:**
- **Request**: Pod scheduled on node with available resources
- **Limit**: Container killed (OOMKilled) if exceeds memory limit
- **No limit**: Can consume all node resources (bad!)

### Docker Resource Limits

```bash
# Limit memory and CPU
docker run -d \
  --memory="512m" \
  --cpus="0.5" \
  myapp:latest

# Docker Compose
services:
  app:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

---

## High Availability Patterns

### Multi-Replica Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3  # Minimum for HA
  
  # Spread across nodes
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - api
          topologyKey: kubernetes.io/hostname
```

### Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  minAvailable: 2  # Always keep 2 pods running
  selector:
    matchLabels:
      app: api
```

**Protects from:**
- Node drains
- Cluster updates
- Voluntary disruptions

---

## CI/CD with Docker

### GitHub Actions Pipeline

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Build Docker image
      - name: Build image
        run: |
          docker build -t myapp:${{ github.sha }} .
      
      # Run tests in container
      - name: Run tests
        run: |
          docker run myapp:${{ github.sha }} npm test
      
      # Security scan
      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          severity: 'CRITICAL,HIGH'
      
      # Push to registry
      - name: Log in to registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Push image
        run: |
          docker tag myapp:${{ github.sha }} ghcr.io/myorg/myapp:${{ github.sha }}
          docker push ghcr.io/myorg/myapp:${{ github.sha }}
      
      # Deploy to Kubernetes
      - name: Deploy
        run: |
          kubectl set image deployment/api api=ghcr.io/myorg/myapp:${{ github.sha }}
```

### Multi-Stage Build for CI/CD

```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN npm run test  # Tests run during build!

# Production stage
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
CMD ["node", "dist/index.js"]
```

---

## Monitoring and Logging

### Prometheus Metrics

```javascript
// Export metrics from your app
const client = require('prom-client');
client.collectDefaultMetrics();

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

// Expose /metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});
```

### Structured Logging

```javascript
// Use structured JSON logs
const winston = require('winston');

const logger = winston.createLogger({
  format: winston.format.json(),
  transports: [new winston.transports.Console()]
});

logger.info('User logged in', {
  userId: 12345,
  ip: req.ip,
  timestamp: new Date().toISOString()
});
```

### Kubernetes Logging

```bash
# View logs
kubectl logs -f deployment/api

# View logs from all pods
kubectl logs -f -l app=api

# Previous container logs (after crash)
kubectl logs api-pod-abc123 --previous
```

---

## Performance Optimization

### Image Size Optimization

```dockerfile
# ❌ Large image (1.2GB)
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "app.js"]

# ✅ Optimized (180MB)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app .
USER node
CMD ["node", "app.js"]
```

### Layer Caching Strategy

```dockerfile
# Copy files in order of change frequency
FROM node:18-alpine

# Least frequent (package.json)
COPY package*.json ./
RUN npm ci

# Most frequent (source code)
COPY . .
CMD ["npm", "start"]
```

### Use BuildKit

```bash
# Enable BuildKit for faster builds
export DOCKER_BUILDKIT=1

# Parallel builds, better caching
docker build -t myapp:latest .
```

---

## Key Takeaways

> [!IMPORTANT]
> **Production Best Practices:**
> 1. Always set **resource limits** (prevent noisy neighbor)
> 2. Run **3+ replicas** for high availability
> 3. Configure **health checks** (liveness + readiness)
> 4. Use **Pod Disruption Budgets** for critical services
> 5. Implement **CI/CD pipelines** with automated testing
> 6. Enable **monitoring** (Prometheus) and **logging** (structured JSON)
> 7. **Scan images** for vulnerabilities before deployment
> 8. Use **rolling updates** with proper strategy
> 9. Test **rollback procedures** regularly
> 10. Optimize **image sizes** for faster deployments

---

**Continue to:** [Part 6: Container Security](file:///C:/Users/phusukale/Downloads/Docs/Repo/Docker_Guide/Part6-Security-Best-Practices.md)
