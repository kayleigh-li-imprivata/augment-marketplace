---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

## Overview

Write the test first.
Watch it fail.
Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it
tests the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Always:**

- New features
- Bug fixes
- Refactoring
- Behavior changes

**Exceptions (ask first):**

- Throwaway prototypes
- Generated code
- Configuration files

Thinking "skip TDD just this once"?
Stop.
That's rationalization.

## The Iron Law

```text
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test?
Delete it.
Start over.

**No exceptions:**

- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

## Red-Green-Refactor

### RED - Write Failing Test

Write one minimal test showing what should happen.

**Requirements:**

- One behavior
- Clear name
- Real code (no mocks unless unavoidable)

### Verify RED - Watch It Fail

**MANDATORY.
Never skip.**

```bash
npm test path/to/test.test.ts
```

Confirm:

- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

**Test passes?** You're testing existing behavior.
Fix test.

### GREEN - Minimal Code

Write simplest code to pass the test.
Don't add features beyond the test.

### Verify GREEN - Watch It Pass

**MANDATORY.**

Confirm:

- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

### REFACTOR - Clean Up

After green only:

- Remove duplication
- Improve names
- Extract helpers

Keep tests green.
Don't add behavior.

### Repeat

Next failing test for next feature.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

## Why Order Matters

**"I'll write tests after to verify it works"** - Tests written after code pass
immediately.
Passing immediately proves nothing.

**"I already manually tested all the edge cases"** - Manual testing is ad-hoc.
Automated tests are systematic.

**"Deleting X hours of work is wasteful"** - Sunk cost fallacy.
Working code without real tests is technical debt.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |

## Red Flags - STOP and Start Over

- Code before test
- Test after implementation
- Test passes immediately
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "I'm being pragmatic"
- "This is different because..."

**All of these mean:
Delete code.
Start over with TDD.**

## Verification Checklist

Before marking work complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes?
You skipped TDD.
Start over.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask for help. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Final Rule

```text
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without explicit permission.

---

## Test Quality Guidelines

### Test Structure (AAA Pattern)

All tests must follow "Arrange, Act, Assert":

```python
def test_user_authentication():
    # Arrange
    user = User(username="test_user")
    auth_service = AuthenticationService()

    # Act
    result = auth_service.authenticate(user.username, "password")

    # Assert
    assert result.is_authenticated is True
```

### Test Documentation

- Remove docstrings that restate the test name
- Keep docstrings that explain non-obvious behavior or edge cases
- Keep AAA section comments for structure

### Avoid Mocks

Strongly discourage mocks, stubs, and test doubles:

**Preferred alternatives:**

- Dependency injection with real implementations
- In-memory databases (SQLite, DuckDB)
- Lightweight fake implementations
- Real instances with test data

**When mocks are acceptable:**

- Truly external systems (payment APIs, SMS gateways)
- Prohibitively expensive cloud services
- Even then, prefer fake implementations over mock frameworks

### Assert Booleans Directly

```python
# ✅ Correct
assert condition
assert not condition

# ❌ Wrong
assert condition == True
assert condition == False
```

### Fuzzing and Property-Based Testing

Use automated test data generation:

- **Polyfactory** for Pydantic models
- **Hypothesis** for property-based testing
- **Faker** for realistic sample data
