---
name: fastapi
description: Use when building FastAPI applications - route handlers, dependency injection, Pydantic models, async patterns, middleware, and common gotchas
---

# FastAPI Development

Guide for building FastAPI applications with proper patterns and avoiding common
pitfalls.

## Request Flow

Understand this flow for debugging:

```text
HTTP Request
    |
[Uvicorn: ASGI receive]
    |
[Starlette: Route match]
    |
[FastAPI: Extract params]
    |
[Pydantic: Parse & validate]
    |
[Depends: Resolve dependencies]
    |
[Handler: Your code]
    |
[Pydantic: Serialize response]
    |
JSON Response
```

## Route Order Matters

Specific routes MUST come before parameterized routes:

```python
# Correct order
@app.get("/users/me")      # Specific first
@app.get("/users/{id}")    # Parameterized second

# Wrong - "me" matches as {id}
@app.get("/users/{id}")
@app.get("/users/me")      # Never reached
```

## Dependency Injection

### Basic Pattern with Cleanup

```python
def get_db():
    db = SessionLocal()
    try:
        yield db          # Value injected to handler
    finally:
        db.close()        # Cleanup after response

@app.get("/users/{user_id}")
def read_user(user_id: int, db: Session = Depends(get_db)):
    return db.query(User).filter(User.id == user_id).first()
```

### Hierarchical Dependencies

```python
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(db: Session = Depends(get_db)):
    # get_db resolved first, result passed here
    return db.query(User).first()

@app.get("/me")
def read_me(user: User = Depends(get_current_user)):
    return user
```

**Key behavior:** Same `Depends()` call within a request returns cached
instance.

## Async vs Sync Handlers

| Handler Type | Use For | Execution |
|--------------|---------|-----------|
| `async def` | I/O-bound (HTTP, DB with async driver) | Event loop |
| `def` | CPU-bound, sync libraries | Threadpool |

```python
# I/O-bound - use async
@app.get("/external")
async def call_external():
    async with httpx.AsyncClient() as client:
        return await client.get("https://api.example.com")

# CPU-bound - use sync (runs in threadpool)
@app.get("/compute")
def heavy_compute():
    return expensive_calculation()
```

**Never block in async:**

```python
# WRONG - blocks event loop
@app.get("/bad")
async def bad_handler():
    time.sleep(10)  # Freezes entire server!

# Correct - use async sleep or sync def
@app.get("/good")
async def good_handler():
    await asyncio.sleep(10)
```

## Common Gotchas

| Gotcha | Problem | Solution |
|--------|---------|----------|
| Mutable defaults | `tags: list = []` shared across requests | `Field(default_factory=list)` |
| Route order | Specific after parameterized | Define specific routes first |
| Blocking async | `time.sleep()` in async | Use `def` or `asyncio.sleep()` |
| Background timing | Tasks run after response | Use Celery for critical tasks |
| Large uploads | Memory issues | Use `UploadFile` with streaming |

## Pydantic Models

```python
from pydantic import BaseModel, Field, ConfigDict

class ItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    price: float = Field(..., gt=0)
    tags: list[str] = Field(default_factory=list)  # Not = []

class ItemResponse(BaseModel):
    id: int
    name: str
    price: float
    
    model_config = ConfigDict(from_attributes=True)  # For ORM
```

## Error Handling

```python
from fastapi import HTTPException, status

@app.get("/items/{id}")
def read_item(id: int):
    if id not in items:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found"
        )
    return items[id]

# Custom exception handler
@app.exception_handler(CustomError)
async def custom_handler(request, exc):
    return JSONResponse(
        status_code=400,
        content={"error": str(exc)}
    )
```

## Project Structure

```text
src/
  app/
    __init__.py
    main.py           # FastAPI app, startup
    dependencies.py   # Shared Depends functions
    routers/
      users.py        # APIRouter for /users
      items.py        # APIRouter for /items
    models/
      user.py         # Pydantic models
    db/
      session.py      # Database connection
```

## APIRouter for Modularity

```python
# routers/users.py
from fastapi import APIRouter, Depends

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/")
def list_users():
    ...

# main.py
from app.routers import users
app.include_router(users.router)
```

## Advanced Topics

See `REFERENCE.md` in this directory for:

- **Dependencies with Yield** - Exception handling, scope control
- **Testing** - TestClient, dependency overrides, fixtures
- **WebSockets** - Endpoints, ConnectionManager, broadcasting, error handling
- **ASGI Middleware** - Built-in and custom middleware patterns
- **OAuth2 + JWT** - Authentication setup, token handling, timing attack
  prevention
- **Background Tasks** - Basic pattern, dependency injection, when to use
- **Lifespan Events** - Modern pattern, use cases, deprecated approach
- **Custom Response Types** - ORJSONResponse, StreamingResponse, FileResponse
