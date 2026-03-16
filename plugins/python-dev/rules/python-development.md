---
type: always_apply
priority: HIGH
description: Critical Python constraints - package authorization, tool detection
last_updated: 2026-02-19
---

# Python Development - Critical Constraints

For patterns and best practices, see the `python-development` skill.

## CRITICAL: Package Installation Authorization

**NEVER install/update/remove packages without EXPLICIT authorization.**

**Explicit authorization requires** words like "install", "add", "update",
"remove", or "upgrade" with package names.

**These do NOT authorize installation:**

- "Fix this import error" → Inform which package is needed
- "Make this work" → Explain what's missing
- "Resolve the dependency issue" → Explain the issue
- "Set up the project" → Ask which dependencies to install

**Before ANY package operation:**

1. Confirm explicit authorization
2. Inform user which packages will be affected
3. Show the command that will be executed

## Package Manager Detection

1. `uv.lock` exists → use **uv**
2. `poetry.lock` exists → use **poetry**
3. New project → default to **uv**

## CRITICAL: High-Level Commands Only

```bash
# ✅ Correct - updates lock files
uv add requests
uv add --dev pytest
poetry add requests
poetry add --group dev pytest

# ❌ NEVER - bypasses lock files
uv pip install requests
```

**Note:** The `pip_to_uv.sh` hook automatically rewrites `pip install` commands:

- `pip install pkg` -> `uv add pkg` (updates lock files)
- `pip install -r requirements.txt` -> `uv pip install -r` (fallback for special
  flags)
- `pip install -e .` -> `uv pip install -e .` (fallback for editable installs)

## Security

- NEVER install from untrusted sources without approval
- NEVER bypass lock files
- Inform user of packages with known security advisories

## Quick Reference

| Task | uv | poetry |
|------|-----|--------|
| Add dependency | `uv add X` | `poetry add X` |
| Add dev dependency | `uv add --dev X` | `poetry add --group dev X` |
| Remove | `uv remove X` | `poetry remove X` |
| Install all | `uv sync` | `poetry install` |
| Run command | `uv run pytest` | `poetry run pytest` |
