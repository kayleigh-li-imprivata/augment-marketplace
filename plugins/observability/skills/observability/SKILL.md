---
name: observability
description: Use when implementing observability - error handling, structured logging, metrics, traces, correlation IDs, and alerting
---

# Observability

Guide for error handling, structured logging, and the three pillars of
observability.

## When to Use

Use this skill when:

- Implementing error handling patterns
- Adding logging to applications
- Setting up observability infrastructure
- Designing alerting and monitoring
- Implementing correlation/tracing

## Error Handling

### Specific Exception Types

```python
# ✅ Specific exceptions
class UserNotFoundError(Exception):
    """Raised when user cannot be found."""

class InvalidCredentialsError(Exception):
    """Raised when authentication fails."""

def get_user(user_id: str) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise UserNotFoundError(f"User {user_id} not found")
    return user
```

### Provide Context

```python
# ✅ Rich context
raise ValidationError(
    f"Invalid email format: {email}",
    field="email",
    value=email,
    user_id=user_id
)

# ❌ No context
raise ValidationError("Invalid email")
```

### Graceful Degradation

```python
def get_user_profile(user_id: str) -> UserProfile:
    try:
        profile = external_api.fetch_profile(user_id)
    except ExternalAPIError as e:
        logger.warning(f"External API failed, using cached: {e}")
        profile = cache.get(f"profile:{user_id}")
        if not profile:
            raise UserProfileUnavailableError(f"Cannot fetch profile for {user_id}")
    return profile
```

## Structured Logging

### Log Levels

| Level | Use |
|-------|-----|
| DEBUG | Detailed diagnostic information |
| INFO | User actions, system events |
| WARNING | Degraded performance, using fallback |
| ERROR | Handled exceptions, failed operations |
| CRITICAL | System failures, data corruption |

### What to Log

```python
# ✅ Log these
logger.info("user_created", user_id=user.id, email=user.email)
logger.warning("rate_limit_exceeded", user_id=user.id, endpoint="/api/data")
logger.error("database_connection_failed", error=str(e), retry_count=3)

# ❌ NEVER log sensitive data
logger.info(f"User logged in with password: {password}")  # NEVER
logger.debug(f"API key: {api_key}")  # NEVER
```

### Correlation IDs

```python
from contextvars import ContextVar

request_id_var: ContextVar[str] = ContextVar("request_id")

@app.before_request
def set_request_id():
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    request_id_var.set(request_id)
    structlog.contextvars.bind_contextvars(request_id=request_id)
```

## Three Pillars of Observability

1. **Logs**:
   What happened (events, errors, debug info)
2. **Metrics**:
   How much/how many (counters, gauges, histograms)
3. **Traces**:
   Where time was spent (request flow, dependencies)

### Correlation

- Consistent identifiers (request_id, user_id, trace_id)
- Link logs to traces via trace context
- Include trace_id in log messages
- Use OpenTelemetry for unified correlation
- Prefer auto-instrumentation

## OpenTelemetry Auto-Instrumentation

### Log Level Configuration

**OTEL does NOT control your app's log level.** You still need Python logging
config:

```python
import logging
import os

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(levelname)s - %(name)s - %(message)s",
)
```

| Variable | Controls |
|----------|----------|
| `LOG_LEVEL` | Your application's log level |
| `OTEL_LOG_LEVEL` | OTEL SDK internal debug logging |

### Running with OTEL

```bash
# Both variables are independent
LOG_LEVEL=DEBUG \
OTEL_SERVICE_NAME=my-service \
OTEL_TRACES_EXPORTER=console \
opentelemetry-instrument uvicorn myapp:app
```

### What OTEL Adds

- `trace_id` and `span_id` attributes on log records
- Automatic spans for frameworks (FastAPI, SQLAlchemy, boto, etc.)
- Export to collectors (OTLP, console, etc.)

OTEL layers on top of Python logging - it does not replace it.

## Alerting

### Define SLIs and SLOs

```yaml
# Service Level Indicators
- API availability: % successful requests
- API latency: p95 response time
- Error rate: % failed requests

# Service Level Objectives
- 99.9% availability (< 0.1% error rate)
- p95 latency < 200ms
- p99 latency < 500ms
```

### Alert Best Practices

- Alert on **symptoms**, not causes (user impact, not disk space)
- Include context (affected service, time range, severity)
- Avoid alert fatigue (tune thresholds, use aggregation)
- Define clear escalation paths
- Include runbooks in alert descriptions

## Performance Considerations

- Use sampling for high-volume traces
- Batch exports to reduce overhead
- Use async exporters
- Monitor observability overhead itself
