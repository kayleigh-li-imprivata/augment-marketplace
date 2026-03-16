# FastAPI Reference

Detailed patterns and examples.
See SKILL.md for core concepts.

## Dependencies with Yield: Advanced Patterns

### Exception Handling in Yield Dependencies

```python
from typing import Annotated


class OwnerError(Exception):
    pass


def get_username():
    try:
        yield "Rick"
    except OwnerError as e:
        # MUST re-raise or convert to HTTPException
        raise HTTPException(status_code=400, detail=f"Owner error: {e}")


@app.get("/items/{item_id}")
def get_item(item_id: str, username: Annotated[str, Depends(get_username)]):
    if item_id == "portal-gun":
        raise OwnerError("Rick's portal gun")
    return {"item_id": item_id, "owner": username}
```

**Critical:** Never swallow exceptions in yield dependencies - you get silent
500 errors with no logs.

### Dependency Scope Control

```python
# Default: cleanup runs AFTER response sent
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()  # Runs after response


# scope="function": cleanup runs BEFORE response
@app.get("/users/me")
def get_user(db: Annotated[Session, Depends(get_db, scope="function")]):
    return db.query(User).first()  # db.close() happens, THEN response sent
```

Use `scope="function"` when you need cleanup before the response is sent.

## Testing

### TestClient Basics

```python
from fastapi.testclient import TestClient


# IMPORTANT: Use sync `def`, not `async def`
def test_read_item():
    client = TestClient(app)
    response = client.get("/items/1")
    assert response.status_code == 200
    assert response.json() == {"item_id": 1}
```

### Dependency Overrides

```python
def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


# Override before creating client
app.dependency_overrides[get_db] = override_get_db


def test_with_override():
    client = TestClient(app)
    response = client.get("/items/")
    assert response.status_code == 200


# Clean up after tests
app.dependency_overrides.clear()
```

Use pytest fixtures for cleaner setup/teardown:

```python
@pytest.fixture
def client():
    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()
```

## WebSockets

### Basic WebSocket Endpoint

```python
from fastapi import WebSocket, WebSocketDisconnect


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(f"Message: {data}")
    except WebSocketDisconnect:
        print("Client disconnected")
```

### ConnectionManager for Broadcasting

```python
class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)


manager = ConnectionManager()


@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: int):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(f"Client {client_id}: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
```

**Warning:** In-memory ConnectionManager only works single-process.
For multiple workers, use Redis pub/sub or `broadcaster` library.

### WebSocket Error Handling

```python
from fastapi import WebSocketException
from starlette.websockets import WebSocketState


# HTTPException does NOT work with WebSockets
# Use WebSocketException instead
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    if not authorized:
        raise WebSocketException(code=1008, reason="Unauthorized")
```

## ASGI Middleware

### Adding Middleware

```python
from starlette.middleware.httpsredirect import HTTPSRedirectMiddleware
from starlette.middleware.trustedhost import TrustedHostMiddleware
from starlette.middleware.gzip import GZipMiddleware

# Use app.add_middleware(), not manual wrapping
app.add_middleware(HTTPSRedirectMiddleware)
app.add_middleware(TrustedHostMiddleware, allowed_hosts=["example.com"])
app.add_middleware(GZipMiddleware, minimum_size=1000)
```

**Middleware order:** Last added executes first (wraps outermost).

### Custom ASGI Middleware

```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request


class TimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.perf_counter()
        response = await call_next(request)
        duration = time.perf_counter() - start
        response.headers["X-Process-Time"] = str(duration)
        return response


app.add_middleware(TimingMiddleware)
```

## OAuth2 + JWT Security

### Authentication Setup

```python
from datetime import datetime, timedelta, timezone
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash
from pydantic import BaseModel

SECRET_KEY = "your-secret-key"  # Generate: openssl rand -hex 32
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

password_hash = PasswordHash.recommended()
DUMMY_HASH = password_hash.hash("dummy")  # Timing attack prevention

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


class Token(BaseModel):
    access_token: str
    token_type: str
```

### Token Creation and Verification

```python
def create_access_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise credentials_exception
    except InvalidTokenError:
        raise credentials_exception
    user = get_user(db, username=username)
    if user is None:
        raise credentials_exception
    return user
```

### Timing Attack Prevention

```python
def authenticate_user(db, username: str, password: str):
    user = get_user(db, username)
    if not user:
        # Always verify to prevent timing-based username enumeration
        password_hash.verify(password, DUMMY_HASH)
        return False
    if not password_hash.verify(password, user.hashed_password):
        return False
    return user
```

**Key points:**

- Use `pwdlib` with Argon2 (not passlib/bcrypt)
- Always verify against dummy hash for non-existent users
- Store SECRET_KEY in environment variable

## Background Tasks

### Basic Pattern

```python
from fastapi import BackgroundTasks


def write_notification(email: str, message: str = ""):
    with open("log.txt", mode="w") as f:
        f.write(f"notification for {email}: {message}")


@app.post("/send-notification/{email}")
async def send_notification(email: str, background_tasks: BackgroundTasks):
    background_tasks.add_task(write_notification, email, message="notification")
    return {"message": "Notification sent in the background"}
```

### With Dependency Injection

```python
def get_query(background_tasks: BackgroundTasks, q: str | None = None):
    if q:
        background_tasks.add_task(write_log, f"found query: {q}")
    return q


@app.post("/send/{email}")
async def send(
    email: str, background_tasks: BackgroundTasks, q: Annotated[str, Depends(get_query)]
):
    background_tasks.add_task(write_log, f"message to {email}")
    return {"message": "Sent"}
```

**When to use:**

| Use Case | Tool |
|----------|------|
| Email, logging, simple tasks | BackgroundTasks |
| Complex, distributed processing | Celery + Redis/RabbitMQ |
| Needs same-process memory | BackgroundTasks |
| Multiple servers | Celery |

## Lifespan Events

### Modern Pattern (Recommended)

```python
from contextlib import asynccontextmanager

ml_models = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: before accepting requests
    ml_models["model"] = load_expensive_model()
    yield
    # Shutdown: after handling all requests
    ml_models.clear()


app = FastAPI(lifespan=lifespan)


@app.get("/predict")
async def predict(x: float):
    return {"result": ml_models["model"](x)}
```

**Use cases:**

- Load ML models once (not per request)
- Database connection pools
- Warm up caches
- External service connections

**Warning:** Lifespan events only fire for main app, not sub-applications.

### Deprecated Pattern (Avoid)

```python
# DON'T use - deprecated
@app.on_event("startup")
async def startup(): ...


@app.on_event("shutdown")
async def shutdown(): ...
```

If you use `lifespan`, startup/shutdown event handlers are ignored.

## Custom Response Types

### Available Responses

| Class | Use Case | Requires |
|-------|----------|----------|
| `JSONResponse` | Default JSON | - |
| `ORJSONResponse` | Fast JSON | `orjson` |
| `HTMLResponse` | HTML pages | - |
| `StreamingResponse` | Large/streaming data | - |
| `FileResponse` | File downloads | - |
| `RedirectResponse` | HTTP redirects | - |

### High-Performance JSON

```python
from fastapi.responses import ORJSONResponse

# Set as default for all routes
app = FastAPI(default_response_class=ORJSONResponse)


# Or per-route
@app.get("/items/", response_class=ORJSONResponse)
async def read_items():
    return [{"item_id": "Foo"}]
```

Requires:
`pip install orjson`

### Streaming Response

```python
from fastapi.responses import StreamingResponse


async def data_generator():
    for i in range(10):
        yield b"chunk of data"


@app.get("/stream")
async def stream():
    return StreamingResponse(data_generator())


# With file-like objects
@app.get("/video")
def stream_video():
    def iterfile():
        with open("large-video.mp4", mode="rb") as f:
            yield from f

    return StreamingResponse(iterfile(), media_type="video/mp4")
```

### File Response

```python
from fastapi.responses import FileResponse


@app.get("/download")
async def download():
    return FileResponse(
        path="document.pdf", filename="download.pdf", media_type="application/pdf"
    )
```

Auto-includes `Content-Length`, `Last-Modified`, `ETag` headers.
