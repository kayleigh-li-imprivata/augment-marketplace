---
name: python-development
description: Use when developing Python applications - patterns, testing with pytest, type hints, modern practices, and code organization
---

# Python Development Patterns

Use this skill for Python development guidance beyond basic constraints.

## Testing with pytest

**Configuration in pyproject.toml:** Use `[tool.pytest]` (pytest 9.0+) with
native TOML types, or `[tool.pytest.ini_options]` (pytest 6.0+) with INI-style
strings:

```toml
# pytest 9.0+ - native TOML (preferred)
[tool.pytest]
testpaths = ["tests"]
addopts = ["--cov=src", "-v"]  # Array, not string

# pytest 6.0+ - INI-style
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src -v"  # String, not array
```

**Organization:** Mirror source structure (`src/module.py` →
`tests/test_module.py`)

**Fixtures:** Use for shared data, connections, complex setup, dependency
injection.

**Parametrize:** Use `@pytest.mark.parametrize` for multiple test cases:

```python
@pytest.mark.parametrize("input,expected", [(1, 2), (2, 4), (3, 6)])
def test_double(input, expected):
    assert double(input) == expected
```

**Collection assertions:** Assert entire collections, not individual elements:

```python
# ✅ Preferred
assert result == [2, 4, 6]
assert result == {"a": 1, "b": 2}

# ❌ Avoid iterating
for i, item in enumerate(result):
    assert item == expected[i]
```

**Anti-mocking:** Use real implementations, in-memory databases, fakes - not
mocks.

## Type Hints

**Required:** All function signatures need type hints.

```python
def process_data(items: list[str], threshold: int = 10) -> dict[str, int]:
    return {item: len(item) for item in items if len(item) > threshold}
```

**Modern syntax (Python 3.9+):**

- `list[str]` not `List[str]`
- `dict[str, int]` not `Dict[str, int]`
- `X | None` not `Optional[X]`
- `A | B` not `Union[A, B]`

**Type checking:** Prefer pyright or zuban over mypy.

## Data Structures

**Use Pydantic** for all structured data (dataclasses are banned):

```python
from pydantic import BaseModel, Field

class User(BaseModel):
    name: str
    email: str
    age: int = Field(ge=0, le=150)
    
    model_config = {"frozen": True}  # Immutable if needed
```

## Modern Python Patterns

**f-strings:** Always use for string formatting.

```python
message = f"{name} is {age} years old"  # ✅
message = "{} is {}".format(name, age)  # ❌
```

**pathlib:** Always use instead of os.path.

```python
from pathlib import Path
config = Path("config") / "settings.json"
content = config.read_text() if config.exists() else ""
```

**Context managers:** Always for files, connections, locks.

```python
with open("data.txt") as f:
    data = f.read()
```

**Comprehensions:** Prefer when readable.

```python
squares = [x**2 for x in range(10)]
even_map = {x: x**2 for x in range(10) if x % 2 == 0}
```

**No ternary:** Use explicit if/else.

```python
# ❌ Avoid
result = value if condition else default

# ✅ Correct
if condition:
    result = value
else:
    result = default
```

## Code Organization

**Import order:**

1. Standard library
2. Third-party
3. Local application

```python
import os
from pathlib import Path

import requests
from pydantic import BaseModel

from myapp.config import settings
```

**Naming:**

- `snake_case` for functions/variables
- `PascalCase` for classes
- `UPPER_CASE` for constants
- `_prefix` for private

## Documentation

**Google-style docstrings:**

```python
def calculate_total(items: list[float], tax_rate: float = 0.1) -> float:
    """Calculate the total cost including tax.

    Args:
        items: List of item prices
        tax_rate: Tax rate as decimal (default: 0.1)

    Returns:
        Total cost including tax

    Raises:
        ValueError: If tax_rate is negative
    """
```

Type hints reduce need for verbose parameter descriptions - focus on _why_, not
_what_.

## Async/Await

**Use for:** I/O-bound operations, concurrent tasks, web servers.

**Avoid for:** CPU-bound work, simple scripts.

```python
async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()
```

## Virtual Environments

- uv/poetry manage automatically
- Never install globally
- Always `.venv` in `.gitignore`
