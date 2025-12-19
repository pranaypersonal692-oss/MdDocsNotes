# Site Reliability Engineering (SRE) Practices

## Table of Contents
1. [What is SRE](#what-is-sre)
2. [SLIs, SLOs, and SLAs](#slis-slos-and-slas)
3. [Error Budgets](#error-budgets)
4. [Toil Reduction](#toil-reduction)
5. [Incident Management](#incident-management)
6. [On-Call Best Practices](#on-call-best-practices)
7. [Postmortems](#postmortems)

---

## What is SRE

**SRE** (Site Reliability Engineering) is what happens when you treat operations as a software problem.

**Traditional Ops:**
```
Problem → Manual fix → Hope it doesn't happen again
```

**SRE:**
```
Problem → Automated fix → Prevent recurrence → Measure everything
```

**Core Principles:**
- Engineering approach to operations
- Embrace risk (100% uptime is impossible and wasteful)
- Measure everything
- Automate toil
- Balance reliability and feature velocity

---

## SLIs, SLOs, and SLAs

### Service Level Indicators (SLIs)

**Definition:** Quantitative measures of service level

**Common SLIs:**
```
Request Latency:
- p50: 100ms
- p95: 200ms
- p99: 500ms

Availability:
- % of successful requests

Throughput:
- Requests per second

Error Rate:
- % of failed requests
```

**Example Measurement:**
```javascript
const sli = {
  availability: successfulRequests / totalRequests,
  latency_p95: calculatePercentile(latencies, 95),
  errorRate: errorRequests / totalRequests
};
```

---

### Service Level Objectives (SLOs)

**Definition:** Target values or ranges for SLIs

**Examples:**
```
✅ GOOD SLOs:
- 99.9% of requests complete successfully
-  95% of requests complete in < 100ms
- 99% of requests complete in < 1s

❌ BAD SLOs:
- "Fast" (not measurable)
- "100% uptime" (unrealistic)
- "No errors" (impossible)
```

**SLO Example:**
```yaml
slo:
  - name: availability
    target: 99.9%
    window: 30d
    
  - name: latency_p95
    target: 200ms
    window: 30d
    
  - name: error_rate
    target: 0.1%
    window: 30d
```

---

### Service Level Agreements (SLAs)

**Definition:** Contractual agreement with consequences

```
SLI → SLO → SLA

SLI: We measure 99.95% uptime
SLO: We target 99.9% uptime
SLA: We guarantee 99.5% uptime or you get a refund
```

**Example:**
```
SLA: 99.5% monthly uptime

Downtime allowed per month:
= 30 days × 24 hours × 60 minutes × 0.5%
= 216 minutes = 3.6 hours

Penalty if breached: 10% service credit
```

---

## Error Budgets

### What is an Error Budget?

**Definition:** Amount of unreliability you can "afford"

```
SLO: 99.9% availability
Error Budget: 0.1% unavailability

Monthly Error Budget:
= 30 days × 24 hours × 60 min × 0.1%
= 43.2 minutes of downtime allowed
```

### Using Error Budgets

**Budget Remaining: Release Features**
```
Error Budget: 43.2 min/month
Used: 10 min
Remaining: 33.2 min (76%)

Decision: Green light for new features! 🚀
```

**Budget Exhausted: Focus on Reliability**
```
Error Budget: 43.2 min/month
Used: 45 min
Remaining: -1.8 min (OVER!)

Decision: Feature freeze. Fix reliability! 🔧
```

**Policy Example:**
```yaml
error_budget_policy:
  slo: 99.9%
  
  if_remaining > 50%:
    - Deploy new features freely
    - Normal release cadence
    
  if_remaining < 50%:
    - Increase testing
    - Reduce release frequency
    
  if_remaining < 0%:
    - Feature freeze
    - All hands on reliability
    - Root cause analysis required
```

---

## Toil Reduction

### What is Toil?

**Definition:** Manual, repetitive, automatable work with no enduring value

**Examples of Toil:**
```
✅ TOIL:
- Manually restarting servers
- SSH into boxes to check logs
- Copying files between environments
- Manual database backups
- Ticket-driven provisioning

❌ NOT TOIL:
- Incident response (requires judgment)
- Project work
- Designing systems
- Code reviews
```

### Measuring Toil

```
Team capacity: 40 hours/week
Toil: 15 hours/week

Toil %: 15/40 = 37.5%

Google's recommendation: < 50% toil
```

### Automating Toil

**Before (Toil):**
```bash
# Manual deployment (30 minutes each time)
ssh prod-server-1
git pull
npm install
pm2 restart app

ssh prod-server-2
git pull
npm install
pm2 restart app

# Result: 30 min × 10 deploys/week = 5 hours/week
```

**After (Automated):**
```bash
# One command
./deploy.sh production

# Or even better: GitOps auto-deploy on merge
# Result: 0 hours/week toil
```

---

## Incident Management

### Incident Severity Levels

```
SEV-1 (Critical):
- Service completely down
- Data loss occurring
- Security breach
Response: Page everyone, all hands on deck

SEV-2 (High):
- Partial service degradation
- Important feature broken
Response: Page on-call, escalate if needed

SEV-3 (Medium):
- Minor feature broken
- Performance degradation
Response: Create ticket, fix during business hours

SEV-4 (Low):
- Cosmetic issues
Response: Backlog
```

### Incident Response Process

**1. Detection:**
```
Alert → PagerDuty → On-call engineer paged
"High error rate: 5%"
```

**2. Triage:**
```
Acknowledge alert
Quick investigation
Assess severity
Escalate if needed
```

**3. Mitigation:**
```
Goal: Stop the bleeding FAST

Options:
- Rollback deployment
- Scale resources
- Disable feature flag
- Switch to backup
```

**4. Resolution:**
```
Find root cause
Permanent fix
Verify fix
Close incident
```

**5. Follow-up:**
```
Postmortem (blameless)
Action items
Prevention measures
```

---

## On-Call Best Practices

### On-Call Rotation

```
Primary On-Call: First responder
Secondary On-Call: Escalation point
Manager: Final escalation

Rotation: Weekly or bi-weekly
Team size: 6+ for sustainable rotation
```

### Playbooks

**Example Runbook:**
```markdown
# High API Error Rate

## Symptoms
- Error rate > 5%
- Alert: "API errors high"

## Investigation
1. Check Grafana dashboard: https://grafana.company.com/api
2. Check logs: `kubectl logs -f deploy/api`
3. Check database connections

## Common Causes
- Database connection pool exhausted
- Downstream service timeout
- Memory leak

## Mitigation
- If DB: Scale connection pool
- If downstream: Enable circuit breaker
- If memory: Restart pods

## Escalation
Secondary: @jane
Manager: @john
```

### On-Call Compensation

```
Best Practices:
- Compensate on-call time (even if not paged)
- Time off after major incidents
- Limit pages (proper alerting)
- Clear escalation path
- Manageable workload
```

---

## Postmortems

### Blameless Postmortem

**Purpose:** Learn from failures without blaming individuals

**Template:**
```markdown
# Incident Postmortem: API Outage 2024-01-15

## Summary
API was down for 45 minutes due to database connection exhaustion.

## Timeline
- 14:00: Deployment of v2.3.0
- 14:15: Error rate increases
- 14:20: Alert fired
- 14:25: On-call acknowledges
- 14:30: Identified DB connection leak
- 14:35: Rollback initiated
- 14:45: Service restored

## Root Cause
New code in v2.3.0 didn't close DB connections properly,
leading to connection pool exhaustion.

## Impact
- 45 minutes downtime
- 10,000 affected requests
- 500 users impacted
- Error budget: 45min / 43.2min = 104% (exceeded)

## What Went Well
- Alert fired correctly
- Rollback was quick
- Communication was clear

## What Went Wrong
- Missed in code review
- No integration test for connection leaks
- Deployment during peak hours

## Action Items
1. [ ] Add connection leak test (@engineer, due: 2024-01-20)
2. [ ] Update deployment schedule (off-peak only) (@manager, done)
3. [ ] Add code review checklist item (@lead, due: 2024-01-18)
4. [ ] Implement connection pool monitoring (@sre, due: 2024-01-25)

## Lessons Learned
- Always test resource cleanup
- Deploy during low-traffic windows
- Monitor connection pools proactively
```

---

## Summary

**Key Takeaways:**

✅ **SRE** treats operations as a software engineering problem
✅ **SLOs** define reliability targets
✅ **Error budgets** balance features and reliability
✅ **Reduce toil** through automation
✅ **Incidents** require clear processes
✅ **On-call** must be sustainable
✅ **Postmortems** are blameless and action-oriented

**SRE Metrics:**
```
- SLO compliance: Did we meet our targets?
- Error budget: How much budget remaining?
- Toil: What % of time is toil?
- MTTR: Mean time to recovery
- Change failure rate: % of changes causing incidents
```

**Next Steps:**
- **Related**: [15-Monitoring-Metrics.md](./15-Monitoring-Metrics.md)
- **Related**: [28-Troubleshooting.md](./28-Troubleshooting.md)

---

*Remember: Hope is not a strategy. Measure, automate, and improve!*
