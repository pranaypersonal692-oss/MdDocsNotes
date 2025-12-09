# Part 3: Docker Compose & Local Development

## Table of Contents
1. [What is Docker Compose?](#what-is-docker-compose)
2. [Compose File Structure](#compose-file-structure)
3. [Service Configuration](#service-configuration)
4. [Networks in Compose](#networks-in-compose)
5. [Volumes in Compose](#volumes-in-compose)
6. [Environment Management](#environment-management)
7. [Real-World Multi-Container Applications](#real-world-multi-container-applications)

---

## What is Docker Compose?

### The Problem

**Running multi-container apps manually:**
```bash
# Create network
docker network create app-network

# Run database
docker run -d --name db --network app-network \
  -e POSTGRES_PASSWORD=secret postgres:15

# Run cache
docker run -d --name redis --network app-network redis:7

# Run API
docker run -d --name api --network app-network \
  -e DATABASE_URL=postgresql://postgres:secret@db:5432/myapp \
  -e REDIS_URL=redis://redis:6379 \
  -p 3000:3000 myapi:latest

# Run frontend
docker run -d --name web --network app-network \
  -p 8080:80 myweb:latest

# 😫 Too many commands, hard to manage!
```

### The Solution: Docker Compose

**Single `docker-compose.yml` file:**
```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
  
  redis:
    image: redis:7
  
  api:
    image: myapi:latest
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://postgres:secret@db:5432/myapp
      REDIS_URL: redis://redis:6379
  
  web:
    image: myweb:latest
    ports:
      - "8080:80"
```

**Single command to run everything:**
```bash
docker-compose up -d
```

---

## Compose File Structure

### Basic Structure

```yaml
version: '3.8'  # Compose file format version

services:       # Define containers
  service1:
    # Service configuration
  service2:
    # Service configuration

networks:       # Define custom networks
  my-network:
    driver: bridge

volumes:        # Define named volumes
  my-data:
    driver: local
```

### Version History

| Version | Docker Engine | Key Features |
|---------|---------------|--------------|
| 3.8 | 19.03.0+ | Latest features, deploy configs |
| 3.7 | 18.06.0+ | secrets, configs top-level |
| 3.0 | 1.13.0+ | Version 3 format |
| 2.0 | 1.10.0+ | Volume, network separation |

> [!TIP]
> Use version `3.8` for modern Docker installations.

---

## Service Configuration

### Building Images

```yaml
services:
  app:
    # Build from Dockerfile in current directory
    build: .
    
  app-with-context:
    # Specify build context and Dockerfile
    build:
      context: ./app
      dockerfile: Dockerfile.prod
      args:
        NODE_ENV: production
        BUILD_VERSION: 1.2.3
    
  app-multi-target:
    # Build specific target from multi-stage Dockerfile
    build:
      context: .
      target: production
```

### Using Pre-built Images

```yaml
services:
  db:
    image: postgres:15-alpine
    
  redis:
    image: redis:7-alpine
    
  nginx:
    image: nginx:1.25-alpine
```

### Ports

```yaml
services:
  web:
    # Short syntax: HOST:CONTAINER
    ports:
      - "8080:80"          # Host 8080 → Container 80
      - "8443:443"
      - "127.0.0.1:3000:3000"  # Bind to localhost only
    
  api:
    # Long syntax (more control)
    ports:
      - target: 3000       # Container port
        published: 3000    # Host port
        protocol: tcp
        mode: host
```

### Environment Variables

```yaml
services:
  app:
    # Inline environment variables
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://db:5432/myapp
      LOG_LEVEL: info
    
  app-from-file:
    # Load from .env file
    env_file:
      - .env
      - .env.production
    
  app-mixed:
    # Combine both
    env_file: .env
    environment:
      NODE_ENV: production  # Overrides .env value
```

### Volumes

```yaml
services:
  db:
    # Named volume
    volumes:
      - postgres-data:/var/lib/postgresql/data
    
  app:
    # Bind mount (for development)
    volumes:
      - ./app:/usr/src/app        # Source code
      - /usr/src/app/node_modules # Anonymous volume for node_modules
    
  logs:
    # Read-only mount
    volumes:
      - ./config:/etc/config:ro

volumes:
  postgres-data:  # Declare named volume
```

### Depends On

```yaml
services:
  api:
    image: myapi:latest
    depends_on:
      - db
      - redis
    # api starts AFTER db and redis
    # But doesn't wait for them to be "ready"
  
  db:
    image: postgres:15
    
  redis:
    image: redis:7
```

> [!WARNING]
> `depends_on` only controls start order, not readiness! Use healthchecks for actual readiness.

### Healthchecks

```yaml
services:
  db:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    
  api:
    image: myapi:latest
    depends_on:
      db:
        condition: service_healthy  # Wait for db to be healthy!
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

### Restart Policies

```yaml
services:
  app:
    restart: always        # Always restart on stop/failure
    
  worker:
    restart: unless-stopped  # Restart unless manually stopped
    
  batch:
    restart: on-failure    # Only restart on error
    
  oneshot:
    restart: no            # Never restart (default)
```

---

## Networks in Compose

### Default Network

```yaml
# All services automatically on same network
services:
  api:
    image: myapi:latest
  db:
    image: postgres:15

# api can reach db via: http://db:5432
# Automatic DNS resolution by service name!
```

### Custom Networks

```yaml
services:
  frontend:
    image: nginx:alpine
    networks:
      - public
      - backend
  
  api:
    image: myapi:latest
    networks:
      - backend
      - database
  
  db:
    image: postgres:15
    networks:
      - database

networks:
  public:      # External-facing
  backend:     # API layer
  database:    # Data layer (isolated)
```

```mermaid
graph LR
    F[Frontend] ---|public| LB[Load Balancer]
    F ---|backend| API[API]
    API ---|database| DB[Database]
    
    style F fill:#51cf66
    style API fill:#4dabf7
    style DB fill:#ff6b6b
```

### Network Isolation Example

```yaml
services:
  # Public-facing web server
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    networks:
      - frontend
  
  # API server (backend + database networks)
  api:
    build: ./api
    networks:
      - frontend  # Can talk to web
      - backend   # Can talk to database
  
  # Database (isolated, only API can access)
  db:
    image: postgres:15
    networks:
      - backend   # Only API can reach this
    # No direct access from web!

networks:
  frontend:
  backend:
```

---

## Volumes in Compose

### Named Volumes

```yaml
services:
  db:
    image: postgres:15
    volumes:
      - postgres-data:/var/lib/postgresql/data
  
  app:
    image: myapp:latest
    volumes:
      - app-uploads:/app/uploads

volumes:
  postgres-data:        # Managed by Docker
  app-uploads:
```

**Persistence:**
```bash
# Stop containers
docker-compose down

# Volumes persist!
docker volume ls  # postgres-data still exists

# Remove volumes too
docker-compose down -v
```

### Bind Mounts (Development)

```yaml
services:
  app:
    build: .
    volumes:
      # Source code - live reload
      - ./src:/app/src
      
      # Don't override node_modules
      - /app/node_modules
      
      # Config files
      - ./config:/app/config:ro  # Read-only
```

### Volume Configuration

```yaml
volumes:
  postgres-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/data/postgres
  
  nfs-data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=nfs-server.example.com,rw
      device: ":/path/to/share"
```

---

## Environment Management

### Using .env Files

**.env file:**
```bash
# Database configuration
POSTGRES_USER=myuser
POSTGRES_PASSWORD=secret
POSTGRES_DB=myapp

# Application
NODE_ENV=development
API_PORT=3000
LOG_LEVEL=debug
```

**docker-compose.yml:**
```yaml
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
  
  api:
    build: ./api
    ports:
      - "${API_PORT}:3000"
    environment:
      NODE_ENV: ${NODE_ENV}
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
```

### Multiple Environments

```bash
# Development
docker-compose --env-file .env.dev up

# Staging
docker-compose --env-file .env.staging up

# Production
docker-compose --env-file .env.prod up
```

### Override Files

**docker-compose.yml (base):**
```yaml
services:
  app:
    image: myapp:latest
    environment:
      NODE_ENV: production
```

**docker-compose.override.yml (development):**
```yaml
services:
  app:
    build: .  # Build locally instead of using image
    volumes:
      - ./src:/app/src  # Mount source for live reload
    environment:
      NODE_ENV: development
      DEBUG: '*'
```

**Usage:**
```bash
# Development (automatically uses override)
docker-compose up

# Production (skip override)
docker-compose -f docker-compose.yml up
```

---

## Real-World Multi-Container Applications

### Example 1: Full-Stack Web Application

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

  # Redis Cache
  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - backend

  # Backend API
  api:
    build:
      context: ./api
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: ${NODE_ENV}
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      REDIS_URL: redis://redis:6379
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./api/src:/app/src  # Development: live reload
      - /app/node_modules
    restart: unless-stopped
    networks:
      - backend
      - frontend

  # Frontend (React/Next.js)
  web:
    build:
      context: ./web
      dockerfile: Dockerfile
    ports:
      - "8080:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:3000
    depends_on:
      - api
    volumes:
      - ./web/src:/app/src
      - ./web/public:/app/public
      - /app/node_modules
      - /app/.next
    restart: unless-stopped
    networks:
      - frontend

  # Nginx Reverse Proxy
  nginx:
    image: nginx:1.25-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - api
      - web
    restart: unless-stopped
    networks:
      - frontend

networks:
  frontend:
  backend:

volumes:
  postgres-data:
  redis-data:
```

### Example 2: Microservices Architecture

```yaml
version: '3.8'

services:
  # API Gateway
  gateway:
    build: ./gateway
    ports:
      - "80:80"
    environment:
      USER_SERVICE_URL: http://user-service:3001
      ORDER_SERVICE_URL: http://order-service:3002
      PRODUCT_SERVICE_URL: http://product-service:3003
    networks:
      - frontend
      - backend

  # User Service
  user-service:
    build: ./services/user
    environment:
      DATABASE_URL: postgresql://postgres:secret@user-db:5432/users
      REDIS_URL: redis://redis:6379
    depends_on:
      - user-db
      - redis
    networks:
      - backend

  user-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: users
    volumes:
      - user-db-data:/var/lib/postgresql/data
    networks:
      - backend

  # Order Service
  order-service:
    build: ./services/order
    environment:
      DATABASE_URL: postgresql://postgres:secret@order-db:5432/orders
      KAFKA_BROKERS: kafka:9092
    depends_on:
      - order-db
      - kafka
    networks:
      - backend

  order-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: orders
    volumes:
      - order-db-data:/var/lib/postgresql/data
    networks:
      - backend

  # Product Service
  product-service:
    build: ./services/product
    environment:
      MONGODB_URL: mongodb://mongo:27017/products
    depends_on:
      - mongo
    networks:
      - backend

  mongo:
    image: mongo:7
    volumes:
      - mongo-data:/data/db
    networks:
      - backend

  # Message Queue (Kafka)
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    networks:
      - backend

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    networks:
      - backend

  # Redis Cache
  redis:
    image: redis:7-alpine
    networks:
      - backend

networks:
  frontend:
  backend:

volumes:
  user-db-data:
  order-db-data:
  mongo-data:
```

### Development Workflow Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f api

# Rebuild and restart service
docker-compose up -d --build api

# Scale service (run multiple instances)
docker-compose up -d --scale worker=3

# Stop all services
docker-compose stop

# Stop and remove containers
docker-compose down

# Remove containers and volumes
docker-compose down -v

# Execute command in service
docker-compose exec api sh

# Run one-off command
docker-compose run api npm test
```

---

## Key Takeaways

> [!IMPORTANT]
> **Docker Compose Best Practices:**
> 1. Use **version 3.8** for modern features
> 2. Define **healthchecks** for service dependencies
> 3. Use **custom networks** for service isolation
> 4. Use **named volumes** for data persistence
> 5. Leverage **.env files** for environment configuration
> 6. Use **override files** for development configuration
> 7. Always specify **image versions** (not `latest`)
> 8. Use **depends_on with condition** for startup order
> 9. Configure **restart policies** for production
> 10. Test with `docker-compose config` before deploying

---

## Next Steps

In **Part 4**, we'll cover:
- Kubernetes fundamentals
- Deploying multi-container apps to production
- Service discovery and load balancing
- Rolling updates and rollbacks
- Auto-scaling

---

**Continue to:** [Part 4: Container Orchestration with Kubernetes](file:///C:/Users/phusukale/Downloads/Docs/Repo/Docker_Guide/Part4-Kubernetes-Orchestration.md)
