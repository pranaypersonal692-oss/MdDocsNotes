# Complete Guide to Web Application Deployment Using Coolify

> [!NOTE]
> This guide is designed as a comprehensive learning resource for understanding web application deployment from end to end. Using Coolify on a local VM, you'll simulate real-world deployment scenarios without needing expensive infrastructure.

## Table of Contents

1. [Introduction to Deployment](#1-introduction-to-deployment)
2. [Understanding the Deployment Landscape](#2-understanding-the-deployment-landscape)
3. [Prerequisites and VM Setup](#3-prerequisites-and-vm-setup)
4. [Installing and Configuring Coolify](#4-installing-and-configuring-coolify)
5. [Deployment Workflows](#5-deployment-workflows)
6. [Practical Examples](#6-practical-examples)
7. [Advanced Topics](#7-advanced-topics)
8. [Troubleshooting and Best Practices](#8-troubleshooting-and-best-practices)

---

## 1. Introduction to Deployment

### 1.1 What is Web Application Deployment?

**Deployment** is the process of making your application available to users. It involves:
- Moving code from development to production environments
- Configuring servers and infrastructure
- Setting up databases, caching, and other services
- Ensuring security, scalability, and reliability
- Monitoring and maintaining the application

### 1.2 Why Learn Deployment?

Understanding deployment helps you:
- **Bridge the gap** between development and operations (DevOps)
- **Debug production issues** more effectively
- **Design better applications** with deployment constraints in mind
- **Advance your career** with full-stack capabilities

### 1.3 What is Coolify?

**Coolify** is an open-source, self-hostable alternative to services like Heroku, Netlify, or Vercel. It provides:
- User-friendly web interface for deployment
- Support for multiple application types (Docker, Node.js, PHP, Python, etc.)
- Built-in SSL/TLS certificates (Let's Encrypt)
- Database management (PostgreSQL, MySQL, MongoDB, Redis)
- Environment variable management
- Automatic deployments from Git repositories
- Reverse proxy configuration (Traefik)

### 1.4 Learning Approach

```mermaid
graph LR
    A[Fundamentals] --> B[Setup VM & Coolify]
    B --> C[Deploy Simple App]
    C --> D[Database Integration]
    D --> E[Advanced Patterns]
    E --> F[Production Practices]
    
    style A fill:#e1f5ff
    style B fill:#b3e5fc
    style C fill:#81d4fa
    style D fill:#4fc3f7
    style E fill:#29b6f6
    style F fill:#039be5
```

---

## 2. Understanding the Deployment Landscape

### 2.1 Deployment Architecture Overview

```mermaid
graph TB
    subgraph "Developer Machine"
        DEV[Your Code]
    end
    
    subgraph "Version Control"
        GIT[Git Repository<br/>GitHub/GitLab]
    end
    
    subgraph "Deployment Server - VM"
        COOLIFY[Coolify Platform]
        TRAEFIK[Traefik Reverse Proxy]
        subgraph "Applications"
            APP1[App 1<br/>Docker Container]
            APP2[App 2<br/>Docker Container]
            APP3[App 3<br/>Docker Container]
        end
        subgraph "Services"
            DB[(PostgreSQL)]
            REDIS[(Redis)]
            MONGO[(MongoDB)]
        end
    end
    
    subgraph "Users"
        USER[End Users]
    end
    
    DEV -->|git push| GIT
    GIT -->|webhook/pull| COOLIFY
    COOLIFY -->|deploy| APP1
    COOLIFY -->|deploy| APP2
    COOLIFY -->|deploy| APP3
    COOLIFY -->|manage| DB
    COOLIFY -->|manage| REDIS
    COOLIFY -->|manage| MONGO
    TRAEFIK -->|route| APP1
    TRAEFIK -->|route| APP2
    TRAEFIK -->|route| APP3
    USER -->|HTTPS| TRAEFIK
    APP1 -.->|connect| DB
    APP2 -.->|connect| REDIS
    APP3 -.->|connect| MONGO
    
    style COOLIFY fill:#ff9800
    style TRAEFIK fill:#4caf50
```

### 2.2 Key Deployment Concepts

#### 2.2.1 Environments

| Environment | Purpose | Characteristics |
|-------------|---------|-----------------|
| **Development** | Active coding | Frequent changes, debugging tools |
| **Staging** | Pre-production testing | Mirror of production |
| **Production** | Live users | Stable, monitored, secured |

#### 2.2.2 Deployment Strategies

```mermaid
graph TB
    subgraph "Deployment Strategies"
        direction TB
        
        subgraph "1. Recreate"
            R1[Old Version v1] -->|Stop| R2[Downtime]
            R2 -->|Deploy| R3[New Version v2]
        end
        
        subgraph "2. Rolling Update"
            RU1[v1 - Instance 1<br/>v1 - Instance 2<br/>v1 - Instance 3] 
            RU1 -->|Update one by one| RU2[v2 - Instance 1<br/>v1 - Instance 2<br/>v1 - Instance 3]
            RU2 --> RU3[v2 - Instance 1<br/>v2 - Instance 2<br/>v2 - Instance 3]
        end
        
        subgraph "3. Blue-Green"
            BG1[Blue Environment v1<br/>Active] 
            BG2[Green Environment v2<br/>Idle]
            BG1 -->|Switch Traffic| BG3[Green Environment v2<br/>Active]
        end
        
        subgraph "4. Canary"
            C1[v1 - 90% Traffic<br/>v2 - 10% Traffic]
            C1 -->|Gradual Increase| C2[v1 - 50% Traffic<br/>v2 - 50% Traffic]
            C2 --> C3[v2 - 100% Traffic]
        end
    end
```

#### 2.2.3 Infrastructure Components

```mermaid
graph LR
    subgraph "Infrastructure Stack"
        LB[Load Balancer<br/>Distributes Traffic]
        RP[Reverse Proxy<br/>Traefik/Nginx]
        APP[Application Server<br/>Your Code]
        DB[(Database<br/>PostgreSQL/MySQL)]
        CACHE[(Cache<br/>Redis)]
        STORAGE[File Storage<br/>S3/Local]
    end
    
    INTERNET[Internet] --> LB
    LB --> RP
    RP --> APP
    APP --> DB
    APP --> CACHE
    APP --> STORAGE
    
    style LB fill:#2196f3
    style RP fill:#4caf50
    style APP fill:#ff9800
    style DB fill:#9c27b0
    style CACHE fill:#f44336
    style STORAGE fill:#607d8b
```

### 2.3 Docker Fundamentals

Coolify uses Docker extensively. Understanding Docker is crucial:

```mermaid
graph TB
    subgraph "Docker Ecosystem"
        DF[Dockerfile<br/>Build Instructions]
        IMG[Docker Image<br/>Template]
        CONT[Docker Container<br/>Running Instance]
        VOL[Volumes<br/>Persistent Data]
        NET[Networks<br/>Container Communication]
        
        DF -->|docker build| IMG
        IMG -->|docker run| CONT
        CONT -.->|uses| VOL
        CONT -.->|uses| NET
    end
    
    style DF fill:#e3f2fd
    style IMG fill:#90caf9
    style CONT fill:#42a5f5
    style VOL fill:#1e88e5
    style NET fill:#1565c0
```

**Key Docker Concepts:**

1. **Image**: Blueprint for your application (immutable)
2. **Container**: Running instance of an image
3. **Volume**: Persistent storage for data
4. **Network**: Isolated network for containers to communicate
5. **Registry**: Storage for images (Docker Hub, etc.)

---

## 3. Prerequisites and VM Setup

### 3.1 System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4 GB | 8+ GB |
| **Storage** | 30 GB | 50+ GB |
| **OS** | Ubuntu 20.04+ | Ubuntu 22.04 LTS |

### 3.2 VM Options

```mermaid
graph TB
    subgraph "VM Options for Learning"
        LOCAL[Local VMs]
        CLOUD[Cloud VMs]
        
        LOCAL --> VM1[VirtualBox<br/>Free]
        LOCAL --> VM2[VMware Workstation<br/>Free Player Available]
        LOCAL --> VM3[Hyper-V<br/>Windows Built-in]
        
        CLOUD --> CL1[Oracle Cloud<br/>Free Tier]
        CLOUD --> CL2[AWS EC2<br/>Free Tier 12 months]
        CLOUD --> CL3[Google Cloud<br/>$300 Credit]
        CLOUD --> CL4[Azure<br/>Free Tier]
    end
    
    style LOCAL fill:#4caf50
    style CLOUD fill:#2196f3
```

### 3.3 Step-by-Step: VirtualBox VM Setup

#### Step 1: Download and Install VirtualBox

1. Visit [https://www.virtualbox.org/](https://www.virtualbox.org/)
2. Download VirtualBox for Windows
3. Install with default settings

#### Step 2: Download Ubuntu Server

1. Visit [https://ubuntu.com/download/server](https://ubuntu.com/download/server)
2. Download Ubuntu 22.04 LTS Server ISO

#### Step 3: Create Virtual Machine

```mermaid
sequenceDiagram
    participant You
    participant VirtualBox
    participant VM
    participant Ubuntu
    
    You->>VirtualBox: Click "New"
    VirtualBox->>You: VM Creation Wizard
    You->>VirtualBox: Name: Coolify-Server<br/>Type: Linux<br/>Version: Ubuntu 64-bit
    You->>VirtualBox: RAM: 4096 MB (4 GB)
    You->>VirtualBox: Create Virtual Hard Disk: 50 GB
    VirtualBox->>VM: VM Created
    You->>VM: Select VM → Settings
    You->>VM: Network → Adapter 1 → Bridged Adapter
    You->>VM: Storage → Add Ubuntu ISO
    You->>VM: Start VM
    VM->>Ubuntu: Boot from ISO
    Ubuntu->>You: Installation Wizard
    You->>Ubuntu: Install Ubuntu Server
    Ubuntu->>VM: Installation Complete
```

**Detailed Settings:**

1. **General**
   - Name: `Coolify-Server`
   - Type: Linux
   - Version: Ubuntu (64-bit)

2. **System**
   - Base Memory: 4096 MB
   - Processors: 2-4 CPUs
   - Enable PAE/NX

3. **Storage**
   - Create virtual hard disk: 50 GB (dynamically allocated)
   - Attach Ubuntu ISO to Optical Drive

4. **Network**
   - Adapter 1: Bridged Adapter (to get IP on local network)
   - Alternative: NAT with Port Forwarding

5. **NAT Port Forwarding (if using NAT)**
   | Name | Protocol | Host Port | Guest Port |
   |------|----------|-----------|------------|
   | SSH | TCP | 2222 | 22 |
   | HTTP | TCP | 8080 | 80 |
   | HTTPS | TCP | 8443 | 443 |
   | Coolify | TCP | 8000 | 8000 |

#### Step 4: Install Ubuntu Server

1. **Start the VM** and boot from ISO
2. **Choose language**: English
3. **Update installer**: Proceed
4. **Keyboard layout**: English (US)
5. **Installation type**: Ubuntu Server
6. **Network**: Configure DHCP (automatic) or static IP
7. **Proxy**: Leave blank (unless needed)
8. **Mirror**: Default
9. **Storage**: Use entire disk
10. **Profile Setup**:
    - Your name: `your-name`
    - Server name: `coolify-server`
    - Username: `coolify`
    - Password: `strong-password`
11. **SSH**: ✅ Install OpenSSH server
12. **Featured snaps**: Skip for now
13. **Installation**: Wait for completion
14. **Reboot**: Remove ISO and reboot

#### Step 5: Post-Installation Setup

Once Ubuntu is installed and running:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git nano net-tools

# Check IP address
ip addr show

# Test internet connectivity
ping -c 4 google.com
```

#### Step 6: Configure SSH Access (from your Windows machine)

```powershell
# Using PowerShell on Windows
ssh coolify@<VM-IP-ADDRESS>

# Example:
ssh coolify@192.168.1.100
```

> [!TIP]
> Save your VM's IP address. You'll use it frequently. For convenience, add an entry to your hosts file:
> - Windows: `C:\Windows\System32\drivers\etc\hosts`
> - Add line: `192.168.1.100 coolify.local`

---

## 4. Installing and Configuring Coolify

### 4.1 Coolify Architecture

```mermaid
graph TB
    subgraph "Coolify Internal Architecture"
        UI[Web UI<br/>Port 8000]
        API[Coolify API]
        DB[(SQLite Database)]
        QUEUE[Job Queue]
        
        subgraph "Docker Engine"
            TRAEFIK[Traefik<br/>Reverse Proxy]
            APPS[Application<br/>Containers]
            SERVICES[Service<br/>Containers]
        end
        
        UI --> API
        API --> DB
        API --> QUEUE
        QUEUE --> DOCKER[Docker Commands]
        DOCKER --> APPS
        DOCKER --> SERVICES
        TRAEFIK --> APPS
    end
    
    EXTERNAL[External Traffic] --> TRAEFIK
    
    style UI fill:#ff9800
    style TRAEFIK fill:#4caf50
    style APPS fill:#2196f3
    style SERVICES fill:#9c27b0
```

### 4.2 Installation Process

#### Step 1: Pre-Installation Checks

```bash
# Ensure you're up to date
sudo apt update && sudo apt upgrade -y

# Verify system resources
free -h  # Check RAM
df -h    # Check disk space
```

#### Step 2: Install Coolify

```bash
# Run the official Coolify installation script
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# The script will:
# 1. Install Docker Engine
# 2. Install Docker Compose
# 3. Download Coolify
# 4. Start Coolify services
```

> [!IMPORTANT]
> The installation takes 5-10 minutes. Don't interrupt the process!

#### Step 3: Installation Flow

```mermaid
sequenceDiagram
    participant User
    participant Script as Install Script
    participant System
    participant Docker
    participant Coolify
    
    User->>Script: curl install.sh | bash
    Script->>System: Check Requirements
    Script->>System: Install Dependencies
    Script->>Docker: Install Docker Engine
    Script->>Docker: Install Docker Compose
    Script->>System: Configure Firewall
    Script->>Coolify: Download Coolify
    Script->>Docker: Start Coolify Containers
    Coolify->>User: Ready! Access on port 8000
```

#### Step 4: Verify Installation

```bash
# Check if Coolify is running
docker ps

# You should see containers like:
# - coolify
# - coolify-db
# - coolify-proxy (Traefik)

# Check Coolify logs
docker logs coolify -f

# Access Coolify Web UI
# Open browser: http://<VM-IP>:8000
# Example: http://192.168.1.100:8000 or http://coolify.local:8000
```

### 4.3 Initial Coolify Configuration

#### Step 1: First Login

```mermaid
graph LR
    A[Open http://VM-IP:8000] --> B[Registration Page]
    B --> C[Create Admin Account]
    C --> D[Email & Password]
    D --> E[Instance Setup]
    E --> F[Dashboard]
    
    style C fill:#4caf50
    style F fill:#2196f3
```

1. Navigate to `http://<VM-IP>:8000`
2. **Create your admin account**:
   - Email: your-email@example.com
   - Password: strong-password
   - Name: Your Name
3. **Login** with credentials

#### Step 2: Configure Server

1. **Go to Settings** → **Servers**
2. By default, `localhost` server is pre-configured
3. This represents your VM where Coolify is installed

#### Step 3: Understand Dashboard

```mermaid
graph TB
    subgraph "Coolify Dashboard Structure"
        DASH[Dashboard]
        
        DASH --> PROJ[Projects]
        DASH --> SERVERS[Servers]
        DASH --> SERVICES[Services]
        DASH --> SETTINGS[Settings]
        
        PROJ --> APPS[Applications]
        PROJ --> DBS[Databases]
        PROJ --> ENV[Environments]
        
        SERVERS --> SERVER1[localhost]
        
        SERVICES --> PRE[Predefined Services<br/>PostgreSQL, Redis, etc.]
        
        SETTINGS --> TEAM[Team]
        SETTINGS --> NOTIF[Notifications]
        SETTINGS --> BACKUP[Backups]
    end
    
    style DASH fill:#ff9800
    style PROJ fill:#4caf50
    style SERVERS fill:#2196f3
```

### 4.4 Key Concepts in Coolify

| Concept | Description | Example |
|---------|-------------|---------|
| **Server** | Physical/virtual machine where apps run | Your VM |
| **Project** | Container for related applications | "My Portfolio" |
| **Environment** | Deployment environment within project | Production, Staging |
| **Application** | Your deployed web application | Node.js app, PHP site |
| **Service** | Pre-configured software (DB, cache) | PostgreSQL, Redis |
| **Destination** | Where on the server apps are deployed | Docker Engine |

---

## 5. Deployment Workflows

### 5.1 End-to-End Deployment Flow

```mermaid
graph TB
    START[Start Deployment] --> CREATE_PROJ[Create Project in Coolify]
    CREATE_PROJ --> CHOOSE_SOURCE{Choose Source}
    
    CHOOSE_SOURCE -->|Git Repository| GIT_CONFIG[Configure Git Repository]
    CHOOSE_SOURCE -->|Docker Image| DOCKER_CONFIG[Configure Docker Image]
    CHOOSE_SOURCE -->|Dockerfile| DOCKERFILE_CONFIG[Configure Dockerfile]
    
    GIT_CONFIG --> BUILD_SETTINGS[Configure Build Settings]
    DOCKER_CONFIG --> BUILD_SETTINGS
    DOCKERFILE_CONFIG --> BUILD_SETTINGS
    
    BUILD_SETTINGS --> ENV_VARS[Set Environment Variables]
    ENV_VARS --> DOMAIN[Configure Domain/Port]
    DOMAIN --> DEPLOY[Click Deploy]
    
    DEPLOY --> BUILD_PROCESS[Build Process]
    BUILD_PROCESS --> DOCKER_IMAGE[Create Docker Image]
    DOCKER_IMAGE --> START_CONTAINER[Start Container]
    START_CONTAINER --> PROXY_CONFIG[Configure Traefik Proxy]
    PROXY_CONFIG --> HEALTH_CHECK{Health Check}
    
    HEALTH_CHECK -->|Pass| SUCCESS[Deployment Successful ✓]
    HEALTH_CHECK -->|Fail| ROLLBACK[Rollback to Previous]
    ROLLBACK --> DEBUG[Check Logs & Debug]
    DEBUG --> DEPLOY
    
    SUCCESS --> MONITOR[Monitor Application]
    
    style START fill:#e3f2fd
    style SUCCESS fill:#c8e6c9
    style ROLLBACK fill:#ffcdd2
    style DEPLOY fill:#fff9c4
```

### 5.2 Deployment Methods Comparison

```mermaid
graph TB
    subgraph "Deployment Methods"
        direction LR
        
        subgraph "1. Git-Based Deployment"
            G1[Push to Git] --> G2[Webhook Triggers]
            G2 --> G3[Coolify Pulls Code]
            G3 --> G4[Build Image]
            G4 --> G5[Deploy Container]
        end
        
        subgraph "2. Docker Image Deployment"
            D1[Pre-built Image] --> D2[Pull from Registry]
            D2 --> D3[Deploy Container]
        end
        
        subgraph "3. Dockerfile Deployment"
            F1[Upload Dockerfile] --> F2[Build Locally]
            F2 --> F3[Deploy Container]
        end
    end
```

**Comparison Table:**

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| **Git-Based** | Continuous deployment | Automatic updates, version control | Requires build time |
| **Docker Image** | Production, microservices | Fast deployment, consistent | Manual versioning |
| **Dockerfile** | Custom builds | Full control, optimizable | Complex setup |

### 5.3 Application Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created: Create Application
    Created --> Configuring: Add Settings
    Configuring --> Building: Click Deploy
    Building --> Deploying: Build Success
    Building --> Failed: Build Error
    Deploying --> Running: Deploy Success
    Deploying --> Failed: Deploy Error
    Running --> Updating: New Deployment
    Running --> Stopped: Stop Application
    Stopped --> Running: Start Application
    Updating --> Running: Update Success
    Updating --> Failed: Update Error
    Failed --> Configuring: Fix & Retry
    Running --> [*]: Delete Application
    
    note right of Building
        Downloading code
        Installing dependencies
        Creating Docker image
    end note
    
    note right of Running
        Container is active
        Accessible via domain/port
        健康監視中
    end note
```

---

## 6. Practical Examples

### 6.1 Example 1: Deploy a Simple Node.js Application

#### Application Architecture

```mermaid
graph LR
    subgraph "Simple Node.js App"
        USER[User Browser] -->|HTTP Request| TRAEFIK[Traefik Proxy]
        TRAEFIK -->|Forward| NODE[Node.js App<br/>Express Server]
        NODE -->|Response| TRAEFIK
        TRAEFIK -->|Response| USER
    end
    
    style NODE fill:#68a063
    style TRAEFIK fill:#4caf50
```

#### Step 1: Create Sample Application

Create a simple Express.js app on your local machine:

**File: `package.json`**
```json
{
  "name": "coolify-demo-app",
  "version": "1.0.0",
  "description": "Simple Node.js app for Coolify",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

**File: `server.js`**
```javascript
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>Coolify Demo</title></head>
      <body style="font-family: Arial; text-align: center; padding: 50px;">
        <h1>🚀 Hello from Coolify!</h1>
        <p>This app is deployed on: ${process.env.HOSTNAME || 'localhost'}</p>
        <p>Environment: ${process.env.NODE_ENV || 'development'}</p>
        <p>Time: ${new Date().toISOString()}</p>
      </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**File: `Dockerfile`**
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

**File: `.dockerignore`**
```
node_modules
npm-debug.log
.git
.gitignore
README.md
```

#### Step 2: Push to Git Repository

```bash
# Initialize git repository
git init
git add .
git commit -m "Initial commit: Simple Node.js app"

# Push to GitHub (create repo first on GitHub)
git remote add origin https://github.com/yourusername/coolify-demo-app.git
git branch -M main
git push -u origin main
```

#### Step 3: Deploy in Coolify

```mermaid
sequenceDiagram
    participant You
    participant Coolify
    participant GitHub
    participant Docker
    participant Traefik
    
    You->>Coolify: Create New Project
    You->>Coolify: Add New Application
    You->>Coolify: Select "Public Repository"
    You->>Coolify: Enter Git URL
    Coolify->>GitHub: Fetch Repository Info
    You->>Coolify: Configure Build Settings
    You->>Coolify: Set Port: 3000
    You->>Coolify: Click "Deploy"
    Coolify->>GitHub: Clone Repository
    Coolify->>Docker: Build Image
    Docker->>Coolify: Image Built
    Coolify->>Docker: Start Container
    Docker->>Coolify: Container Running
    Coolify->>Traefik: Configure Proxy
    Traefik->>You: Application Live!
```

**Detailed Steps in Coolify UI:**

1. **Dashboard** → **Projects** → **+ New Project**
   - Name: `Learning Projects`
   - Description: `My learning deployments`

2. **+ New** → **Application** → **Public Repository**

3. **Configure Application**:
   - **Git Repository**: `https://github.com/yourusername/coolify-demo-app`
   - **Branch**: `main`
   - **Build Pack**: `nixpacks` (auto-detected) or `Dockerfile`
   - **Port**: `3000`
   - **Name**: `demo-node-app`

4. **Environment Variables** (optional):
   - `NODE_ENV`: `production`

5. **Domain Configuration**:
   - Option A: Use generated domain: `http://<random-hash>.<vm-ip>.sslip.io`
   - Option B: Custom domain: `demo-app.local` (add to hosts file)
   - Option C: Use IP and port: `http://<vm-ip>:<assigned-port>`

6. **Click "Deploy"**

7. **Monitor Deployment** in real-time:
   - Watch build logs
   - See Docker commands being executed
   - Wait for "Deployment successful" message

8. **Access Application**:
   - Visit configured domain
   - Or visit IP:port combination

#### Step 4: Deployment Flow Diagram

```mermaid
graph TB
    START[Click Deploy in Coolify] --> CLONE[Clone Git Repository]
    CLONE --> DETECT[Detect Build Method]
    DETECT --> BUILD[Build Docker Image]
    BUILD --> TEST[Test Container Start]
    TEST --> SUCCESS{Success?}
    
    SUCCESS -->|Yes| TAG[Tag Image]
    SUCCESS -->|No| ERROR[Show Error Logs]
    
    TAG --> START_CONT[Start Container]
    START_CONT --> NETWORK[Connect to Network]
    NETWORK --> PROXY[Configure Traefik Routes]
    PROXY --> HEALTH[Health Check]
    HEALTH --> LIVE[Application Live! 🎉]
    
    ERROR --> FIX[Fix Issues]
    FIX --> START
    
    style START fill:#fff9c4
    style LIVE fill:#c8e6c9
    style ERROR fill:#ffcdd2
```

### 6.2 Example 2: Full-Stack Application with Database

#### Application Architecture

```mermaid
graph TB
    subgraph "Full-Stack Architecture"
        USER[Users] -->|HTTPS| TRAEFIK[Traefik Reverse Proxy]
        
        TRAEFIK -->|/| FRONTEND[Frontend<br/>React/Vue/Angular]
        TRAEFIK -->|/api| BACKEND[Backend API<br/>Node.js/Python/Go]
        
        BACKEND -->|SQL Queries| POSTGRES[(PostgreSQL<br/>Database)]
        BACKEND -->|Cache| REDIS[(Redis<br/>Cache)]
        
        POSTGRES -.->|Backup| BACKUP[Backup Storage]
        
        subgraph "Docker Network"
            FRONTEND
            BACKEND
            POSTGRES
            REDIS
        end
    end
    
    style TRAEFIK fill:#4caf50
    style FRONTEND fill:#61dafb
    style BACKEND fill:#ff9800
    style POSTGRES fill:#336791
    style REDIS fill:#dc382d
```

#### Step 1: Prepare Full-Stack Application

**Backend API (Node.js + Express + PostgreSQL)**

**File: `backend/package.json`**
```json
{
  "name": "fullstack-backend",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.0",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3"
  }
}
```

**File: `backend/index.js`**
```javascript
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 5000;

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

app.use(cors());
app.use(express.json());

// Initialize database
pool.query(`
  CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )
`).then(() => console.log('Database initialized'));

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', database: 'connected' });
});

app.get('/api/tasks', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM tasks ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/tasks', async (req, res) => {
  try {
    const { title } = req.body;
    const result = await pool.query(
      'INSERT INTO tasks (title) VALUES ($1) RETURNING *',
      [title]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/tasks/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM tasks WHERE id = $1', [req.params.id]);
    res.json({ message: 'Task deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Backend API running on port ${PORT}`);
});
```

**File: `backend/Dockerfile`**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
```

#### Step 2: Deploy Database First

1. **In Coolify Dashboard** → **Projects** → `Learning Projects` → **+ New** → **Database** → **PostgreSQL**

2. **Configure PostgreSQL**:
   - **Name**: `task-db`
   - **Database Name**: `tasks`
   - **Username**: `taskuser`
   - **Password**: (auto-generated or custom)
   - **Version**: `15` (latest stable)

3. **Deploy Database** → Wait for "Running" status

4. **Copy Connection Details**:
   - Internal URL: `postgresql://taskuser:password@task-db:5432/tasks`
   - Save this for backend configuration

#### Step 3: Deploy Backend API

```mermaid
sequenceDiagram
    participant You
    participant Coolify
    participant Docker
    participant PostgreSQL
    
    You->>Coolify: Create New Application (Backend)
    You->>Coolify: Configure Git Repository
    You->>Coolify: Add Environment Variable<br/>DATABASE_URL
    Coolify->>Docker: Build Backend Image
    Docker->>Coolify: Image Ready
    Coolify->>Docker: Start Backend Container
    Docker->>PostgreSQL: Test Connection
    PostgreSQL->>Docker: Connection Success
    Coolify->>You: Backend Deployed
```

1. **+ New** → **Application** → **Public Repository**

2. **Configure**:
   - **Repository**: Your backend repo URL
   - **Build Pack**: `Dockerfile`
   - **Port**: `5000`
   - **Name**: `task-backend`

3. **Environment Variables**:
   ```
   DATABASE_URL=postgresql://taskuser:password@task-db:5432/tasks
   PORT=5000
   NODE_ENV=production
   ```

4. **Domain**: `task-api.coolify.local` (or use generated)

5. **Deploy** → Monitor logs

#### Step 4: Complete Stack Visualization

```mermaid
graph TB
    subgraph "Deployed Stack in Coolify"
        subgraph "Load Balancer"
            ENTRY[Entry Point<br/>Your VM IP]
        end
        
        subgraph "Traefik Proxy Layer"
            TRAEFIK[Traefik]
        end
        
        subgraph "Application Layer"
            BACKEND[Backend API Container<br/>task-backend:5000]
        end
        
        subgraph "Data Layer"
            POSTGRES[(PostgreSQL Container<br/>task-db:5432)]
            VOLUME[Persistent Volume]
        end
        
        ENTRY --> TRAEFIK
        TRAEFIK -->|task-api.coolify.local| BACKEND
        BACKEND -->|Internal Network| POSTGRES
        POSTGRES -.->|Data Persistence| VOLUME
    end
    
    INTERNET[Internet / Your Browser] --> ENTRY
    
    style TRAEFIK fill:#4caf50
    style BACKEND fill:#ff9800
    style POSTGRES fill:#336791
    style VOLUME fill:#607d8b
```

### 6.3 Example 3: Multi-Service Application (Microservices)

#### Microservices Architecture

```mermaid
graph TB
    subgraph "Microservices Architecture"
        USER[Users] -->|HTTPS| GATEWAY[API Gateway<br/>Traefik]
        
        GATEWAY -->|/users| USER_SVC[User Service<br/>Port 3001]
        GATEWAY -->|/products| PROD_SVC[Product Service<br/>Port 3002]
        GATEWAY -->|/orders| ORDER_SVC[Order Service<br/>Port 3003]
        
        USER_SVC --> USER_DB[(Users DB<br/>PostgreSQL)]
        PROD_SVC --> PROD_DB[(Products DB<br/>PostgreSQL)]
        ORDER_SVC --> ORDER_DB[(Orders DB<br/>PostgreSQL)]
        
        ORDER_SVC -.->|Message Queue| RABBITMQ[RabbitMQ]
        RABBITMQ -.->|Events| NOTIFICATION[Notification Service]
        
        USER_SVC -.->|Cache| REDIS[(Redis Cache)]
        PROD_SVC -.->|Cache| REDIS
        
        subgraph "Service Mesh"
            USER_SVC
            PROD_SVC
            ORDER_SVC
            NOTIFICATION
        end
        
        subgraph "Data Layer"
            USER_DB
            PROD_DB
            ORDER_DB
            REDIS
            RABBITMQ
        end
    end
    
    style GATEWAY fill:#4caf50
    style USER_SVC fill:#2196f3
    style PROD_SVC fill:#ff9800
    style ORDER_SVC fill:#9c27b0
```

#### Deployment Strategy

1. **Deploy Shared Services First**:
   - Redis (caching)
   - RabbitMQ (message queue)

2. **Deploy Databases**:
   - PostgreSQL for each service (or shared with multiple databases)

3. **Deploy Microservices**:
   - User Service
   - Product Service
   - Order Service
   - Notification Service

4. **Configure Service Discovery**:
   - Each service communicates via internal Docker network
   - Use service names as hostnames

```mermaid
sequenceDiagram
    participant Order Service
    participant RabbitMQ
    participant Notification Service
    participant User Service
    
    Order Service->>RabbitMQ: Publish "OrderCreated" Event
    RabbitMQ->>Notification Service: Consume Event
    Notification Service->>User Service: Get User Details
    User Service->>Notification Service: Return User Info
    Notification Service->>Notification Service: Send Email/SMS
```

### 6.4 Example 4: Static Website Deployment

For simple static sites (HTML, CSS, JS):

**File: `index.html`**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Static Site</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to My Static Site</h1>
        <p>Deployed with Coolify!</p>
    </div>
</body>
</html>
```

**File: `Dockerfile`**
```dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Deploy using Coolify with Dockerfile option - simple and fast!

---

## 7. Advanced Topics

### 7.1 Environment Management

```mermaid
graph LR
    subgraph "Environment Strategy"
        DEV[Development<br/>Environment]
        STAGE[Staging<br/>Environment]
        PROD[Production<br/>Environment]
        
        DEV -->|Promote| STAGE
        STAGE -->|Promote| PROD
        
        DEV -.->|Different Config| DEVDB[(Dev DB)]
        STAGE -.->|Different Config| STAGEDB[(Stage DB)]
        PROD -.->|Different Config| PRODDB[(Prod DB)]
    end
    
    style DEV fill:#4caf50
    style STAGE fill:#ff9800
    style PROD fill:#f44336
```

**Best Practices:**

| Environment | Use Case | Configuration |
|-------------|----------|---------------|
| **Development** | Active development, debugging | Debug mode ON, verbose logging |
| **Staging** | Testing, QA, client demos | Mirror production, test data |
| **Production** | Live users | Optimized, secure, monitored |

### 7.2 CI/CD Integration

```mermaid
graph LR
    subgraph "CI/CD Pipeline"
        PUSH[Git Push] --> CI[CI Service<br/>GitHub Actions]
        CI --> TEST[Run Tests]
        TEST --> BUILD[Build Docker Image]
        BUILD --> PUSH_REG[Push to Registry]
        PUSH_REG --> WEBHOOK[Trigger Coolify Webhook]
        WEBHOOK --> COOLIFY[Coolify Auto-Deploy]
        COOLIFY --> LIVE[Application Updated]
    end
    
    TEST -.->|Failed| NOTIFY[Notify Developer]
    
    style PUSH fill:#e3f2fd
    style TEST fill:#fff9c4
    style LIVE fill:#c8e6c9
    style NOTIFY fill:#ffcdd2
```

**GitHub Actions Example:**

```yaml
name: Deploy to Coolify

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Trigger Coolify Deployment
        run: |
          curl -X POST ${{ secrets.COOLIFY_WEBHOOK_URL }}
```

### 7.3 Monitoring and Logging

```mermaid
graph TB
    subgraph "Monitoring Stack"
        APP[Your Application]
        
        APP -->|Logs| LOGS[Docker Logs]
        APP -->|Metrics| METRICS[Application Metrics]
        
        LOGS --> VIEWER[Log Viewer<br/>Coolify UI]
        METRICS --> DASHBOARD[Metrics Dashboard]
        
        ALERTS[Alert Rules] -.->|Trigger| NOTIFICATION[Notifications<br/>Email/Slack/Discord]
    end
    
    style APP fill:#2196f3
    style LOGS fill:#ff9800
    style METRICS fill:#4caf50
    style NOTIFICATION fill:#f44336
```

**Accessing Logs in Coolify:**

1. Dashboard → Your Application → **Logs** tab
2. Real-time log streaming
3. Historical logs (last N lines)
4. Download logs for analysis

**Log Management Best Practices:**

```javascript
// Structured logging example
const logger = {
  info: (message, meta) => console.log(JSON.stringify({
    level: 'info',
    message,
    timestamp: new Date().toISOString(),
    ...meta
  })),
  error: (message, error, meta) => console.error(JSON.stringify({
    level: 'error',
    message,
    error: error.message,
    stack: error.stack,
    timestamp: new Date().toISOString(),
    ...meta
  }))
};

// Usage
logger.info('User logged in', { userId: 123 });
logger.error('Database connection failed', error, { retry: 3 });
```

### 7.4 Scaling Applications

```mermaid
graph TB
    subgraph "Scaling Strategies"
        direction TB
        
        subgraph "Vertical Scaling"
            V1[2 CPU, 4GB RAM] --> V2[4 CPU, 8GB RAM]
            V2 --> V3[8 CPU, 16GB RAM]
        end
        
        subgraph "Horizontal Scaling"
            H1[App Instance 1]
            H2[App Instance 2]
            H3[App Instance 3]
            LB[Load Balancer]
            
            LB --> H1
            LB --> H2
            LB --> H3
        end
    end
    
    style V3 fill:#4caf50
    style LB fill:#ff9800
```

**Coolify Scaling:**

Currently, Coolify focuses on single-instance deployments. For horizontal scaling:

1. **Option A**: Deploy multiple separate applications with different names
2. **Option B**: Use external load balancer (Nginx, HAProxy) pointing to multiple Coolify apps
3. **Option C**: Use Coolify's upcoming "replicas" feature (check latest version)

### 7.5 Backup and Disaster Recovery

```mermaid
graph LR
    subgraph "Backup Strategy"
        APP[Application] --> DATA[Application Data]
        DB[(Database)] --> DB_DATA[Database Data]
        
        DATA --> BACKUP1[Daily Backups]
        DB_DATA --> BACKUP2[Automated DB Backups]
        
        BACKUP1 --> STORAGE[Backup Storage<br/>Local/S3/Cloud]
        BACKUP2 --> STORAGE
        
        STORAGE -.->|Restore| RECOVERY[Disaster Recovery]
    end
    
    style BACKUP1 fill:#4caf50
    style BACKUP2 fill:#2196f3
    style STORAGE fill:#ff9800
```

**Database Backup in Coolify:**

1. Go to Database → **Backups** tab
2. Configure automated backups:
   - Frequency: Daily, Weekly
   - Retention: 7 days, 30 days
   - Storage: Local or S3-compatible

**Manual Backup:**

```bash
# Backup PostgreSQL database
docker exec task-db pg_dump -U taskuser tasks > backup.sql

# Restore
docker exec -i task-db psql -U taskuser tasks < backup.sql
```

### 7.6 Security Best Practices

```mermaid
graph TB
    subgraph "Security Layers"
        NETWORK[Network Security]
        TRANSPORT[Transport Security]
        AUTH[Authentication]
        AUTHZ[Authorization]
        DATA[Data Security]
        
        NETWORK --> FIREWALL[Firewall Rules]
        TRANSPORT --> SSL[SSL/TLS Certificates]
        AUTH --> JWT[JWT Tokens / OAuth]
        AUTHZ --> RBAC[Role-Based Access]
        DATA --> ENCRYPT[Encryption at Rest]
    end
    
    style NETWORK fill:#f44336
    style TRANSPORT fill:#ff9800
    style AUTH fill:#ffc107
    style AUTHZ fill:#4caf50
    style DATA fill:#2196f3
```

**Security Checklist:**

- [ ] **SSL/TLS**: Always use HTTPS (Coolify provides Let's Encrypt)
- [ ] **Environment Variables**: Never commit secrets to Git
- [ ] **Database**: Use strong passwords, limit access
- [ ] **Firewall**: Only open necessary ports
- [ ] **Updates**: Keep Coolify, Docker, and OS updated
- [ ] **Backups**: Regular automated backups
- [ ] **Monitoring**: Set up alerts for suspicious activity
- [ ] **Access Control**: Use SSH keys, disable root login

**Coolify SSL Configuration:**

1. Application → **Domains** tab
2. Add your domain name
3. Enable "Auto-generate SSL Certificate"
4. Coolify automatically gets Let's Encrypt certificate

---

## 8. Troubleshooting and Best Practices

### 8.1 Common Issues and Solutions

```mermaid
graph TB
    subgraph "Troubleshooting Flow"
        ISSUE[Deployment Failed] --> CHECK1{Build Failed?}
        CHECK1 -->|Yes| LOGS1[Check Build Logs]
        CHECK1 -->|No| CHECK2{Container Crashed?}
        
        LOGS1 --> FIX1[Fix Dockerfile/Dependencies]
        
        CHECK2 -->|Yes| LOGS2[Check Container Logs]
        LOGS2 --> FIX2[Fix Application Error]
        
        CHECK2 -->|No| CHECK3{Port Conflict?}
        CHECK3 -->|Yes| FIX3[Change Port Configuration]
        CHECK3 -->|No| CHECK4{Resource Issue?}
        
        CHECK4 -->|Yes| FIX4[Increase VM Resources]
        CHECK4 -->|No| SUPPORT[Check Coolify Discord/Docs]
        
        FIX1 --> RETRY[Retry Deployment]
        FIX2 --> RETRY
        FIX3 --> RETRY
        FIX4 --> RETRY
    end
    
    style ISSUE fill:#ffcdd2
    style RETRY fill:#c8e6c9
```

| Problem | Symptoms | Solution |
|---------|----------|----------|
| **Build Fails** | Error during image build | Check Dockerfile syntax, dependencies |
| **Container Won't Start** | Container exits immediately | Check application logs, environment variables |
| **Can't Access App** | Domain not resolving | Check Traefik configuration, DNS settings |
| **Database Connection** | Connection refused | Verify DATABASE_URL, network connectivity |
| **Out of Memory** | Container killed, OOM errors | Increase VM RAM or optimize application |
| **Port Already in Use** | Bind error | Change application port or stop conflicting service |

### 8.2 Debugging Techniques

#### Technique 1: Check Coolify Logs

```bash
# Coolify application logs
docker logs coolify -f

# Traefik proxy logs
docker logs coolify-proxy -f

# Specific application logs
docker logs <container-name> -f
```

#### Technique 2: Access Container Shell

```bash
# List running containers
docker ps

# Access container shell
docker exec -it <container-name> sh

# Inside container, check:
ls -la                    # Files
env                       # Environment variables
netstat -tulpn           # Network ports
ps aux                   # Running processes
```

#### Technique 3: Network Debugging

```bash
# Check Docker networks
docker network ls

# Inspect network
docker network inspect coolify

# Test connectivity between containers
docker exec <container-1> ping <container-2>

# Test from host to container
curl http://localhost:<port>
```

### 8.3 Performance Optimization

```mermaid
graph LR
    subgraph "Optimization Areas"
        BUILD[Build Optimization]
        RUNTIME[Runtime Optimization]
        NETWORK[Network Optimization]
        DATA[Data Optimization]
        
        BUILD --> CACHE[Use Build Cache]
        BUILD --> LAYERS[Minimize Layers]
        
        RUNTIME --> RESOURCES[Right-size Resources]
        RUNTIME --> PROCESSES[Optimize Processes]
        
        NETWORK --> CDN[Use CDN for Static Assets]
        NETWORK --> COMPRESS[Enable Compression]
        
        DATA --> REDIS_CACHE[Implement Caching]
        DATA --> INDEXES[Database Indexes]
    end
    
    style BUILD fill:#4caf50
    style RUNTIME fill:#2196f3
    style NETWORK fill:#ff9800
    style DATA fill:#9c27b0
```

**Dockerfile Optimization:**

```dockerfile
# ❌ Bad: Installing each dependency separately
FROM node:18-alpine
COPY package.json .
RUN npm install express
RUN npm install pg
RUN npm install cors
COPY . .

# ✅ Good: Leveraging cache and minimizing layers
FROM node:18-alpine
WORKDIR /app
# Install dependencies first (cached if package.json unchanged)
COPY package*.json ./
RUN npm ci --production
# Copy application code after
COPY . .
# Use non-root user
USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

### 8.4 Best Practices Checklist

#### Development Best Practices

- [ ] Use `.dockerignore` to exclude unnecessary files
- [ ] Implement health check endpoints (`/health`, `/ready`)
- [ ] Use environment variables for configuration
- [ ] Implement structured logging (JSON format)
- [ ] Version your Docker images with Git tags
- [ ] Write meaningful commit messages
- [ ] Test locally with Docker before deploying

#### Deployment Best Practices

- [ ] Use separate environments (dev, staging, prod)
- [ ] Never deploy directly to production from local machine
- [ ] Implement automated testing in CI pipeline
- [ ] Use database migrations (not manual SQL)
- [ ] Set resource limits for containers
- [ ] Implement graceful shutdown handling
- [ ] Use health checks for deployment verification

#### Security Best Practices

- [ ] Store secrets in environment variables, not code
- [ ] Use HTTPS/SSL for all public endpoints
- [ ] Regularly update dependencies (security patches)
- [ ] Implement rate limiting and DDoS protection
- [ ] Use strong database passwords
- [ ] Enable firewall on VM
- [ ] Regular backups with tested restore procedures
- [ ] Monitor application logs for anomalies

#### Operational Best Practices

- [ ] Set up monitoring and alerting
- [ ] Document your deployment process
- [ ] Create runbooks for common issues
- [ ] Implement log rotation to save disk space
- [ ] Regular VM maintenance and updates
- [ ] Capacity planning for growth
- [ ] Disaster recovery plan and testing

### 8.5 Learning Path and Resources

```mermaid
graph TB
    START[Start: Basic Concepts] --> STAGE1[Stage 1: VM Setup & Coolify]
    STAGE1 --> STAGE2[Stage 2: Simple Deployments]
    STAGE2 --> STAGE3[Stage 3: Database Integration]
    STAGE3 --> STAGE4[Stage 4: Full-Stack Apps]
    STAGE4 --> STAGE5[Stage 5: Microservices]
    STAGE5 --> STAGE6[Stage 6: CI/CD & Automation]
    STAGE6 --> ADVANCED[Advanced: Scaling & Optimization]
    
    style START fill:#e3f2fd
    style STAGE1 fill:#bbdefb
    style STAGE2 fill:#90caf9
    style STAGE3 fill:#64b5f6
    style STAGE4 fill:#42a5f5
    style STAGE5 fill:#2196f3
    style STAGE6 fill:#1e88e5
    style ADVANCED fill:#1565c0
```

**Recommended Learning Timeline:**

| Week | Focus | Projects |
|------|-------|----------|
| **1** | VM setup, Docker basics, Coolify installation | Get environment working |
| **2** | Deploy static site, simple Node.js app | Practice git-based deployments |
| **3** | Database integration, environment variables | Todo app with PostgreSQL |
| **4** | Full-stack application | Frontend + Backend + DB |
| **5** | Multiple services, microservices basics | 2-3 connected services |
| **6** | CI/CD, monitoring, backups | Automated deployment pipeline |
| **7** | Performance, scaling, optimization | Optimize existing projects |
| **8** | Security, production readiness | Production-ready deployment |

**Resources:**

- **Coolify Documentation**: [https://coolify.io/docs](https://coolify.io/docs)
- **Docker Documentation**: [https://docs.docker.com/](https://docs.docker.com/)
- **Coolify Discord**: Community support and discussions
- **YouTube**: Search for "Coolify deployment tutorial"
- **GitHub**: Explore example applications

### 8.6 Practice Exercises

#### Exercise 1: Deploy Your Portfolio
Create a personal portfolio website (HTML/CSS/JS) and deploy it with Coolify.

**Requirements:**
- Custom domain (use `.local` with hosts file)
- SSL certificate
- Contact form that sends to an API
- Analytics integration

#### Exercise 2: Build a REST API
Create a simple REST API with CRUD operations.

**Tech Stack:**
- Backend: Node.js/Express or Python/Flask
- Database: PostgreSQL
- Cache: Redis (optional)

**Requirements:**
- Database migrations
- Environment-based configuration
- Input validation
- Error handling
- API documentation (Swagger/OpenAPI)

#### Exercise 3: Full-Stack Blog Platform
Build a complete blog application.

**Features:**
- User authentication (JWT)
- Create, read, update, delete posts
- Comment system
- Image uploads
- Search functionality

**Deployment:**
- Separate frontend and backend deployments
- PostgreSQL database
- Redis for session management
- File storage for images

#### Exercise 4: Microservices E-commerce
Create a simplified e-commerce system with microservices.

**Services:**
- User service (authentication, profiles)
- Product service (catalog, inventory)
- Order service (cart, checkout)
- Notification service (emails)

**Infrastructure:**
- Message queue (RabbitMQ or Redis)
- API Gateway pattern
- Service-to-service communication
- Shared database or separate databases

---

## 9. Conclusion and Next Steps

Congratulations! You now have a comprehensive understanding of web application deployment using Coolify.

### 9.1 What You've Learned

```mermaid
mindmap
  root((Deployment<br/>Mastery))
    Fundamentals
      Deployment Concepts
      Infrastructure Basics
      Docker Essentials
    Coolify Platform
      Installation
      Configuration
      Management
    Deployment Workflows
      Git-based
      Docker Images
      CI/CD Integration
    Architecture Patterns
      Monolithic
      Full-Stack
      Microservices
    Best Practices
      Security
      Performance
      Monitoring
      Troubleshooting
```

### 9.2 Real-World Applications

You can now:

1. **Deploy Production Applications**: Move beyond learning to real projects
2. **Understand DevOps**: Bridge development and operations
3. **Debug Deployment Issues**: Troubleshoot problems confidently
4. **Architect for Deployment**: Design apps with deployment in mind
5. **Scale Applications**: Understand scaling strategies and limitations

### 9.3 Next Steps

```mermaid
graph LR
    CURRENT[Current: Coolify on VM] --> NEXT1[Kubernetes Basics]
    CURRENT --> NEXT2[Cloud Platforms<br/>AWS/GCP/Azure]
    CURRENT --> NEXT3[Advanced Docker<br/>Docker Swarm]
    CURRENT --> NEXT4[Serverless<br/>Functions]
    
    NEXT1 --> ADVANCED[Advanced<br/>DevOps]
    NEXT2 --> ADVANCED
    NEXT3 --> ADVANCED
    NEXT4 --> ADVANCED
    
    style CURRENT fill:#4caf50
    style ADVANCED fill:#2196f3
```

**Progression Path:**

1. **Master Coolify**: Practice with diverse applications
2. **Learn Kubernetes**: Industry-standard orchestration
3. **Explore Cloud Platforms**: AWS ECS, Azure Container Apps, Google Cloud Run
4. **Advanced Monitoring**: Prometheus, Grafana, ELK Stack
5. **Infrastructure as Code**: Terraform, Ansible
6. **Advanced Security**: Container scanning, secret management

### 9.4 Final Tips

> [!IMPORTANT]
> - **Practice regularly**: Deploy something weekly
> - **Document everything**: Your future self will thank you
> - **Join communities**: Coolify Discord, Reddit r/selfhosted
> - **Experiment fearlessly**: VMs are safe sandboxes
> - **Build real projects**: Best learning comes from solving real problems

### 9.5 Quick Reference Commands

```bash
# Coolify management
docker ps                              # List all containers
docker logs coolify -f                 # View Coolify logs
docker restart coolify                 # Restart Coolify

# Application debugging
docker logs <app-container> -f         # View app logs
docker exec -it <container> sh         # Access container shell
docker stats                           # Resource usage

# Database access
docker exec -it <db-container> psql -U username dbname

# System maintenance
docker system prune -a                 # Clean up unused resources
docker volume prune                    # Remove unused volumes
sudo systemctl status docker           # Check Docker status

# VM maintenance
sudo apt update && sudo apt upgrade -y # Update system
df -h                                  # Check disk space
free -h                                # Check memory
htop                                   # Monitor processes
```

### 9.6 Quick Troubleshooting Guide

| Symptom | Quick Fix |
|---------|-----------|
| Can't access Coolify UI | Check `docker ps`, restart Coolify: `docker restart coolify` |
| Deployment stuck | Check build logs, verify Dockerfile syntax |
| App returns 502 | Check app container is running, verify port configuration |
| Database connection fails | Verify DATABASE_URL, check network connectivity |
| Out of disk space | Run `docker system prune -a` |
| SSL certificate issue | Ensure domain points to server, check port 80/443 open |

---

## Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| **Container** | Lightweight, isolated environment running your application |
| **Image** | Template used to create containers |
| **Volume** | Persistent storage for container data |
| **Network** | Virtual network for container communication |
| **Reverse Proxy** | Server that forwards requests to application containers |
| **CI/CD** | Continuous Integration/Continuous Deployment |
| **Orchestration** | Automated arrangement and coordination of containers |
| **Load Balancer** | Distributes traffic across multiple instances |
| **Blue-Green Deployment** | Strategy using two identical environments |
| **Canary Deployment** | Gradual rollout to subset of users |

### B. Port Reference

| Service | Default Port | Purpose |
|---------|--------------|---------|
| Coolify UI | 8000 | Web interface |
| HTTP | 80 | Web traffic |
| HTTPS | 443 | Secure web traffic |
| SSH | 22 | Remote access |
| PostgreSQL | 5432 | Database |
| MySQL | 3306 | Database |
| MongoDB | 27017 | Database |
| Redis | 6379 | Cache/Queue |
| Traefik Dashboard | 8080 | Proxy management |

### C. Environment Variable Examples

```bash
# Database connections
DATABASE_URL=postgresql://user:pass@host:5432/dbname
MYSQL_URL=mysql://user:pass@host:3306/dbname
MONGODB_URI=mongodb://user:pass@host:27017/dbname
REDIS_URL=redis://host:6379

# Application configuration
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
API_KEY=your-secret-key

# Third-party services
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
STRIPE_SECRET_KEY=sk_test_...
SENDGRID_API_KEY=SG....

# Feature flags
ENABLE_FEATURE_X=true
MAX_UPLOAD_SIZE=10485760
```

---

**Happy Deploying! 🚀**

*Remember: The best way to learn is by doing. Start with simple projects and gradually increase complexity. Every deployment teaches you something new!*
