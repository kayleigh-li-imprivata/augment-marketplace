---
name: api-design
description: Use when designing APIs - RESTful endpoints, client interfaces, service integration, and FastAPI-specific patterns
---

# API Design

Guide for building maintainable API services and client interfaces.

## When to Use

Use this skill when:

- Designing new API endpoints
- Building client libraries for services
- Integrating with external services
- Working with FastAPI applications
- Defining data transfer objects (DTOs)

## RESTful API Design

### Endpoint Structure

- Use **nouns** for resource names, not verbs
- Use HTTP methods appropriately (GET, POST, PUT, DELETE)
- Consistent query parameter patterns
- Clear, hierarchical URL structures

### Response Consistency

- Standard HTTP status codes
- Consistent error response structures
- Meaningful error messages with context
- Consistent serialization formats

### Versioning

- Include version in API design from start
- Maintain backward compatibility when possible
- Clear migration paths for breaking changes
- Document changes and deprecation timelines

## Client Interface Design

### Simple Client APIs

- Single client class per service with logical method grouping
- Sensible defaults to minimize required parameters
- Clear separation between configuration and operation
- Consistent error handling across methods

### Data Transfer Objects (DTOs)

- Use Pydantic models for validation and serialization
- Clear field documentation and examples
- Proper type hints for all fields
- Conversion methods between internal/external representations

### Configuration Management

- Environment variables for deployment-specific settings
- Configuration validation at startup
- Document all configuration options
- Configuration classes over scattered constants

## Service Integration

### Database Integration

- Connection pooling and proper resource management
- Consistent query patterns and error handling
- Separate business logic from data access
- Modern libraries (DuckDB, SQLAlchemy)

### External Service Integration

- Proper timeout and retry logic
- Circuit breaker patterns for unreliable services
- Fallback mechanisms where appropriate
- Log failures with debugging context

### Authentication and Authorization

- Standard mechanisms (JWT, OAuth)
- Proper session management
- Validate permissions at service boundaries
- Log security events for audit

## FastAPI Patterns

### Dependency Injection

```python
from fastapi import Depends

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/users/{user_id}")
def read_user(user_id: int, db: Session = Depends(get_db)):
    return db.query(User).filter(User.id == user_id).first()
```

- Reusable dependencies for common functionality
- DI for database connections, auth, etc.
- Proper dependency lifecycle management
- Test dependencies independently

### Request/Response Models

```python
from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    """User creation request."""
    email: str = Field(..., description="User's email address")
    name: str = Field(..., min_length=1, max_length=100)

class UserResponse(BaseModel):
    """User response model."""
    id: int
    email: str
    name: str
```

- Descriptive model names indicating purpose
- Field validation and documentation
- Proper error handling for validation failures
- Model inheritance to reduce duplication

### Middleware and Error Handling

- Middleware for logging, auth, error handling
- Global exception handlers for consistent responses
- Request/response logging for debugging
- Correlation IDs for request tracing

```python
@app.exception_handler(ValidationError)
async def validation_exception_handler(request, exc):
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors(), "correlation_id": request.state.correlation_id}
    )
```
