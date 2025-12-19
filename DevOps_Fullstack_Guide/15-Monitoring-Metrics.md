# Monitoring, Logging, and Observability

## Table of Contents
1. [Introduction to Observability](#introduction-to-observability)
2. [The Three Pillars of Observability](#the-three-pillars-of-observability)
3. [Monitoring Fundamentals](#monitoring-fundamentals)
4. [Prometheus and Grafana](#prometheus-and-grafana)
5. [Application Performance Monitoring](#application-performance-monitoring)
6. [Logging Best Practices](#logging-best-practices)
7. [ELK Stack](#elk-stack)
8. [Distributed Tracing](#distributed-tracing)
9. [Alerting Strategies](#alerting-strategies)
10. [Observability in Practice](#observability-in-practice)

---

## Introduction to Observability

### Monitoring vs Observability

**Monitoring:**
```
Monitoring answers: "Is everything working?"
- Predefined metrics
- Known failure modes
- Dashboards and alerts
```

**Observability:**
```
Observability answers: "Why is it not working?"
- Understand internal state from external outputs
- Explore unknown problems
- Debug complex distributed systems
```

**Analogy:**
```
Monitoring = Dashboard lights in a car
  ✓ Check engine light
  ✓ Low fuel warning
  ✓ Speed, RPM

Observability = Full diagnostics
  ✓ Why is the check engine on?
  ✓ What component is failing?
  ✓ What happened before the failure?
```

---

### Why Observability Matters

**In Microservices:**
```
Monolith:
Request → [Single App] → Response
(Easy to debug)

Microservices:
Request → [Gateway] → [Auth] → [Service A] → [Database]
                         ↓          ↓
                    [Service B] → [Cache]
                         ↓
                    [Service C] → [Queue]

(Where did it fail? Why? When?)
```

**Challenges:**
- Multiple services
- Distributed state
- Network failures
- Complex interactions

**Solution:** Comprehensive observability

---

## The Three Pillars of Observability

```
┌────────────────────────────────────────┐
│                                        │
│           OBSERVABILITY                │
│                                        │
│  ┌──────────┐  ┌──────────┐  ┌─────┐ │
│  │  Metrics │  │   Logs   │  │Trace│ │
│  │          │  │          │  │     │ │
│  │ Numbers  │  │  Events  │  │Path │ │
│  │over time │  │with ctx  │  │of   │ │
│  │          │  │          │  │req  │ │
│  └──────────┘  └──────────┘  └─────┘ │
│                                        │
└────────────────────────────────────────┘
```

---

### 1. Metrics

**What:** Numerical measurements over time

**Examples:**
```
- CPU usage: 45%
- Memory usage: 2.3 GB
- Request rate: 1000/sec
- Error rate: 0.5%
- Response time: 150ms (p95)
```

**Best For:**
- Trends over time
- Alerting on thresholds
- Dashboards
- Capacity planning

---

### 2. Logs

**What:** Discrete events with context

**Examples:**
```
2024-01-15T10:30:00Z [INFO] User logged in userId=123 ip=192.168.1.1
2024-01-15T10:30:05Z [ERROR] Database connection failed error="timeout after 30s"
2024-01-15T10:30:10Z [WARN] High memory usage current=85% threshold=80%
```

**Best For:**
- Debugging specific issues
- Audit trails
- Error investigation
- Business events

---

### 3. Traces

**What:** Request journey through distributed system

**Example:**
```
Trace ID: abc123
├─ API Gateway (20ms)
│  └─ Auth Service (50ms)
│     ├─ User Service (30ms)
│     │  └─ Database (25ms)
│     └─ Cache (5ms)
└─ Order Service (100ms)
   ├─ Inventory Service (40ms)
   │  └─ Database (35ms)
   └─ Payment Service (60ms)
      └─ External API (55ms)

Total: 120ms (with parallelization)
```

**Best For:**
- Performance optimization
- Understanding dependencies
- Finding bottlenecks
- Distributed debugging

---

## Monitoring Fundamentals

### The Four Golden Signals (Google SRE)

**1. Latency:**
```
How long does it take to serve a request?

Metrics:
- p50 (median): 100ms
- p95: 200ms
- p99: 500ms

Alert: p95 > 1000ms
```

**2. Traffic:**
```
How much demand is on your system?

Metrics:
- Requests per second: 1000/s
- Active users: 5000
- Bandwidth: 100 MB/s

Alert: Traffic drops 50% (potential outage)
```

**3. Errors:**
```
What is the rate of failing requests?

Metrics:
- Error rate: 0.5%
- 4xx errors: 10/sec
- 5xx errors: 5/sec

Alert: Error rate > 5%
```

**4. Saturation:**
```
How "full" is your service?

Metrics:
- CPU usage: 70%
- Memory usage: 80%
- Disk usage: 60%
- Connection pool: 40/50 (80% full)

Alert: CPU > 90% for 5 minutes
```

---

### USE Method (Resource-Oriented)

**For every resource:**
- **Utilization:** How busy is the resource?
- **Saturation:** How much work is queued?
- **Errors:** Count of error events

**Example (Database):**
```
Utilization: 75% CPU, 60% Memory
Saturation: 10 connections waiting
Errors: 5 timeout errors/hour
```

---

### RED Method (Request-Oriented)

**For every service:**
- **Rate:** Requests per second
- **Errors:** Error rate
- **Duration:** Response time distribution

**Example (API Service):**
```
Rate: 500 req/s
Errors: 2% error rate
Duration: p50=100ms, p95=250ms, p99=800ms
```

---

## Prometheus and Grafana

### Prometheus Architecture

```
┌────────────────────────────────────────┐
│           Prometheus Server            │
│  ┌──────────────────────────────────┐  │
│  │      Retrieval (Scraper)         │  │
│  └───────────┬──────────────────────┘  │
│              │ Pull Metrics             │
│  ┌───────────▼──────────────────────┐  │
│  │      Time Series Database        │  │
│  └───────────┬──────────────────────┘  │
│              │                          │
│  ┌───────────▼──────────────────────┐  │
│  │      HTTP Server (API)           │  │
│  └──────────────────────────────────┘  │
└────────────────┬───────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼─────┐    ┌──────▼─────┐
   │  Grafana │    │  AlertMgr  │
   │(Visualize│    │  (Alerts)  │
   └──────────┘    └────────────┘
```

---

### Metrics Collection

**Application Instrumentation (Node.js):**
```javascript
// Install: npm install prom-client
const client = require('prom-client');
const express = require('express');

const app = express();

// Create metrics
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});

const httpRequestTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new client.Gauge({
  name: 'active_connections',
  help: 'Number of active connections'
});

// Middleware to track metrics
app.use((req, res, next) => {
  const start = Date.now();
  
  activeConnections.inc();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
    
    httpRequestTotal
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .inc();
    
    activeConnections.dec();
  });
  
  next();
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.listen(3000);
```

---

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Application metrics
  - job_name: 'myapp'
    static_configs:
      - targets: ['app:3000']
    metrics_path: '/metrics'
  
  # Node exporter (system metrics)
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
  
  # Kubernetes pods
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true

# Alerting rules
rule_files:
  - 'alerts.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

---

### Alert Rules

```yaml
# alerts.yml
groups:
  - name: application_alerts
    interval: 30s
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          rate(http_requests_total{status_code=~"5.."}[5m]) 
          / 
          rate(http_requests_total[5m]) 
          > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"
      
      # Slow response time
      - alert: SlowResponseTime
        expr: |
          histogram_quantile(0.95, 
            rate(http_request_duration_seconds_bucket[5m])
          ) > 1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Slow response time (p95)"
          description: "p95 latency is {{ $value }}s"
      
      # Service down
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
```

---

### Grafana Dashboards

**Docker Compose Setup:**
```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
  
  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"

volumes:
  prometheus-data:
  grafana-data:
```

**PromQL Queries:**
```promql
# Request rate (per second)
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status_code=~"5.."}[5m])
/
rate(http_requests_total[5m])

# p95 latency
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket[5m])
)

# CPU usage by pod
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# Memory usage
container_memory_usage_bytes / container_spec_memory_limit_bytes
```

---

## Application Performance Monitoring

### APM Tools

**Popular Options:**
- **New Relic**
- **Datadog**
- **Dynatrace**
- **AppDynamics**
- **Elastic APM**

---

### Elastic APM Example

**Node.js Setup:**
```javascript
// Install: npm install elastic-apm-node
// Must be required FIRST, before other modules
const apm = require('elastic-apm-node').start({
  serviceName: 'my-service',
  serverUrl: 'http://apm-server:8200',
  environment: 'production'
});

const express = require('express');
const app = express();

// APM automatically instruments Express

app.get('/api/users/:id', async (req, res) => {
  // Create custom span
  const span = apm.startSpan('fetch-user-from-db');
  
  try {
    const user = await db.users.findById(req.params.id);
    res.json(user);
  } catch (error) {
    // Capture exception
    apm.captureError(error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    if (span) span.end();
  }
});

// Custom transaction
async function processOrder(order) {
  const transaction = apm.startTransaction('process-order', 'background');
  
  try {
    await validateOrder(order);
    await chargePayment(order);
    await updateInventory(order);
    
    transaction.result = 'success';
  } catch (error) {
    apm.captureError(error);
    transaction.result = 'error';
    throw error;
  } finally {
    transaction.end();
  }
}
```

---

## Logging Best Practices

### Structured Logging

❌ **Bad (Unstructured):**
```javascript
console.log('User John logged in at 10:30 AM from IP 192.168.1.1');
```

✅ **Good (Structured):**
```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'auth-service' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

logger.info('User logged in', {
  userId: 123,
  username: 'john',
  ip: '192.168.1.1',
  timestamp: new Date().toISOString(),
  sessionId: 'abc123'
});

// Output (JSON):
{
  "level": "info",
  "message": "User logged in",
  "userId": 123,
  "username": "john",
  "ip": "192.168.1.1",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "sessionId": "abc123",
  "service": "auth-service"
}
```

---

### Log Levels

```javascript
logger.error('Critical error occurred', { error: err.message });
logger.warn('High memory usage', { usage: 85 });
logger.info('User action completed', { action: 'purchase' });
logger.debug('Variable value', { value: someVar });
logger.trace('Entering function', { function: 'processPayment' });
```

**Guidelines:**
- **ERROR:** Something failed, needs attention
- **WARN:** Something unexpected, but handled
- **INFO:** Important business events
- **DEBUG:** Detailed diagnostic information
- **TRACE:** Very detailed, for deep debugging

---

### Correlation IDs

**Track requests across services:**
```javascript
const { v4: uuidv4 } = require('uuid');

app.use((req, res, next) => {
  // Get or create correlation ID
  req.correlationId = req.headers['x-correlation-id'] || uuidv4();
  
  // Add to response headers
  res.setHeader('x-correlation-id', req.correlationId);
  
  // Add to all logs
  req.logger = logger.child({ correlationId: req.correlationId });
  
  next();
});

app.get('/api/users/:id', async (req, res) => {
  req.logger.info('Fetching user', { userId: req.params.id });
  
  // Forward correlation ID to downstream services
  const user = await fetch('http://user-service/users/' + req.params.id, {
    headers: {
      'x-correlation-id': req.correlationId
    }
  });
  
  req.logger.info('User fetched successfully', { userId: req.params.id });
  res.json(user);
});
```

**Result:** Track a single request across all services:
```
[Service A] correlationId=abc123 "Received request"
[Service B] correlationId=abc123 "Fetching user data"
[Service C] correlationId=abc123 "Querying database"
[Service C] correlationId=abc123 "Query completed"
[Service B] correlationId=abc123 "User data retrieved"
[Service A] correlationId=abc123 "Request completed"
```

---

## ELK Stack

### Architecture

```
Applications
  ↓ (logs)
Filebeat/Fluentd
  ↓ (ship logs)
Logstash (optional)
  ↓ (parse & transform)
Elasticsearch
  ↓ (store & search)
Kibana
  ↓ (visualize)
Dashboards, Alerts
```

---

### Docker Compose Setup

```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - xpack.security.enabled=false
    ports:
      - "9200:9200"
    volumes:
      - es-data:/usr/share/elasticsearch/data
  
  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    depends_on:
      - elasticsearch
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
  
  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    depends_on:
      - elasticsearch
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5000:5000"

volumes:
  es-data:
```

---

### Logstash Configuration

```ruby
# logstash.conf
input {
  tcp {
    port => 5000
    codec => json
  }
}

filter {
  # Parse timestamp
  date {
    match => [ "timestamp", "ISO8601" ]
  }
  
  # Add geoip for IP addresses
  geoip {
    source => "ip"
  }
  
  # Parse user agent
  useragent {
    source => "user_agent"
    target => "ua"
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "app-logs-%{+YYYY.MM.dd}"
  }
  
  # Also output to console for debugging
  stdout {
    codec => rubydebug
  }
}
```

---

### Sending Logs to Logstash

```javascript
const winston = require('winston');
require('winston-logstash');

const logger = winston.createLogger({
  transports: [
    new winston.transports.Logstash({
      port: 5000,
      host: 'logstash',
      node_name: 'my-app',
      max_connect_retries: -1
    })
  ]
});

logger.info('User action', {
  userId: 123,
  action: 'purchase',
  amount: 99.99,
  ip: '192.168.1.1'
});
```

---

## Distributed Tracing

### OpenTelemetry Example

**Node.js Setup:**
```javascript
// Install:
// npm install @opentelemetry/sdk-node
// npm install @opentelemetry/auto-instrumentations-node
// npm install @opentelemetry/exporter-jaeger

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');

const sdk = new NodeSDK({
  serviceName: 'my-service',
  traceExporter: new JaegerExporter({
    endpoint: 'http://jaeger:14268/api/traces'
  }),
  instrumentations: [getNodeAutoInstrumentations()]
});

sdk.start();

// Application code (automatically instrumented)
const express = require('express');
const app = express();

app.get('/api/users/:id', async (req, res) => {
  // Automatically traced!
  const user = await db.users.findById(req.params.id);
  res.json(user);
});
```

---

### Custom Spans

```javascript
const { trace } = require('@opentelemetry/api');

const tracer = trace.getTracer('my-service');

async function processOrder(order) {
  const span = tracer.startSpan('process-order');
  
  span.setAttribute('order.id', order.id);
  span.setAttribute('order.total', order.total);
  
  try {
    // Child spans
    await tracer.startActiveSpan('validate-order', async (validateSpan) => {
      await validateOrder(order);
      validateSpan.end();
    });
    
    await tracer.startActiveSpan('charge-payment', async (paymentSpan) => {
      await chargePayment(order);
      paymentSpan.end();
    });
    
    span.setStatus({ code: SpanStatusCode.OK });
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
    throw error;
  } finally {
    span.end();
  }
}
```

---

## Alerting Strategies

### Alert Fatigue Prevention

**Bad:**
```
Too many alerts → Noise → Ignored → Missed critical issues
```

**Good:**
```
Actionable alerts → Clear signal → Quick response
```

---

### Alert Best Practices

**1. Make Alerts Actionable:**

❌ **Bad:**
```
Alert: "High CPU usage"
(What do I do?)
```

✅ **Good:**
```
Alert: "High CPU usage on web-server-3"
Runbook: https://wiki.company.com/runbooks/high-cpu
Current: 95%
Threshold: 90%
Action: Scale up or investigate process
```

**2. Set Appropriate Thresholds:**
```yaml
# Don't alert on temporary spikes
- alert: HighCPU
  expr: avg_over_time(cpu_usage[10m]) > 90
  for: 5m  # Must be sustained for 5 minutes
```

**3. Use Multiple Severity Levels:**
```yaml
- alert: HighErrorRate
  expr: error_rate > 0.01
  labels:
    severity: warning  # Page someone during business hours

- alert: CriticalErrorRate
  expr: error_rate > 0.10
  labels:
    severity: critical  # Page someone immediately, 24/7
```

---

### Alert Routing

**AlertManager Configuration:**
```yaml
route:
  receiver: 'team-email'
  group_by: ['alertname', 'cluster']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  
  routes:
    # Critical alerts → PagerDuty
    - match:
        severity: critical
      receiver: pagerduty
      continue: true
    
    # Warning alerts → Slack
    - match:
        severity: warning
      receiver: slack
    
    # Database alerts → DBA team
    - match:
        component: database
      receiver: dba-team

receivers:
  - name: 'team-email'
    email_configs:
      - to: 'team@company.com'
  
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
  
  - name: 'slack'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK'
        channel: '#alerts'
  
  - name: 'dba-team'
    email_configs:
      - to: 'dba@company.com'
```

---

## Summary

**Key Takeaways:**

✅ **Three Pillars:** Metrics, Logs, Traces
✅ **Four Golden Signals:** Latency, Traffic, Errors, Saturation
✅ **Structured logging** for better searchability
✅ **Correlation IDs** for distributed tracing
✅ **Prometheus + Grafana** for metrics visualization
✅ **ELK Stack** for centralized logging
✅ **OpenTelemetry** for distributed tracing
✅ **Actionable alerts** prevent alert fatigue

**Next Steps:**
- **Next**: [18-DevSecOps-Fundamentals.md](./18-DevSecOps-Fundamentals.md) - Security in DevOps
- **Related**: [23-SRE-Practices.md](./23-SRE-Practices.md) - Site Reliability Engineering

---

*Remember: You can't fix what you can't see. Observability is your eyes into production!*
