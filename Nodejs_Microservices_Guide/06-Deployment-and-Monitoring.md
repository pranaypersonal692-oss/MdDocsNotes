# Node.js Microservices: From Scratch to Production
## Part 6: Production Deployment, Observability & Scaling

Congratulations! You have a working set of microservices. Now, let's make it production-ready with proper deployment, monitoring, and scaling strategies.

### 1. Complete Docker Compose Setup

Create a comprehensive `docker-compose.yml` in the project root:

```yaml
version: '3.8'

services:
  # Infrastructure Services
  postgres:
    image: postgres:15-alpine
    container_name: shop_postgres
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: password123
      POSTGRES_MULTIPLE_DATABASES: auth_db,order_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/create-multiple-postgresql-databases.sh:/docker-entrypoint-initdb.d/create-databases.sh
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin"]
      interval: 10s
      timeout: 5s
      retries: 5

  mongo:
    image: mongo:6-alpine
    container_name: shop_mongo
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      retries: 5

  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: shop_rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    healthcheck:
      test: rabbitmq-diagnostics -q ping
      interval: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: shop_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      retries: 5

  # Observability Stack
  jaeger:
    image: jaegertracing/all-in-one:latest
    container_name: jaeger
    ports:
      - "5775:5775/udp"
      - "6831:6831/udp"
      - "6832:6832/udp"
      - "5778:5778"
      - "16686:16686" # UI
      - "14268:14268"
      - "9411:9411"
    environment:
      COLLECTOR_ZIPKIN_HOST_PORT: :9411

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus

  # Microservices
  auth-service:
    build: ./auth-service
    container_name: auth_service
    ports:
      - "4001:4001"
    environment:
      DATABASE_URL: postgresql://admin:password123@postgres:5432/auth_db
      JWT_SECRET: supersecretkey
      PORT: 4001
      NODE_ENV: production
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  catalog-service:
    build: ./catalog-service
    container_name: catalog_service
    ports:
      - "4002:4002"
    environment:
      MONGO_URI: mongodb://mongo:27017/catalog_db
      RABBITMQ_URL: amqp://rabbitmq:5672
      PORT: 4002
      NODE_ENV: production
    depends_on:
      mongo:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    restart: unless-stopped

  order-service:
    build: ./order-service
    container_name: order_service
    ports:
      - "4003:4003"
    environment:
      DATABASE_URL: postgresql://admin:password123@postgres:5432/order_db
      RABBITMQ_URL: amqp://rabbitmq:5672
      PORT: 4003
      NODE_ENV: production
    depends_on:
      postgres:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    restart: unless-stopped

  api-gateway:
    build: ./api-gateway
    container_name: api_gateway
    ports:
      - "8000:8000"
    environment:
      AUTH_SERVICE_URL: http://auth-service:4001
      CATALOG_SERVICE_URL: http://catalog-service:4002
      ORDER_SERVICE_URL: http://order-service:4003
      JWT_SECRET: supersecretkey
      PORT: 8000
      NODE_ENV: production
    depends_on:
      - auth-service
      - catalog-service
      - order-service
    restart: unless-stopped

  notification-service:
    build: ./notification-service
    container_name: notification_service
    environment:
      RABBITMQ_URL: amqp://rabbitmq:5672
      NODE_ENV: production
    depends_on:
      rabbitmq:
        condition: service_healthy
    restart: unless-stopped

volumes:
  postgres_data:
  mongo_data:
  rabbitmq_data:
  redis_data:
  prometheus_data:
  grafana_data:

networks:
  default:
    name: microservices_network
```

#### 1.1  Multi-Database Initialization Script

Create `scripts/create-multiple-postgresql-databases.sh`:
```bash
#!/bin/bash
set -e
set -u

function create_database() {
    local database=$1
    echo "Creating database '$database'"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE DATABASE $database;
EOSQL
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        create_database $db
    done
fi
```

---

### 2. OpenTelemetry Implementation

#### 2.1 Install Dependencies
```bash
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node
npm install @opentelemetry/exporter-jaeger
```

#### 2.2 Tracing Setup

Create `src/tracing.ts` (add to each service):
```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

const jaegerExporter = new JaegerExporter({
    endpoint: process.env.JAEGER_ENDPOINT || 'http://localhost:14268/api/traces',
});

const sdk = new NodeSDK({
    resource: new Resource({
        [SemanticResourceAttributes.SERVICE_NAME]: process.env.SERVICE_NAME || 'unknown-service',
    }),
    traceExporter: jaegerExporter,
    instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

process.on('SIGTERM', () => {
    sdk.shutdown()
        .then(() => console.log('Tracing terminated'))
        .catch((error) => console.log('Error terminating tracing', error))
        .finally(() => process.exit(0));
});

export default sdk;
```

Update `src/index.ts` to import tracing first:
```typescript
import './tracing'; // Must be first!
import express from 'express';
// ... rest of the code
```

---

### 3. Prometheus Metrics

#### 3.1 Add Metrics Endpoint

```bash
npm install prom-client
```

Create `src/utils/metrics.ts`:
```typescript
import promClient from 'prom-client';

const register = new promClient.Registry();

promClient.collectDefaultMetrics({ register });

// Custom metrics
export const httpRequestDuration = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    registers: [register]
});

export const httpRequestTotal = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code'],
    registers: [register]
});

export { register };
```

Add metrics middleware:
```typescript
import { httpRequestDuration, httpRequestTotal, register } from './utils/metrics';

app.use((req, res, next) => {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        const route = req.route?.path || req.path;
        
        httpRequestDuration.labels(req.method, route, res.statusCode.toString()).observe(duration);
        httpRequestTotal.labels(req.method, route, res.statusCode.toString()).inc();
    });
    
    next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});
```

#### 3.2 Prometheus Configuration

Create `prometheus.yml`:
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'auth-service'
    static_configs:
      - targets: ['auth-service:4001']
  
  - job_name: 'catalog-service'
    static_configs:
      - targets: ['catalog-service:4002']
  
  - job_name: 'order-service'
    static_configs:
      - targets: ['order-service:4003']
  
  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway:8000']
```

---

### 4. Kubernetes Deployment

#### 4.1 Deployment Manifest (auth-service example)

Create `k8s/auth-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  labels:
    app: auth-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth-service
        image: your-registry/auth-service:latest
        ports:
        - containerPort: 4001
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: auth-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: auth-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /auth/health
            port: 4001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /auth/health
            port: 4001
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: auth-service
spec:
  selector:
    app: auth-service
  ports:
    - protocol: TCP
      port: 80
      targetPort: 4001
  type: ClusterIP
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: auth-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: auth-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

#### 4.2 ConfigMap & Secrets

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  NODE_ENV: "production"
  LOG_LEVEL: "info"
---
apiVersion: v1
kind: Secret
metadata:
  name: auth-secrets
type: Opaque
stringData:
  database-url: "postgresql://user:pass@host:5432/db"
  jwt-secret: "your-secret-key"
```

---

### 5. Observability Dashboard Architecture

```mermaid
graph TB
    Services[Microservices]
    
    subgraph Observability Stack
        Logs[Logs → ELK/Loki]
        Metrics[Metrics → Prometheus]
        Traces[Traces → Jaeger]
    end
    
    subgraph Visualization
        Grafana[Grafana Dashboards]
        Jaeger jaegerUI[Jaeger UI]
    end
    
    subgraph Alerting
        AlertManager[Prometheus AlertManager]
        PagerDuty[PagerDuty/Slack]
    end
    
    Services --> Logs
    Services --> Metrics
    Services --> Traces
    
    Metrics --> Grafana
    Traces --> JaegerUI
    Metrics --> AlertManager
    AlertManager --> PagerDuty
```

### 6. Production Checklist

> [!IMPORTANT]
> **Pre-Production Verification**

- [ ] **Health Checks**: All services expose `/health` and `/readiness` endpoints
- [ ] **Graceful Shutdown**: Services handle SIGTERM/SIGINT properly
- [ ] **Resource Limits**: CPU/Memory limits defined in k8s
- [ ] **Secrets Management**: Using Kubernetes Secrets or Vault
- [ ] **Database Migrations**: Automated with Prisma migrate or Flyway
- [ ] **Horizontal Scaling**: HPA configured based on CPU/Memory/Custom metrics
- [ ] **Monitoring**: Prometheus + Grafana dashboards created
- [ ] **Logging**: Centralized logging (ELK/Loki) configured
- [ ] **Tracing**: OpenTelemetry + Jaeger operational
- [ ] **Backup Strategy**: Database backups automated
- [ ] **Disaster Recovery**: Multi-region deployment or backup cluster
- [ ] **Security Scan**: Container images scanned (Trivy/Snyk)
- [ ] **Load Testing**: Performed with k6/Artillery
- [ ] **CI/CD Pipeline**: Automated testing and deployment

### 7. Running the Entire System

```bash
# Development
docker-compose up -d

# Production (Kubernetes)
kubectl apply -f k8s/

# Access UIs
# Grafana: http://localhost:3000
# Jaeger: http://localhost:16686
# RabbitMQ: http://localhost:15672
# Prometheus: http://localhost:9090
```

---

## Conclusion

You've built a production-grade Node.js microservices system with:
✅ **Authentication** with JWT and refresh tokens  
✅ **Inter-service communication** with RabbitMQ  
✅ **Saga pattern** for distributed transactions  
✅ **Circuit Breaker** for resilience  
✅ **API Gateway** with service discovery  
✅ **Complete observability** with OpenTelemetry, Prometheus, and Grafana  
✅ **Production deployment** with Docker Compose and Kubernetes

**Next Steps:**
- Implement Blue-Green or Canary deployments
- Add A/B testing framework
- Implement CQRS with Event Sourcing
- Add GraphQL Federation layer
- Implement Service Mesh (Istio/Linkerd)

**Happy Building! 🚀**
