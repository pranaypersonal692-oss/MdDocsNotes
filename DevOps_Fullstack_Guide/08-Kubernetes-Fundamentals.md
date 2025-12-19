# Kubernetes Fundamentals

## Table of Contents
1. [Introduction to Kubernetes](#introduction-to-kubernetes)
2. [Kubernetes Architecture](#kubernetes-architecture)
3. [Installing Kubernetes](#installing-kubernetes)
4. [Core Concepts](#core-concepts)
5. [Pods](#pods)
6. [Deployments](#deployments)
7. [Services](#services)
8. [ConfigMaps and Secrets](#configmaps-and-secrets)
9. [Persistent Volumes](#persistent-volumes)
10. [Namespaces](#namespaces)
11. [kubectl Commands](#kubectl-commands)

---

## Introduction to Kubernetes

### What is Kubernetes?

**Kubernetes (K8s)** is an open-source container orchestration platform that automates deployment, scaling, and management of containerized applications.

**Created by:** Google (donated to CNCF in 2014)
**Name Origin:** Greek for "helmsman" or "pilot"
**K8s:** 8 letters between K and s

---

### Why Kubernetes?

**Without Kubernetes:**
```
You manually:
- Deploy containers on servers
- Monitor container health
- Replace failed containers
- Scale up/down manually
- Load balance traffic
- Rolling updates (carefully!)
```

**With Kubernetes:**
```
You declare desired state:
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3

Kubernetes ensures:
✅ Always 3 replicas running
✅ Auto-restarts failed pods
✅ Auto-distributes across nodes
✅ Auto-load balances traffic
✅ Rolling updates with zero downtime
```

---

### Key Benefits

**1. Self-Healing:**
```
Pod crashes → K8s automatically restarts it
Node fails → K8s reschedules pods to healthy nodes
```

**2. Automated Scaling:**
```
High traffic → Auto-scale pods from 3 to 10
Low traffic → Scale down from 10 to 3
```

**3. Automated Rollouts and Rollbacks:**
```
Deploy new version → Rolling update (no downtime)
Version has bugs → Automatic rollback
```

**4. Service Discovery and Load Balancing:**
```
DNS-based service discovery
Automatic load balancing
```

**5. Secret and Configuration Management:**
```
Secure secret storage
Environment-specific configurations
```

---

## Kubernetes Architecture

### Cluster Components

```
┌─────────────────────────────────────────────────────────┐
│                    CONTROL PLANE                        │
│  ┌───────────────┐  ┌──────────┐  ┌─────────────────┐  │
│  │  API Server   │  │  etcd    │  │   Scheduler     │  │
│  │  (kube-api)   │  │  (DB)    │  │ (Pod placement) │  │
│  └───────────────┘  └──────────┘  └─────────────────┘  │
│  ┌────────────────────────────────────────────────────┐ │
│  │    Controller Manager                              │ │
│  │    (Maintains desired state)                       │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌───────▼──────┐
│   Worker     │  │   Worker     │  │   Worker     │
│   Node 1     │  │   Node 2     │  │   Node 3     │
├──────────────┤  ├──────────────┤  ├──────────────┤
│  kubelet     │  │  kubelet     │  │  kubelet     │
│  kube-proxy  │  │  kube-proxy  │  │  kube-proxy  │
│  Container   │  │  Container   │  │  Container   │
│  Runtime     │  │  Runtime     │  │  Runtime     │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ ┌──┐ ┌──┐   │  │ ┌──┐ ┌──┐   │  │ ┌──┐ ┌──┐   │
│ │P1│ │P2│   │  │ │P3│ │P4│   │  │ │P5│ │P6│   │
│ └──┘ └──┘   │  │ └──┘ └──┘   │  │ └──┘ └──┘   │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

### Control Plane Components

**1. API Server (kube-apiserver):**
- Frontend for Kubernetes control plane
- RESTful API
- All communication goes through it

**2. etcd:**
- Distributed key-value store
- Stores cluster state
- Critical for cluster operation

**3. Scheduler (kube-scheduler):**
- Assigns pods to nodes
- Considers resource requirements, constraints
- Optimizes for even distribution

**4. Controller Manager (kube-controller-manager):**
- Node Controller: Monitors node health
- Replication Controller: Maintains correct number of pods
- Endpoints Controller: Populates endpoints
- Service Account Controller: Creates default accounts

**5. Cloud Controller Manager:**
- Interacts with cloud provider APIs
- Manages load balancers, storage, networking

---

### Node Components

**1. kubelet:**
- Agent running on each node
- Ensures containers are running in pods
- Reports node status to control plane

**2. kube-proxy:**
- Network proxy on each node
- Maintains network rules
- Enables service communication

**3. Container Runtime:**
- Runs containers (Docker, containerd, CRI-O)
- Pulls images
- Starts/stops containers

---

## Installing Kubernetes

### Local Development

**1. Minikube:**
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start

# Check status
minikube status
```

**2. Docker Desktop:**
```
Settings → Kubernetes → Enable Kubernetes
```

**3. kind (Kubernetes IN Docker):**
```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster

# Create multi-node cluster
kind create cluster --config=kind-config.yaml
```

---

### Production

**Managed Kubernetes:**
- **AWS:** EKS (Elastic Kubernetes Service)
- **Azure:** AKS (Azure Kubernetes Service)
- **GCP:** GKE (Google Kubernetes Engine)
- **DigitalOcean:** DOKS

**Self-Managed:**
- **kubeadm:** Official tool
- **kops:** Production-grade clusters on AWS
- **Kubespray:** Ansible-based

---

### kubectl Installation

```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# macOS (Homebrew)
brew install kubectl

# Windows (Chocolatey)
choco install kubernetes-cli

# Verify
kubectl version --client
```

---

## Core Concepts

### Declarative vs Imperative

**Imperative (Tell HOW):**
```bash
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=3
kubectl expose deployment nginx --port=80
```

**Declarative (Tell WHAT):**
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply -f deployment.yaml
```

**Best Practice:** Use declarative (YAML files in version control)

---

### labels and Selectors

**Labels:** Key-value pairs attached to objects
```yaml
metadata:
  labels:
    app: nginx
    environment: production
    tier: frontend
```

**Selectors:** Query labels
```bash
# Select by label
kubectl get pods -l app=nginx

# Multiple labels
kubectl get pods -l app=nginx,environment=production
```

---

## Pods

### What is a Pod?

**Pod** = Smallest deployable unit in Kubernetes
- Can contain one or more containers
- Shares network and storage
- Co-located, co-scheduled

```
┌────────────────────────────┐
│          Pod               │
│  ┌──────────┐ ┌──────────┐│
│  │Container │ │Container ││
│  │   App    │ │  Sidecar ││
│  └──────────┘ └──────────┘│
│  Shared Network (localhost)│
│  Shared Volumes            │
└────────────────────────────┘
```

---

### Pod Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0.0
    ports:
    - containerPort: 8080
    env:
    - name: DATABASE_URL
      value: "postgresql://db:5432/mydb"
    resources:
      requests:
        memory: "128Mi"
        cpu: "250m"
      limits:
        memory: "256Mi"
        cpu: "500m"
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

### Pod Lifecycle

```
Pending → Running → Succeeded/Failed
           ↓
       Terminating
```

**States:**
- **Pending:** Accepted but not running yet
- **Running:** Pod bound to node, containers created
- **Succeeded:** All containers terminated successfully
- **Failed:** At least one container failed
- **Unknown:** Cannot determine state

---

### Pod Commands

```bash
# Create pod
kubectl apply -f pod.yaml

# List pods
kubectl get pods

# Detailed pod info
kubectl describe pod myapp-pod

# Watch pods
kubectl get pods -w

# Pod logs
kubectl logs myapp-pod

# Follow logs
kubectl logs -f myapp-pod

# Multi-container pod logs
kubectl logs myapp-pod -c container-name

# Execute command
kubectl exec myapp-pod -- ls /app

# Interactive shell
kubectl exec -it myapp-pod -- /bin/bash

# Delete pod
kubectl delete pod myapp-pod
```

---

## Deployments

### What is a Deployment?

**Deployment** manages a ReplicaSet, which manages Pods.

```
Deployment
    │
    ├── ReplicaSet v1
    │      ├── Pod 1
    │      ├── Pod 2
    │      └── Pod 3
    │
    └── ReplicaSet v2 (after update)
           ├── Pod 4
           ├── Pod 5
           └── Pod 6
```

**Benefits:**
- Declarative updates
- Rolling updates
- Rollbacks
- Scaling
- Self-healing

---

### Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: myapp
        version: v1.0.0
    spec:
      containers:
      - name: myapp
        image: myapp:1.0.0
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
          value: production
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

---

### Deployment Operations

**Create/Update:**
```bash
kubectl apply -f deployment.yaml
```

**Scale:**
```bash
# Scale to 5 replicas
kubectl scale deployment myapp --replicas=5

# Auto-scale
kubectl autoscale deployment myapp --min=3 --max=10 --cpu-percent=70
```

**Update Image:**
```bash
kubectl set image deployment/myapp myapp=myapp:2.0.0

# Record change
kubectl set image deployment/myapp myapp=myapp:2.0.0 --record
```

**Rollout Status:**
```bash
kubectl rollout status deployment/myapp
```

**Rollback:**
```bash
# Rollback to previous version
kubectl rollout undo deployment/myapp

# Rollback to specific revision
kubectl rollout undo deployment/myapp --to-revision=2
```

**Rollout History:**
```bash
kubectl rollout history deployment/myapp
```

---

### Rolling Update Strategy

```
Initial State: [V1] [V1] [V1] [V1]

Step 1: [V2] [V1] [V1] [V1]
        ↓ healthy ✓

Step 2: [V2] [V2] [V1] [V1]
              ↓ healthy ✓

Step 3: [V2] [V2] [V2] [V1]
                    ↓ healthy ✓

Step 4: [V2] [V2] [V2] [V2] ✓

Zero downtime!
```

---

## Services

### What is a Service?

**Service** provides stable networking for pods.

**Problem:**
```
Pods are ephemeral:
Pod 1: 10.1.1.1 → Dies
Pod 2: 10.1.1.5 → Created (different IP!)

How to connect reliably?
```

**Solution:**
```
Service: myapp-service (stable endpoint)
   ↓
Load balances to:
   → Pod 1 (10.1.1.1)
   → Pod 2 (10.1.1.2)
   → Pod 3 (10.1.1.3)
```

---

### Service Types

**1. ClusterIP (Default):**
```yaml
type: ClusterIP
# Internal cluster IP
# Only accessible within cluster
```

**2. NodePort:**
```yaml
type: NodePort
# Exposes service on each node's IP at a static port
# Accessible from outside: <NodeIP>:<NodePort>
```

**3. LoadBalancer:**
```yaml
type: LoadBalancer
# Creates external load balancer (cloud provider)
# Accessible via external IP
```

**4. ExternalName:**
```yaml
type: ExternalName
# Maps service to DNS name
# Example: database.example.com
```

---

### Service Examples

**ClusterIP (Internal):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80        # Service port
    targetPort: 8080  # Container port
```

**NodePort (External):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-nodeport
spec:
  type: NodePort
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
    nodePort: 30080  # 30000-32767
```

**LoadBalancer (Cloud):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-lb
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

---

### Service Discovery

**DNS-Based:**
```javascript
// Pods in same namespace
fetch('http://myapp-service')

// Pods in different namespace
fetch('http://myapp-service.production.svc.cluster.local')

// Full DNS format:
// <service-name>.<namespace>.svc.cluster.local
```

---

## ConfigMaps and Secrets

### ConfigMaps

**Store non-sensitive configuration:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.properties: |
    server.port=8080
    log.level=info
  database.host: postgres.default.svc.cluster.local
  cache.ttl: "3600"
```

**Use in Pod:**
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    envFrom:
    - configMapRef:
        name: app-config
    # Or specific keys
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.host
    # Or mount as file
    volumeMounts:
    - name: config
      mountPath: /config
  volumes:
  - name: config
    configMap:
      name: app-config
```

---

### Secrets

**Store sensitive data (base64 encoded):**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  db-password: cGFzc3dvcmQxMjM=  # base64 encoded
  api-key: YXBpLWtleS14eXo=
```

**Create secret:**
```bash
# From literal
kubectl create secret generic app-secrets \
  --from-literal=db-password=password123 \
  --from-literal=api-key=api-key-xyz

# From file
kubectl create secret generic app-secrets \
  --from-file=db-password=./password.txt
```

**Use in Pod:**
```yaml
spec:
  containers:
  - name: app
    image:app:latest
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: db-password
    # Or mount as file
    volumeMounts:
    - name: secrets
      mountPath: /secrets
      readOnly: true
  volumes:
  - name: secrets
    secret:
      secretName: app-secrets
```

---

## Persistent Volumes

### Storage Hierarchy

```
PersistentVolume (PV)     ← Cluster resource
        ↑
    (binds to)
        ↓
PersistentVolumeClaim (PVC)  ← Namespace resource
        ↑
    (mounts)
        ↓
       Pod
```

---

### PersistentVolume

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data
```

---

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

---

### Using PVC in Pod

```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-data
```

---

## Namespaces

### What are Namespaces?

**Logical partitions** of a cluster.

```
Cluster
├── Namespace: default
│   ├── Deployment: app-a
│   └── Service: service-a
├── Namespace: production
│   ├── Deployment: app-prod
│   └── Service: service-prod
└── Namespace: development
    ├── Deployment: app-dev
    └── Service: service-dev
```

---

### Create Namespace

```bash
# Imperative
kubectl create namespace production

# Declarative
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: production
EOF
```

---

### Use Namespace

```bash
# Deploy to namespace
kubectl apply -f deployment.yaml -n production

# List resources in namespace
kubectl get pods -n production

# Set default namespace
kubectl config set-context --current --namespace=production

# All namespaces
kubectl get pods --all-namespaces
# or
kubectl get pods -A
```

---

## kubectl Commands

### Essential Commands

**Cluster Info:**
```bash
kubectl cluster-info
kubectl get nodes
kubectl describe node node-name
```

**Get Resources:**
```bash
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get all  # All resources

# With labels
kubectl get pods -l app=myapp

# Wide output
kubectl get pods -o wide

# YAML output
kubectl get deployment myapp -o yaml

# JSON output
kubectl get pods -o json
```

**Describe Resources:**
```bash
kubectl describe pod myapp-pod
kubectl describe deployment myapp
kubectl describe service myapp-service
```

**Create/Apply:**
```bash
kubectl create -f resource.yaml
kubectl apply -f resource.yaml
kubectl apply -f directory/
```

**Edit:**
```bash
kubectl edit deployment myapp
```

**Delete:**
```bash
kubectl delete pod myapp-pod
kubectl delete -f deployment.yaml
kubectl delete deployment myapp
```

**Logs:**
```bash
kubectl logs pod-name
kubectl logs -f pod-name  # Follow
kubectl logs pod-name -c container-name  # Multi-container
kubectl logs --tail=100 pod-name  # Last 100 lines
```

**Execute:**
```bash
kubectl exec pod-name -- command
kubectl exec -it pod-name -- /bin/bash
```

**Port Forward:**
```bash
kubectl port-forward pod/myapp-pod 8080:80
kubectl port-forward service/myapp-service 8080:80
```

**Copy Files:**
```bash
# To pod
kubectl cp ./local-file pod-name:/path/in/pod

# From pod
kubectl cp pod-name:/path/in/pod ./local-file
```

---

## Summary

**Key Takeaways:**

✅ Kubernetes **orchestrates containers** at scale
✅ **Pods** are the smallest deployable units
✅ **Deployments** manage pod replicas and updates
✅ **Services** provide stable networking
✅ **ConfigMaps/Secrets** manage configuration
✅ **PersistentVolumes** provide storage
✅ **Namespaces** organize resources
✅ Use **declarative** configuration (YAML)

**Next Steps:**
- **Next**: [09-Kubernetes-Advanced.md](./09-Kubernetes-Advanced.md) - Advanced K8s topics
- **Related**: [10-Terraform.md](./10-Terraform.md) - Infrastructure as Code

---

*Remember: Kubernetes is like a self-driving car for your applications!*
