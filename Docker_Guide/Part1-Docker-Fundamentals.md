# Part 1: Docker Fundamentals & Core Concepts

## Table of Contents
1. [What is Docker and Why Use It?](#what-is-docker-and-why-use-it)
2. [Docker Architecture](#docker-architecture)
3. [Core Concepts: Images, Containers, Registries](#core-concepts-images-containers-registries)
4. [Docker vs Virtual Machines](#docker-vs-virtual-machines)
5. [Basic Docker Commands](#basic-docker-commands)
6. [Container Lifecycle](#container-lifecycle)
7. [Networking Basics](#networking-basics)
8. [Volume Management](#volume-management)

---

## What is Docker and Why Use It?

### The Problem Docker Solves

**Before Docker:**
```
Developer: "It works on my machine!" 🤷‍♂️
Operations: "Well, it doesn't work in production!" 😤
```

```mermaid
graph LR
    A[Development<br/>Python 3.9<br/>Ubuntu 20.04] -->|Deploy| B[Staging<br/>Python 3.8<br/>CentOS 7]
    B -->|Deploy| C[Production<br/>Python 3.7<br/>RHEL 8]
    
    style A fill:#51cf66
    style B fill:#ffd43b
    style C fill:#ff6b6b
```

**Common Issues:**
- Different OS versions
- Missing dependencies
- Configuration drift
- "Library version mismatch"
- Environment-specific bugs

### Docker Solution

**With Docker:**
```
Developer: "Here's the container image"
Operations: "It works everywhere!" ✅
```

```mermaid
graph LR
    A[Docker Image] --> B[Development]
    A --> C[Staging]
    A --> D[Production]
    
    style A fill:#4dabf7
    style B fill:#51cf66
    style C fill:#51cf66
    style D fill:#51cf66
```

### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Consistency** | Same environment everywhere (dev → prod) |
| **Isolation** | Applications don't interfere with each other |
| **Portability** | Run anywhere (laptop, cloud, on-prem) |
| **Efficiency** | Lightweight compared to VMs |
| **Scalability** | Easy to spin up/down instances |
| **Version Control** | Image versioning and rollbacks |

---

## Docker Architecture

### High-Level Architecture

```mermaid
graph TD
    subgraph Client
        CLI[Docker CLI<br/>docker run, build, push]
    end
    
    subgraph Docker Host
        DAEMON[Docker Daemon<br/>dockerd]
        IMAGES[Images]
        CONTAINERS[Containers]
        VOLUMES[Volumes]
        NETWORKS[Networks]
    end
    
    subgraph Registry
        DOCKER_HUB[Docker Hub<br/>Public Registry]
        PRIVATE[Private Registry<br/>ECR, GCR, ACR]
    end
    
    CLI -->|API Calls| DAEMON
    DAEMON --> IMAGES
    DAEMON --> CONTAINERS
    DAEMON --> VOLUMES
    DAEMON --> NETWORKS
    DAEMON <-->|Pull/Push| DOCKER_HUB
    DAEMON <-->|Pull/Push| PRIVATE
    
    style DAEMON fill:#4dabf7
    style DOCKER_HUB fill:#51cf66
```

### Components Explained

#### 1. Docker Client (CLI)
```bash
# User interacts with Docker through CLI
docker run nginx
docker build -t myapp .
docker push myapp:latest
```

#### 2. Docker Daemon (dockerd)
- Background service running on the host
- Manages images, containers, networks, volumes
- Listens to Docker API requests

#### 3. Docker Registry
- Stores Docker images
- Public: Docker Hub, Quay.io
- Private: AWS ECR, Google GCR, Azure ACR, Harbor

---

## Core Concepts: Images, Containers, Registries

### Docker Images

**What is an image?**
- Read-only template with application code and dependencies
- Built from Dockerfile instructions
- Stored in layers (like Git commits)

```mermaid
graph TD
    A[Base Layer<br/>ubuntu:20.04] --> B[Layer 2<br/>apt-get install python3]
    B --> C[Layer 3<br/>pip install flask]
    C --> D[Layer 4<br/>COPY app.py]
    D --> E[Final Image<br/>myapp:latest]
    
    style A fill:#e1f5ff
    style B fill:#b3e5fc
    style C fill:#81d4fa
    style D fill:#4fc3f7
    style E fill:#4dabf7
```

**Image Layers Example:**
```dockerfile
FROM ubuntu:20.04              # Layer 1
RUN apt-get update             # Layer 2
RUN apt-get install python3    # Layer 3
COPY app.py /app/              # Layer 4
CMD ["python3", "/app/app.py"] # Layer 5
```

> [!IMPORTANT]
> Layers are cached! If you rebuild and only `app.py` changes, layers 1-3 are reused from cache.

### Docker Containers

**What is a container?**
- Running instance of an image
- Isolated process with its own filesystem, network, process space
- Can be started, stopped, moved, deleted

```mermaid
graph LR
    A[Docker Image<br/>myapp:latest] -->|docker run| B[Container 1<br/>Instance]
    A -->|docker run| C[Container 2<br/>Instance]
    A -->|docker run| D[Container 3<br/>Instance]
    
    style A fill:#4dabf7
    style B fill:#51cf66
    style C fill:#51cf66
    style D fill:#51cf66
```

**Analogy:**
- **Image** = Class definition (blueprint)
- **Container** = Object instance (running program)

### Docker Registry

**Image naming convention:**
```
[registry]/[username]/[repository]:[tag]
docker.io/library/nginx:1.21-alpine

registry    = docker.io (Docker Hub)
username    = library (official images)
repository  = nginx
tag         = 1.21-alpine (version)
```

---

## Docker vs Virtual Machines

```mermaid
graph TD
    subgraph Virtual Machines
        A1[Infrastructure<br/>CPU, RAM, Disk]
        A2[Hypervisor<br/>VMware, VirtualBox]
        A3[VM 1<br/>Guest OS + App]
        A4[VM 2<br/>Guest OS + App]
        A5[VM 3<br/>Guest OS + App]
        
        A1 --> A2
        A2 --> A3
        A2 --> A4
        A2 --> A5
    end
    
    subgraph Docker Containers
        B1[Infrastructure<br/>CPU, RAM, Disk]
        B2[Host OS<br/>Linux Kernel]
        B3[Docker Engine]
        B4[Container 1<br/>App + Libs]
        B5[Container 2<br/>App + Libs]
        B6[Container 3<br/>App + Libs]
        
        B1 --> B2
        B2 --> B3
        B3 --> B4
        B3 --> B5
        B3 --> B6
    end
    
    style A1 fill:#868e96
    style A2 fill:#ff6b6b
    style B3 fill:#4dabf7
```

### Comparison Table

| Aspect | Virtual Machines | Docker Containers |
|--------|------------------|-------------------|
| **Size** | GBs (full OS) | MBs (app + dependencies) |
| **Startup Time** | Minutes | Seconds |
| **Resource Usage** | Heavy (each VM has full OS) | Lightweight (share host kernel) |
| **Isolation** | Strong (hardware-level) | Process-level |
| **Portability** | Limited (VM images are large) | Excellent (images are small) |
| **Performance** | Slower (virtualization overhead) | Near-native performance |
| **Density** | 10-20 VMs per host | 100s of containers per host |

**When to Use VMs:**
- Strong isolation required (security)
- Different OS kernels needed (Windows + Linux)
- Legacy applications

**When to Use Containers:**
- Microservices architecture
- CI/CD pipelines
- Rapid scaling
- Cloud-native applications

---

## Basic Docker Commands

### Working with Images

```bash
# Pull image from registry
docker pull nginx:latest

# List local images
docker images
# or
docker image ls

# Remove image
docker rmi nginx:latest
# or
docker image rm nginx:latest

# Build image from Dockerfile
docker build -t myapp:1.0 .

# Tag image (create alias)
docker tag myapp:1.0 myapp:latest

# Push to registry
docker push myusername/myapp:1.0

# View image layers and size
docker history nginx:latest

# Inspect image details
docker inspect nginx:latest

# Remove unused images
docker image prune
```

### Working with Containers

```bash
# Run container (create and start)
docker run nginx

# Run in background (detached mode)
docker run -d nginx

# Run with name
docker run -d --name my-nginx nginx

# Run with port mapping
docker run -d -p 8080:80 nginx
# Host port 8080 → Container port 80

# Run with environment variables
docker run -d -e MYSQL_ROOT_PASSWORD=secret mysql:8

# Run with volume
docker run -d -v /host/path:/container/path nginx

# Interactive mode (bash shell)
docker run -it ubuntu:20.04 /bin/bash

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop container
docker stop my-nginx

# Start stopped container
docker start my-nginx

# Restart container
docker restart my-nginx

# Remove container
docker rm my-nginx

# Remove running container (force)
docker rm -f my-nginx

# View container logs
docker logs my-nginx

# Follow logs (real-time)
docker logs -f my-nginx

# Execute command in running container
docker exec -it my-nginx /bin/bash

# View container resource usage
docker stats

# View container details
docker inspect my-nginx

# Remove stopped containers
docker container prune
```

### Real-World Example: Running a Web Application

```bash
# 1. Pull Node.js image
docker pull node:18-alpine

# 2. Run Node.js app with volume mount (for development)
docker run -d \
  --name my-node-app \
  -p 3000:3000 \
  -v $(pwd)/app:/usr/src/app \
  -w /usr/src/app \
  node:18-alpine \
  npm start

# 3. View logs
docker logs -f my-node-app

# 4. Enter container to debug
docker exec -it my-node-app sh

# 5. Stop and remove
docker stop my-node-app
docker rm my-node-app
```

---

## Container Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created: docker create
    Created --> Running: docker start
    Running --> Paused: docker pause
    Paused --> Running: docker unpause
    Running --> Stopped: docker stop
    Stopped --> Running: docker start
    Stopped --> Removed: docker rm
    Running --> Removed: docker rm -f
    Removed --> [*]
    
    Created --> Removed: docker rm
```

### Lifecycle Commands

```bash
# Create container (doesn't start it)
docker create --name my-app nginx

# Start created container
docker start my-app

# Pause running container (freeze processes)
docker pause my-app

# Unpause
docker unpause my-app

# Stop container (sends SIGTERM, waits, then SIGKILL)
docker stop my-app

# Kill container immediately (SIGKILL)
docker kill my-app

# Remove container
docker rm my-app
```

### Container States

| State | Description | CPU Usage | Memory Usage |
|-------|-------------|-----------|--------------|
| **Created** | Container exists but not running | None | None |
| **Running** | Container is executing | Active | Active |
| **Paused** | Processes frozen | None | Retained |
| **Stopped** | Container exited | None | None |
| **Removed** | Container deleted | None | None |

---

## Networking Basics

### Network Types

```mermaid
graph TD
    A[Docker Networks] --> B[Bridge<br/>Default]
    A --> C[Host<br/>Share host network]
    A --> D[None<br/>No networking]
    A --> E[Custom Bridge<br/>User-defined]
    
    style B fill:#4dabf7
    style E fill:#51cf66
```

### 1. Bridge Network (Default)

**How it works:**
- Default network for containers
- Containers get internal IP addresses
- Containers on same bridge can communicate

```bash
# Containers on default bridge
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# They can reach each other via IP
docker exec web1 ping <web2-ip>
```

```mermaid
graph LR
    H[Host<br/>172.17.0.1] --- B[docker0 bridge]
    
    B --- C1[Container 1<br/>172.17.0.2]
    B --- C2[Container 2<br/>172.17.0.3]
    B --- C3[Container 3<br/>172.17.0.4]
    
    style B fill:#4dabf7
```

### 2. Custom Bridge Network

**Better for microservices:**
- DNS resolution by container name
- Better isolation
- Can disconnect/reconnect containers

```bash
# Create custom network
docker network create my-network

# Run containers on custom network
docker run -d --name api --network my-network myapi:latest
docker run -d --name db --network my-network postgres:14

# Containers can communicate by name!
# Inside api container:
curl http://db:5432  # DNS resolves to db container
```

### 3. Host Network

**Direct host network access:**

```bash
# Container uses host's network stack
docker run -d --network host nginx

# nginx binds directly to host's port 80
# No port mapping needed
```

> [!WARNING]
> Host network mode removes network isolation. Use only when necessary (performance, tools that need host network).

### Port Mapping

```bash
# Map container port 80 to host port 8080
docker run -d -p 8080:80 nginx

# Map to random host port
docker run -d -p 80 nginx

# Map multiple ports
docker run -d \
  -p 8080:80 \
  -p 8443:443 \
  nginx

# Bind to specific host interface
docker run -d -p 127.0.0.1:8080:80 nginx
```

### Network Commands

```bash
# List networks
docker network ls

# Create network
docker network create my-network

# Inspect network
docker network inspect my-network

# Connect container to network
docker network connect my-network my-container

# Disconnect container
docker network disconnect my-network my-container

# Remove network
docker network rm my-network

# Remove unused networks
docker network prune
```

---

## Volume Management

### Why Volumes?

**Problem:** Container filesystem is ephemeral (deleted when container is removed)

```bash
# Data is lost when container is removed!
docker run -d --name db mysql:8
docker rm -f db  # All database data is GONE! ❌
```

**Solution:** Volumes persist data outside container lifecycle

### Volume Types

```mermaid
graph TD
    A[Docker Volumes] --> B[Named Volumes<br/>Managed by Docker]
    A --> C[Bind Mounts<br/>Host filesystem path]
    A --> D[tmpfs Mounts<br/>Memory-only]
    
    style B fill:#51cf66
    style C fill:#4dabf7
```

### 1. Named Volumes (Recommended)

```bash
# Create volume
docker volume create mydata

# Run container with volume
docker run -d \
  --name db \
  -v mydata:/var/lib/mysql \
  mysql:8

# Data persists even after container removal
docker rm -f db
docker volume ls  # mydata still exists!

# Start new container with same volume
docker run -d \
  --name db2 \
  -v mydata:/var/lib/mysql \
  mysql:8
# Data from previous container is available!
```

**Volume location:**
- Linux: `/var/lib/docker/volumes/`
- Windows: `C:\ProgramData\Docker\volumes\`
- Mac: VM filesystem

### 2. Bind Mounts

**Mount host directory into container:**

```bash
# Development: Live code updates
docker run -d \
  --name webapp \
  -v $(pwd)/app:/usr/src/app \
  -p 3000:3000 \
  node:18-alpine \
  npm start

# Edit files on host → changes reflect in container immediately!
```

**Use cases:**
- Development (live reload)
- Configuration files
- Sharing data between host and container

### 3. tmpfs Mounts (Memory-only)

```bash
# Sensitive data in memory (not persisted)
docker run -d \
  --tmpfs /tmp \
  myapp

# Data is lost when container stops
```

### Volume Commands

```bash
# List volumes
docker volume ls

# Create volume
docker volume create myvolume

# Inspect volume (shows mount point)
docker volume inspect myvolume

# Remove volume
docker volume rm myvolume

# Remove unused volumes
docker volume prune

# Remove all volumes (dangerous!)
docker volume prune -a
```

### Real-World Example: PostgreSQL with Persistent Data

```bash
# Create network for database
docker network create app-network

# Create volume for database data
docker volume create postgres-data

# Run PostgreSQL with volume
docker run -d \
  --name postgres \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=myapp \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:15

# Run application connected to database
docker run -d \
  --name api \
  --network app-network \
  -e DATABASE_URL=postgresql://postgres:secret@postgres:5432/myapp \
  -p 3000:3000 \
  myapi:latest

# Query database from app container
docker exec -it api curl http://postgres:5432
```

---

## Practical Example: Complete Web Stack

**Scenario:** WordPress site with MySQL database

```bash
# 1. Create network
docker network create wordpress-net

# 2. Create volumes
docker volume create mysql-data
docker volume create wordpress-data

# 3. Run MySQL
docker run -d \
  --name mysql \
  --network wordpress-net \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=wordpress \
  -e MYSQL_USER=wpuser \
  -e MYSQL_PASSWORD=wppass \
  -v mysql-data:/var/lib/mysql \
  mysql:8

# 4. Run WordPress
docker run -d \
  --name wordpress \
  --network wordpress-net \
  -e WORDPRESS_DB_HOST=mysql \
  -e WORDPRESS_DB_USER=wpuser \
  -e WORDPRESS_DB_PASSWORD=wppass \
  -e WORDPRESS_DB_NAME=wordpress \
  -v wordpress-data:/var/www/html \
  -p 8080:80 \
  wordpress:latest

# 5. Access WordPress at http://localhost:8080

# 6. View logs
docker logs -f wordpress

# 7. Backup database
docker exec mysql mysqldump -u wpuser -pwppass wordpress > backup.sql

# 8. Cleanup
docker stop wordpress mysql
docker rm wordpress mysql
docker volume rm mysql-data wordpress-data
docker network rm wordpress-net
```

---

## Key Takeaways

> [!IMPORTANT]
> **Docker Fundamentals Summary:**
> 1. **Images** are blueprints, **containers** are running instances
> 2. Containers are **lightweight** and start in **seconds**
> 3. Use **custom bridge networks** for container communication
> 4. Use **named volumes** for data persistence
> 5. **Port mapping** exposes container services to host
> 6. Containers are **isolated** but share the host kernel
> 7. **Layers are cached** during image builds
> 8. Always use **specific image tags** in production (not `latest`)

---

## Common Mistakes to Avoid

```bash
# ❌ Don't store data in containers (use volumes instead)
docker run -d mysql:8  # Data lost on removal!

# ✅ Use volumes
docker run -d -v mysql-data:/var/lib/mysql mysql:8

# ❌ Don't use 'latest' tag in production
docker run myapp:latest  # Version unknown, breaks reproducibility

# ✅ Use specific versions
docker run myapp:1.2.3

# ❌ Don't run as root in containers
# (covered in security section)

# ❌ Don't expose all ports
docker run -P myapp  # Exposes all EXPOSE ports randomly

# ✅ Explicitly map needed ports
docker run -p 8080:80 myapp
```

---

## Next Steps

In **Part 2**, we'll dive into:
- Writing optimized Dockerfiles
- Multi-stage builds
- Layer caching strategies
- Build arguments and secrets
- Image optimization techniques
- Security best practices in Dockerfiles

---

**Continue to:** [Part 2: Dockerfile Best Practices & Multi-Stage Builds](file:///C:/Users/phusukale/Downloads/Docs/Repo/Docker_Guide/Part2-Dockerfile-Best-Practices.md)
