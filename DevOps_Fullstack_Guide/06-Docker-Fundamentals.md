# Docker Fundamentals

## Table of Contents
1. [Introduction to Containers](#introduction-to-containers)
2. [Docker Architecture](#docker-architecture)
3. [Installing Docker](#installing-docker)
4. [Docker Images](#docker-images)
5. [Docker Containers](#docker-containers)
6. [Dockerfile Best Practices](#dockerfile-best-practices)
7. [Docker Volumes](#docker-volumes)
8. [Docker Networking](#docker-networking)
9. [Docker Compose](#docker-compose)
10. [Multi-Stage Builds](#multi-stage-builds)
11. [Docker Security](#docker-security)

---

## Introduction to Containers

### What are Containers?

**Containers** are lightweight, standalone, executable packages that include everything needed to run an application: code, runtime, system tools, libraries, and settings.

### Containers vs. Virtual Machines

```
Virtual Machines:                    Containers:

┌─────────────────────┐             ┌──────────────────────┐
│   App A   │  App B  │             │ App A │ App B │ App C│
├───────────┼─────────┤             ├──────┴──────┴────────┤
│  Guest OS │ Guest OS│             │   Container Runtime  │
├───────────┴─────────┤             │      (Docker)        │
│    Hypervisor       │             ├──────────────────────┤
├─────────────────────┤             │     Host OS          │
│      Host OS        │             ├──────────────────────┤
└─────────────────────┘             │   Infrastructure     │
                                    └──────────────────────┘

Size: GBs                           Size: MBs
Boot: Minutes                       Boot: Seconds
Isolation: Strong                   Isolation: Process-level
```

**Key Differences:**

| Aspect | Virtual Machines | Containers |
|--------|-----------------|------------|
| **Size** | Gigabytes | Megabytes |
| **Startup Time** | Minutes | Seconds |
| **Resource Usage** | Heavy | Lightweight |
| **Isolation** | Complete | Process-level |
| **OS** | Full OS | Shared kernel |
| **Portability** | Limited | Highly portable |

---

### Benefits of Containers

**1. Consistency:**
```
"It works on my machine!" → Problem solved
   Developer         Shipping          Production
 ┌──────────┐     ┌──────────┐     ┌──────────┐
 │Container │  →  │Container │  →  │Container │
 └──────────┘     └──────────┘     └──────────┘
   (Same)           (Same)           (Same)
```

**2. Isolation:**
- Each container runs in its own isolated environment
- No dependency conflicts
- Predictable behavior

**3. Portability:**
```
Build once, run anywhere:
- Local laptop
- Cloud (AWS, Azure, GCP)
- On-premises servers
- Developer machines
```

**4. Efficiency:**
- Share OS kernel
- Fast startup
- Lower resource consumption

**5. Scalability:**
```
1 container → 10 containers → 100 containers
(in seconds, not minutes)
```

---

## Docker Architecture

### Docker Components

```
┌────────────────────────────────────────────┐
│           Docker Client (CLI)              │
│        docker build, run, push, etc.       │
└───────────────┬────────────────────────────┘
                │ Docker API (REST)
┌───────────────▼────────────────────────────┐
│           Docker Daemon (dockerd)          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │Container │  │Container │  │Container │ │
│  └──────────┘  └──────────┘  └──────────┘ │
│  ┌──────────────────────────────────────┐ │
│  │          Images                      │ │
│  └──────────────────────────────────────┘ │
└────────────────────────────────────────────┘
                │
┌───────────────▼────────────────────────────┐
│        Docker Registry (Docker Hub)        │
│     Public/Private image repositories      │
└────────────────────────────────────────────┘
```

### Key Components

**1. Docker Client:**
- Command-line tool
- Sends commands to Docker daemon
- Can connect to remote daemons

**2. Docker Daemon (dockerd):**
- Background service
- Manages containers, images, networks, volumes
- Listens to Docker API requests

**3. Docker Images:**
- Read-only templates
- Contains application code and dependencies
- Built from Dockerfiles

**4. Docker Containers:**
- Runnable instances of images
- Isolated processes
- Can be started, stopped, moved, deleted

**5. Docker Registry:**
- Stores Docker images
- Docker Hub (public)
- Private registries (AWS ECR, Azure ACR, etc.)

---

## Installing Docker

### Windows

**Docker Desktop:**
```powershell
# Using winget
winget install Docker.DockerDesktop

# Or download from docker.com
```

**WSL2 Requirements:**
```powershell
# Install WSL2
wsl --install

# Set WSL2 as default
wsl --set-default-version 2
```

---

### macOS

```bash
# Using Homebrew
brew install --cask docker

# Or download Docker Desktop from docker.com
```

---

### Linux (Ubuntu/Debian)

```bash
# Update package index
sudo apt update

# Install prerequisites
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group (avoid using sudo)
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker
```

---

### Verify Installation

```bash
# Check Docker version
docker --version
# Output: Docker version 24.0.0, build abc123

# Run hello-world container
docker run hello-world

# Check Docker info
docker info
```

---

## Docker Images

### What are Docker Images?

**Docker images** are read-only templates containing:
- Application code
- Runtime environment
- Libraries
- Dependencies
- Configuration files

### Image Layers

Images are built in layers (like a cake):
```
┌─────────────────────┐ ← Your App (50 MB)
├─────────────────────┤
│ Dependencies (Node)  │ (100 MB)
├─────────────────────┤
│    Base OS (Ubuntu) │ (80 MB)
└─────────────────────┘

Total: 230 MB
But layers are cached and reused!
```

---

### Working with Images

**Pull an Image:**
```bash
# Pull from Docker Hub
docker pull node:18

# Pull specific tag
docker pull nginx:1.25-alpine

# Pull from private registry
docker pull myregistry.com/myapp:latest
```

**List Images:**
```bash
docker images

# Output:
# REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
# node          18        abc123def456   2 days ago     918MB
# nginx         alpine    789ghi012jkl   1 week ago     23.5MB
```

**Remove Images:**
```bash
# Remove specific image
docker rmi node:18

# Remove by ID
docker rmi abc123def456

# Remove all unused images
docker image prune -a
```

**Inspect Image:**
```bash
docker inspect node:18

# View image history (layers)
docker history node:18
```

---

### Creating Images with Dockerfile

**Simple Dockerfile (Node.js App):**
```dockerfile
# Use official Node.js runtime as base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Define environment variable
ENV NODE_ENV=production

# Run application
CMD ["node", "index.js"]
```

**Build Image:**
```bash
# Build image
docker build -t myapp:1.0.0 .

# Build with build args
docker build --build-arg VERSION=1.0.0 -t myapp:latest .

# Build with no cache
docker build --no-cache -t myapp:latest .
```

**Tag Image:**
```bash
# Tag image
docker tag myapp:1.0.0 myapp:latest

# Tag for registry
docker tag myapp:1.0.0 myregistry.com/myapp:1.0.0
```

**Push Image:**
```bash
# Login to registry
docker login

# Push image
docker push myregistry.com/myapp:1.0.0
```

---

## Docker Containers

### Running Containers

**Basic Run:**
```bash
# Run container
docker run nginx

# Run in background (detached)
docker run -d nginx

# Run with name
docker run -d --name my-nginx nginx

# Run with port mapping
docker run -d -p 8080:80 nginx

# Run with environment variables
docker run -d -e NODE_ENV=production node:18

# Run with volume mount
docker run -d -v /host/path:/container/path nginx

# Run with interactive terminal
docker run -it ubuntu bash
```

**Advanced Run:**
```bash
# Run with resource limits
docker run -d \
  --memory="512m" \
  --cpus="1.5" \
  nginx

# Run with restart policy
docker run -d --restart=always nginx

# Run with custom network
docker run -d --network=my-network nginx

# Run with hostname
docker run -d --hostname=webserver nginx
```

---

### Managing Containers

**List Containers:**
```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# List with custom format
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```

**Container Lifecycle:**
```bash
# Start stopped container
docker start my-nginx

# Stop running container
docker stop my-nginx

# Restart container
docker restart my-nginx

# Pause container
docker pause my-nginx

# Unpause container
docker unpause my-nginx

# Kill container (force stop)
docker kill my-nginx

# Remove container
docker rm my-nginx

# Remove running container (force)
docker rm -f my-nginx
```

**Interact with Containers:**
```bash
# View container logs
docker logs my-nginx

# Follow logs (like tail -f)
docker logs -f my-nginx

# View last 100 lines
docker logs --tail 100 my-nginx

# Execute command in running container
docker exec my-nginx ls /app

# Interactive shell
docker exec -it my-nginx bash

# Copy files from container
docker cp my-nginx:/app/log.txt ./log.txt

# Copy files to container
docker cp ./config.yml my-nginx:/app/config.yml

# View container stats (live)
docker stats my-nginx

# Inspect container
docker inspect my-nginx
```

---

## Dockerfile Best Practices

### 1. **Use Specific Base Images**

❌ **Bad:**
```dockerfile
FROM node
```

✅ **Good:**
```dockerfile
# Specific version and variant
FROM node:18-alpine
```

---

### 2. **Minimize Layers**

❌ **Bad:**
```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean
```

✅ **Good:**
```dockerfile
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

---

### 3. **Order Instructions by Change Frequency**

```dockerfile
# Least frequently changed first
FROM node:18-alpine

# Package files (change occasionally)
COPY package*.json ./
RUN npm ci --only=production

# Application code (changes often)
COPY . .

CMD ["node", "index.js"]
```

**Why?** Docker caches layers. Putting frequently changing files last maximizes cache usage.

---

### 4. **Use .dockerignore**

```bash
# .dockerignore
node_modules
npm-debug.log
.git
.env
.env.local
dist
build
*.md
.vscode
.idea
coverage
```

---

### 5. **Run as Non-Root User**

❌ **Bad:**
```dockerfile
FROM node:18-alpine
COPY . .
CMD ["node", "index.js"]
# Runs as root!
```

✅ **Good:**
```dockerfile
FROM node:18-alpine

# Create user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set ownership
WORKDIR /app
COPY --chown=nodejs:nodejs . .

# Switch to user
USER nodejs

CMD ["node", "index.js"]
```

---

### 6. **Use COPY instead of ADD**

```dockerfile
# Use COPY for local files
COPY package.json ./

# Use ADD only for tar extraction or URLs
ADD https://example.com/file.tar.gz /tmp/
```

---

### 7. **Leverage Build Cache**

```dockerfile
# Install dependencies before copying code
COPY package*.json ./
RUN npm ci

# Copy code last (changes frequently)
COPY . .
```

---

### 8. **Health Checks**

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node healthcheck.js || exit 1
```

---

## Docker Volumes

### What are Volumes?

Volumes persist data outside containers:
```
Container (ephemeral)        Volume (persistent)
┌──────────────────┐         ┌──────────────────┐
│   /app/data  ────┼────────→│  /var/lib/docker │
└──────────────────┘         │  /volumes/...    │
                             └──────────────────┘
```

### Types of Mounts

**1. Volume (Managed by Docker):**
```bash
docker run -d -v mydata:/app/data nginx
```

**2. Bind Mount (Host directory):**
```bash
docker run -d -v /host/path:/container/path nginx
```

**3. tmpfs Mount (Memory):**
```bash
docker run -d --tmpfs /app/cache nginx
```

---

### Working with Volumes

**Create Volume:**
```bash
docker volume create mydata
```

**List Volumes:**
```bash
docker volume ls
```

**Inspect Volume:**
```bash
docker volume inspect mydata
```

**Remove Volume:**
```bash
docker volume rm mydata

# Remove all unused volumes
docker volume prune
```

---

### Volume Examples

**Database with Persistent Storage:**
```bash
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:15
```

**Development with Live Reload:**
```bash
docker run -d \
  --name dev-app \
  -v $(pwd):/app \
  -p 3000:3000 \
  node:18 \
  npm run dev
```

---

## Docker Networking

### Network Types

**1. Bridge (Default):**
```
Host
└── Bridge Network
    ├── Container A (172.17.0.2)
    ├── Container B (172.17.0.3)
    └── Container C (172.17.0.4)
```

**2. Host:**
```
Container uses host's network directly
(no network isolation)
```

**3. None:**
```
No networking (complete isolation)
```

**4. Custom Bridge:**
```
User-defined network with DNS
```

---

### Network Commands

**Create Network:**
```bash
docker network create mynetwork

# With subnet
docker network create --subnet=172.20.0.0/16 mynetwork
```

**List Networks:**
```bash
docker network ls
```

**Inspect Network:**
```bash
docker network inspect mynetwork
```

**Connect Container to Network:**
```bash
docker network connect mynetwork my-container
```

**Disconnect:**
```bash
docker network disconnect mynetwork my-container
```

---

### Container Communication

**Custom Network Example:**
```bash
# Create network
docker network create app-network

# Run database
docker run -d \
  --name postgres \
  --network app-network \
  postgres:15

# Run app (can access db by name "postgres")
docker run -d \
  --name app \
  --network app-network \
  -e DATABASE_HOST=postgres \
  myapp:latest
```

**Inside the app container:**
```javascript
// Can connect using container name
mongoose.connect('mongodb://mongodb:27017/mydb');
// or
const pool = new Pool({
  host: 'postgres',
  database: 'mydb'
});
```

---

## Docker Compose

### What is Docker Compose?

**Docker Compose** is a tool for defining and running multi-container applications.

### docker-compose.yml Example

```yaml
version: '3.8'

services:
  # Node.js Application
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:password@postgres:5432/mydb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    networks:
      - app-network
    volumes:
      - ./logs:/app/logs
    restart: always

  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=mydb
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    networks:
      - app-network
    volumes:
      - redisdata:/data

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - app
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  pgdata:
  redisdata:
```

---

### Docker Compose Commands

**Start Services:**
```bash
# Start all services
docker-compose up

# Start in background
docker-compose up -d

# Build and start
docker-compose up --build

# Scale service
docker-compose up -d --scale app=3
```

**Stop Services:**
```bash
# Stop services
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop, remove containers, networks, and volumes
docker-compose down -v
```

**View Services:**
```bash
# List running services
docker-compose ps

# View logs
docker-compose logs

# Follow logs
docker-compose logs -f app

# View logs for specific service
docker-compose logs -f postgres
```

**Execute Commands:**
```bash
# Run command in service
docker-compose exec app npm run migrate

# Interactive shell
docker-compose exec app sh

# Run one-off command
docker-compose run app npm test
```

---

## Multi-Stage Builds

### Why Multi-Stage Builds?

Reduce image size by separating build and runtime dependencies.

**Without Multi-Stage:**
```dockerfile
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install  # Includes devDependencies
COPY . .
RUN npm run build
CMD ["node", "dist/index.js"]

# Final image: 1.2 GB (includes build tools!)
```

**With Multi-Stage:**
```dockerfile
# Stage 1: Build
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/index.js"]

# Final image: 150 MB (much smaller!)
```

---

### Advanced Multi-Stage Example

```dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Stage 2: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build && \
    npm run test

# Stage 3: Production
FROM node:18-alpine AS production
WORKDIR /app

# Copy dependencies from first stage
COPY --from=dependencies /app/node_modules ./node_modules

# Copy built application
COPY --from=builder /app/dist ./dist
COPY package.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

---

## Docker Security

### Security Best Practices

**1. Use Official Images:**
```dockerfile
# ✅ Good
FROM node:18-alpine

# ❌ Avoid
FROM random-user/node-image
```

**2. Scan Images for Vulnerabilities:**
```bash
# Using Docker Scout
docker scout cve myapp:latest

# Using Trivy
trivy image myapp:latest

# Using Snyk
snyk container test myapp:latest
```

**3. Don't Run as Root:**
```dockerfile
USER nodejs
```

**4. Use Read-Only Filesystem:**
```bash
docker run -d --read-only myapp:latest
```

**5. Drop Capabilities:**
```bash
docker run -d --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp:latest
```

**6. Limit Resources:**
```bash
docker run -d \
  --memory="512m" \
  --cpus="1.0" \
  --pids-limit=100 \
  myapp:latest
```

**7. Use Secrets Management:**
```bash
# Don't include secrets in image
# Use environment variables or secrets management

# Docker Swarm secrets
docker secret create db_password password.txt
docker service create --secret db_password myapp:latest

# Or use external secrets manager
docker run -d -e DATABASE_URL=$(vault kv get secret/db) myapp:latest
```

---

## Summary

**Key Takeaways:**

✅ Containers are **lightweight, portable**, and **consistent**
✅ Docker images are **layered** and **cacheable**
✅ Use **multi-stage builds** to reduce image size
✅ Follow **Dockerfile best practices** (specific tags, non-root user, etc.)
✅ Use **volumes** for persistent data
✅ Use **networks** for container communication
✅ **Docker Compose** simplifies multi-container apps
✅ Always consider **security** (scan images, run as non-root, etc.)

**Next Steps:**
- **Next**: [08-Kubernetes-Fundamentals.md](./08-Kubernetes-Fundamentals.md) - Learn container orchestration
- **Related**: [07-Docker-Advanced.md](./07-Docker-Advanced.md) - Advanced Docker topics

---

*Remember: Containers are cattle, not pets. Design for immutability and replaceability!*
