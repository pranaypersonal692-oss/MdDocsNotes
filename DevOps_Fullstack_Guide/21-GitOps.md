# GitOps

## Table of Contents
1. [What is GitOps](#what-is-gitops)
2. [GitOps Principles](#gitops-principles)
3. [GitOps vs Traditional](#gitops-vs-traditional)
4. [ArgoCD](#argocd)
5. [Flux](#flux)
6. [GitOps Workflows](#gitops-workflows)  
7. [Best Practices](#best-practices)

---

## What is GitOps

**GitOps** is a paradigm where Git is the single source of truth for declarative infrastructure and applications.

**Core Concept:**
```
Git Repository → Automated Deployment → Kubernetes Cluster
     ↓                    ↓                      ↓
   Code/Config        ArgoCD/Flux         Desired State
```

**Traditional CI/CD:**
```
Push code → CI builds → CI pushes to K8s → Deployed!
(CI has cluster access - security risk!)
```

**GitOps:**
```
Push code → Git updated → GitOps agent pulls → Deployed!
(Agent inside cluster - more secure!)
```

---

## GitOps Principles

### The Four Principles

**1. Declarative:**
```yaml
# Everything defined declaratively
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  # ...
```

**2. Versioned and Immutable:**
```
Git commits = immutable history
main@abc123 = production
main@def456 = rollback point
```

**3. Pulled Automatically:**
```
GitOps Agent polls Git every 3 minutes
Changes detected → Automatically synced to cluster
```

**4. Continuously Reconciled:**
```
Desired State (Git) ≠ Actual State (Cluster)
       ↓
GitOps Agent fixes drift automatically
```

---

## GitOps vs Traditional

| Aspect | Traditional CI/CD | GitOps |
|--------|------------------|---------|
| **Deployment** | CI pushes to cluster | GitOps agent pulls from Git |
| **Credentials** | CI has cluster access | Agent inside cluster only |
| **Rollback** | Redeploy previous version | Git revert |
| **Audit** | CI logs | Git history |
| **Drift Detection** | Manual | Automatic |

---

## ArgoCD

### Installation

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Application Definition

```yaml
# application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/myorg/myapp
    targetRevision: main
    path: k8s
    
  destination:
    server: https://kubernetes.default.svc
    namespace: production
    
  syncPolicy:
    automated:
      prune: true      # Delete resources not in Git
      selfHeal: true   # Fix manual changes
    syncOptions:
      - CreateNamespace=true
```

```bash
# Apply application
kubectl apply -f application.yaml

# Check sync status
argocd app get myapp

# Manual sync
argocd app sync myapp
```

---

## Flux

### Installation

```bash
# Install Flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# Bootstrap Flux
flux bootstrap github \
  --owner=myorg \
  --repository=fleet-infra \
  --branch=main \
  --path=clusters/production \
  --personal
```

### GitRepository

```yaml
# source/git-repo.yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/myorg/myapp
  ref:
    branch: main
```

### Kustomization

```yaml
# kustomization.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp
  namespace: flux-system
spec:
  interval: 5m
  path: ./k8s
  prune: true
  source:
    kind: GitRepository
    name: myapp
  validation: client
```

---

## GitOps Workflows

### Environment Promotion

```
Repository Structure:
myapp-gitops/
├── base/
│   ├── deployment.yaml
│   └── service.yaml
├── overlays/
│   ├── dev/
│   │   └── kustomization.yaml
│   ├── staging/
│   │   └── kustomization.yaml
│   └── prod/
│       └── kustomization.yaml
```

**Promotion Flow:**
```
1. Merge to main → Deploy to dev (automatic)
2. Tag v1.2.3 → Deploy to staging (automatic)
3. Manual approval → Update prod overlay → Deploy to prod
```

### Multi-Cluster

```yaml
# ArgoCD ApplicationSet
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: myapp
spec:
  generators:
  - clusters: {}  # All  registered clusters
  
  template:
    metadata:
      name: '{{name}}-myapp'
    spec:
      source:
        repoURL: https://github.com/myorg/myapp
        path: 'k8s/{{name}}'
      destination:
        server: '{{server}}'
        namespace: production
```

---

## Best Practices

### 1. **Separate App and Config Repos**

```
myapp/ (application code)
└── .github/workflows/ci.yml
    ↓ (builds image)
    ↓
myapp-gitops/ (K8s manifests)
└── k8s/deployment.yaml (image: myapp:v1.2.3)
    ↓ (ArgoCD syncs)
    ↓
Kubernetes Cluster
```

### 2. **Use Kustomize or Helm**

```
# Kustomize overlay
base/
└── deployment.yaml (replicas: 2)

overlays/prod/
└── kustomization.yaml
    patches:
    - replicas: 10
```

### 3. **Encrypt Secrets**

```bash
# Sealed Secrets
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# Commit sealed-secret.yaml to Git ✓
# Only cluster can decrypt
```

### 4. **Auto-Sync with Manual Approval for Prod**

```yaml
syncPolicy:
  automated: {}  # dev/staging

# Production (manual)
syncPolicy:
  syncOptions:
    - CreateNamespace=true
  # No automated sync
```

---

## Summary

**Key Takeaways:**

✅ Git is the **single source of truth**
✅ **Pull-based** deployment is more secure
✅ **Automatic drift detection** and correction
✅ **Git history** = deployment audit trail
✅ ArgoCD and Flux are popular tools
✅ Use **environment overlays** for promotion

**Next Steps:**
- **Related**: [08-Kubernetes-Fundamentals.md](./08-Kubernetes-Fundamentals.md)
- **Related**: [10-Terraform.md](./10-Terraform.md)

---

*Remember: If it's not in Git, it doesn't exist!*
