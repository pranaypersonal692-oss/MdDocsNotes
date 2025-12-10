# Node.js Microservices: From Scratch to Production
## Part 2: Project Setup & Building the User Service

In this part, we will scaffold our project, set up the infrastructure using Docker, and build our first microservice: the **User Service**.

### 1. Project Scaffolding

We will use a simple folder-based monorepo. Open your terminal and run:

```bash
mkdir ecommerce-microservices
cd ecommerce-microservices
git init
mkdir auth-service catalog-service order-service api-gateway
```

### 2. Infrastructure Setup (Docker Compose)

We need databases! Instead of installing Postgres and Mongo locally, we use Docker.
Create a `docker-compose.yml` file in the root `ecommerce-microservices` folder:

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Postgres for Auth & Order Service
  postgres:
    image: postgres:15-alpine
    container_name: shop_postgres
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: password123
      POSTGRES_DB: auth_db
    ports:
      - "5432:5432"
    volumes:
      - ./postgres_data:/var/lib/postgresql/data

  # MongoDB for Catalog Service
  mongo:
    image: mongo:6-alpine
    container_name: shop_mongo
    ports:
      - "27017:27017"
    volumes:
      - ./mongo_data:/data/db

  # RabbitMQ for Messaging
  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: shop_rabbitmq
    ports:
      - "5672:5672"   # Message port
      - "15672:15672" # GUI port
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
```

Run it:
```bash
docker-compose up -d
```
Check `localhost:15672` (User: guest, Pass: guest) to see RabbitMQ Dashboard.

---

### 3. Building the Auth (User) Service

The Auth Service handles registration and login. We will use **Express**, **TypeScript**, and **Prisma ORM**.

#### 3.1 Initialization
```bash
cd auth-service
npm init -y
npm install express dotenv cors helmet
npm install -D typescript ts-node @types/express @types/node nodemon prisma
npx tsc --init
```

Update `tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "es2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true
  }
}
```

#### 3.2 Prisma Setup (Database)
Initialize Prisma:
```bash
npx prisma init
```
Edit `prisma/schema.prisma`:
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  password  String
  name      String?
  createdAt DateTime @default(now())
}
```

Create `.env` inside `auth-service`:
```env
DATABASE_URL="postgresql://admin:password123@localhost:5432/auth_db?schema=public"
PORT=4001
JWT_SECRET=supersecretkey
```

Run migration to create tables:
```bash
npx prisma migrate dev --name init
```

#### 3.3 Comprehensive Folder Structure

A scalable microservice needs proper organization. Create this structure:

```text
auth-service/
├── src/
│   ├── config/
│   │   └── database.ts       # Prisma client instance
│   ├── controllers/
│   │   └── authController.ts
│   ├── routes/
│   │   └── authRoutes.ts
│   ├── services/
│   │   └── authService.ts    # Business logic
│   ├── middleware/
│   │   ├── authMiddleware.ts # JWT verification
│   │   ├── errorHandler.ts   # Global error handler
│   │   └── validator.ts      # Request validation
│   ├── utils/
│   │   ├── logger.ts         # Winston logger
│   │   └── apiResponse.ts    # Standardized responses
│   ├── types/
│   │   └── express.d.ts      # Custom type definitions
│   └── index.ts              # Entry point
├── prisma/
│   └── schema.prisma
├── .env
├── Dockerfile
├── package.json
└── tsconfig.json
```

**Why this structure?**
- **Separation of Concerns**: Controllers handle HTTP, Services handle business logic
- **Middleware**: Reusable cross-cutting concerns
- **Utils**: Shared utilities
- **Config**: Centralized configuration

#### 3.4 Updated Entry Point with Middleware

Update `src/index.ts` to include error handling and graceful shutdown:

```typescript
import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import helmet from 'helmet';
import authRoutes from './routes/authRoutes';
import { errorHandler } from './middleware/errorHandler';
import { logger } from './utils/logger';
import { prisma } from './config/database';

dotenv.config();

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request Logging
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`);
    next();
});

// Routes
app.use('/auth', authRoutes);

// 404 Handler
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// Global Error Handler (must be last)
app.use(errorHandler);

const PORT = process.env.PORT || 4001;

const server = app.listen(PORT, () => {
    logger.info(`Auth Service running on port ${PORT}`);
});

// Graceful Shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM signal received: closing HTTP server');
    server.close(async () => {
        await prisma.$disconnect();
        logger.info('HTTP server closed');
        process.exit(0);
    });
});

process.on('SIGINT', async () => {
    logger.info('SIGINT signal received: closing HTTP server');
    server.close(async () => {
        await prisma.$disconnect();
        logger.info('HTTP server closed');
        process.exit(0);
    });
});
```

> [!IMPORTANT]
> **Graceful Shutdown** ensures that:
> 1. Active requests complete before termination
> 2. Database connections close properly
> 3. No data corruption occurs during deployment

#### 3.5 Essential Utilities & Middleware

Before implementing auth logic (Part 3), let's set up utilities for error handling and validation.

##### 3.5.1 Install Additional Dependencies
```bash
npm install joi winston
npm install -D @types/joi
```

##### 3.5.2 Error Handler Middleware

Create `src/middleware/errorHandler.ts`:
```typescript
import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

export class AppError extends Error {
    statusCode: number;
    isOperational: boolean;

    constructor(message: string, statusCode: number) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = true;
        Error.captureStackTrace(this, this.constructor);
    }
}

export const errorHandler = (
    err: AppError | Error,
    req: Request,
    res: Response,
    next: NextFunction
) => {
    const error = err as AppError;
    const statusCode = error.statusCode || 500;
    const message = error.message || 'Internal Server Error';

    logger.error({
        message: error.message,
        stack: error.stack,
        url: req.url,
        method: req.method
    });

    res.status(statusCode).json({
        success: false,
        error: message,
        ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
};
```

##### 3.5.3 Request Validator

Create `src/middleware/validator.ts`:
```typescript
import { Request, Response, NextFunction } from 'express';
import Joi from 'joi';
import { AppError } from './errorHandler';

export const validate = (schema: Joi.ObjectSchema) => {
    return (req: Request, res: Response, next: NextFunction) => {
        const { error } = schema.validate(req.body, { abortEarly: false });
        
        if (error) {
            const message = error.details.map(d => d.message).join(', ');
            throw new AppError(message, 400);
        }
        
        next();
    };
};
```

##### 3.5.4 Logger Setup

Create `src/utils/logger.ts`:
```typescript
import winston from 'winston';

export const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple()
            )
        }),
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' })
    ]
});
```

##### 3.5.5 Database Configuration

Create `src/config/database.ts`:
```typescript
import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';

export const prisma = new PrismaClient({
    log: [
        { emit: 'event', level: 'query' },
        { emit: 'event', level: 'error' },
    ],
});

prisma.$on('error', (e) => {
    logger.error('Prisma Error:', e);
});

prisma.$on('query' as any, (e: any) => {
    logger.debug(`Query: ${e.query} - Duration: ${e.duration}ms`);
});
```

##### 3.5.6 Health Check Route

Create `src/routes/authRoutes.ts`:
```typescript
import { Router } from 'express';
import { prisma } from '../config/database';

const router = Router();

router.get('/health', async (req, res) => {
    try {
        // Check database connection
        await prisma.$queryRaw`SELECT 1`;
        res.json({ 
            status: 'ok', 
            service: 'Auth Service',
            timestamp: new Date().toISOString(),
            database: 'connected'
        });
    } catch (error) {
        res.status(503).json({ 
            status: 'error', 
            service: 'Auth Service',
            database: 'disconnected'
        });
    }
});

export default router;
```

Add a `dev` script to `package.json`:
```json
"scripts": {
  "dev": "nodemon src/index.ts"
}
```

Run it: `npm run dev`.
Visit `http://localhost:4001/auth/health` -> you should see JSON.

### 4. Dockerizing the Service

Create a production-ready `Dockerfile` in `auth-service/`:

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build TypeScript
RUN npm run build

# Stage 2: Production
FROM node:18-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Copy from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/prisma ./prisma
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 4001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4001/auth/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "dist/index.js"]
```

> [!TIP]
> **Multi-stage builds** reduce image size by 70%+ by separating build dependencies from runtime.

#### 4.1 Environment Variables Best Practices

Update `.env.example` (commit this, not `.env`):
```env
# Server
NODE_ENV=development
PORT=4001
LOG_LEVEL=info

# Database
DATABASE_URL=postgresql://admin:password123@localhost:5432/auth_db?schema=public

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000
```

#### 4.2 Building and Running

Add these scripts to `package.json`:
```json
{
  "scripts": {
    "dev": "nodemon src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "docker:build": "docker build -t auth-service:latest .",
    "docker:run": "docker run -p 4001:4001 --env-file .env auth-service:latest"
  }
}
```

### 5. Testing the Service

Create a simple test to verify everything works:

```bash
# Start the service
npm run dev

# In another terminal, test the health endpoint
curl http://localhost:4001/auth/health
```

Expected response:
```json
{
  "status": "ok",
  "service": "Auth Service",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "database": "connected"
}
```

> [!NOTE]
> In Part 3, we'll implement the actual registration and login endpoints using this solid foundation.

---
**[Next: Part 3 - Implementing JWT Authentication & Security](./03-Authentication-and-Security.md)**
