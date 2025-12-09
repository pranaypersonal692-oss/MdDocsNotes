# Part 6: Container Security & Best Practices

## Security Principles

### 1. Never Run as Root

```dockerfile
# ✅ Create non-root user
FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
USER nodejs
WORKDIR /home/nodejs/app
COPY --chown=nodejs:nodejs . .
CMD ["node", "app.js"]
```

### 2. Use Minimal Base Images

```
Security surface area:
debian:latest      (129MB, many packages)  ❌
alpine:latest      (5MB, minimal packages) ✅
distroless/nodejs  (No shell, no package manager) ✅✅
```

### 3. Scan for Vulnerabilities

```bash
# Trivy
trivy image myapp:latest

# Docker Scout
docker scout cve myapp:latest

# Snyk
snyk container test myapp:latest
```

### 4. Sign and Verify Images

```bash
# Enable Content Trust
export DOCKER_CONTENT_TRUST=1

# Push signed image
docker push myregistry.io/myapp:1.0

# Verify signature on pull
docker pull myregistry.io/myapp:1.0
```

### 5. Use Secrets Properly

```yaml
# ❌ WRONG - Secret in environment variable
environment:
  DB_PASSWORD: supersecret123  # Visible in inspect!

# ✅ RIGHT - Use Kubernetes secrets
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

### 6. Network Policies

```yaml
# Restrict pod communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend  # Only frontend can reach API
    ports:
    - protocol: TCP
      port: 3000
```

### 7. Read-Only Filesystem

```yaml
securityContext:
  readOnlyRootFilesystem: true  # Prevent file modifications
  runAsNonRoot: true
  runAsUser: 1001
  capabilities:
    drop:
    - ALL  # Drop all Linux capabilities
```

---

## Key Takeaways

> [!IMPORTANT]
> **Security Checklist:**
> - [ ] Use non-root user
> - [ ] Minimal base images (Alpine/Distroless)
> - [ ] Scan images for vulnerabilities
> - [ ] Sign images (Content Trust)
> - [ ] Use secrets management
> - [ ] Set security contexts
> - [ ] Network policies
> - [ ] Read-only filesystem where possible
> - [ ] Resource limits
> - [ ] No secrets in Dockerfile

---

**Continue to:** [Part 7: Real-World Case Studies](file:///C:/Users/phusukale/Downloads/Docs/Repo/Docker_Guide/Part7-Real-World-Case-Studies.md)
