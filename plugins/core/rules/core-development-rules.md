---
type: always_apply
priority: CRITICAL
description: Core development rules and coding standards
last_updated: 2025-02-13
---
# Core Development Rules

## ⚠️ CRITICAL RULES SUMMARY ⚠️

Before proceeding with any task, be aware of these **CRITICAL FAILURE**
violations:

1. **Response Style (MANDATORY)**:
   NEVER use flattering, evaluative, or self-aggrandizing language in responses.
   No "Great question!", "Excellent idea!", "That's interesting!", etc. See
   `response-style-communication.md` for complete list of prohibited phrases.

2. **Tool Selection (MANDATORY)**:
   ALWAYS use specialized semantic code analysis tools (`find_symbol`,
   `find_referencing_symbols`, `find_implementations`, `get_symbols_overview`)
   when searching for code symbols.
   NEVER use `grep`, `ripgrep`, `ag`, or `ack` for code symbol searches.
   See "Tool Selection Hierarchy" section below.

3. **Git Operations (MANDATORY)**:
   ALL git operations MUST use the git MCP server tools (e.g., `git_status_git`,
   `git_commit_git`, `git_add_git`).
   Direct `git` commands via `launch-process` are blocked.
   See `git-mcp-required.md`.

4. **Git Commits**:
   NEVER commit in main checkout without explicit user authorization.
   EXCEPTION:
   In `.worktrees/` directories, commit freely with atomic commits.
   See `authorization-policies.md` for details.

5. **Git Staging (MANDATORY)**:
   NEVER use `git_add_git` with `all:
   true` - ALWAYS stage specific files explicitly with exact paths

6. **No Nested Functions**:
   NEVER define functions inside other functions or create closures

7. **No Continue Statements**:
   NEVER use `continue` statements in loops

8. **Tool Behavior Verification (MANDATORY)**:
   BEFORE using any CLI tool, VERIFY its expected arguments and defaults.
   Do NOT assume tools work on the current directory by default.
   See "Tool Behavior Verification" section below.

9. **Signature Change Completeness (MANDATORY)**:
   After changing ANY public method or function signature, use
   `find_referencing_symbols` to find ALL callers and update them.
   Run the project's type checker to verify no type errors before reporting complete.
   See "Signature Change Completeness" section below.

---

## Tool Behavior Verification

### ⚠️ MANDATORY: Verify Before Executing ⚠️

**BEFORE running any CLI tool** (especially linters, formatters, build tools),
verify how it works:

1. **Check if directory/file argument is required** vs. defaulting to current
   directory
2. **Verify the correct invocation syntax** using `--help` or documentation
3. **Do NOT assume** based on other similar tools

**Common tools that require explicit paths:**

| Tool | Requires | Example |
|------|----------|---------|
| pyright | Directory argument | `pyright src/` not just `pyright` |
| mypy | File/directory argument | `mypy src/` |
| pytest | Usually works on cwd | `pytest` or `pytest tests/` |

**Verification methods (in order of preference):**

1. `tool --help` - Check argument requirements
2. Check pyproject.toml/config for tool-specific settings
3. Documentation lookup if unclear

**Example workflow:**

```bash
# Before running pyright for the first time in a project:
pyright --help # Check: does it need explicit path?

# Then run with appropriate arguments:
pyright src/
```

**CRITICAL**:
When a tool invocation fails or produces unexpected results, verify the
invocation syntax before retrying with different arguments.

---

## Code Patterns (Automated Enforcement)

All code patterns are **automatically enforced** by ast-grep rules in
`~/.config/ast-grep/rules/` (70+ rules) and ruff.
The `auto_lint.sh` hook runs these on every file modification.

**Key enforced patterns:**

- No nested functions, classes, or closures
- No `continue`, `global`, or `nonlocal` statements
- No ternary expressions
- No mocks (`unittest.mock`, `pytest-mock`, `monkeypatch`)
- No `assert x == True/False`
- No `time.sleep` in tests
- No dataclasses (use Pydantic)
- No legacy typing (`List`, `Optional`) - use modern syntax
- No `os.path` - use pathlib

See individual rule files for rationale and alternatives.

## Tool Selection Hierarchy

### ⚠️ MANDATORY: Semantic Tools for Code Symbols ⚠️

**CRITICAL FAILURE** to use generic text search (`grep`, `ripgrep`, `ag`, `ack`)
for code symbols when semantic tools are available.

| Search Target | Required Tool | Fallback (justify use) |
|--------------|---------------|------------------------|
| Symbol definitions | `find_symbol` | Never for code symbols |
| Symbol usages | `find_referencing_symbols` | Never for code symbols |
| Implementations | `find_implementations` | Never for code symbols |
| File structure | `get_symbols_overview` | Never for code symbols |
| Comments, TODOs | `view` with `search_query_regex` | `grep`/`ripgrep` |
| Config files (YAML, JSON) | `grep`/`ripgrep` | - |
| String literals, logs | `grep`/`ripgrep` | - |

### Decision Rule

**Before ANY search**:
Is the target a code symbol (class, function, variable, method)?

- **YES** → MUST use semantic tools.
  No exceptions.
- **NO** → May use text search.

### Prohibited Patterns

- ❌ `grep -r "class ClassName"` or `ripgrep "def function_name"`
- ❌ Text search for "all usages of" any code symbol
- ❌ Justifying text search with "it's faster" or "it's simpler"


## Signature Change Completeness

### ⚠️ MANDATORY: Update All Callers After Signature Changes ⚠️

**CRITICAL FAILURE** to leave broken callers after changing any public method,
function, or class signature.

**Applies to**: parameter additions/removals, renames, type changes, return
type changes, and new required arguments.

### Required Workflow

After changing **any** public function/method signature:

1. **Find all callers** using `find_referencing_symbols` on the changed symbol
2. **Update every caller** — no exceptions, no deferred fixes
3. **Find all implementations** using `find_implementations` if the symbol is
   part of an interface or abstract class
4. **Run the project's type checker** to verify no compilation errors remain.
   Check project memory or `pyproject.toml` for the correct command.
5. **Do not report the task as complete** until the type checker passes clean

### MCP Language Server Tools

The `language-server` MCP server provides LSP-backed tools that complement
Augment's semantic tools:

| Need | Tool |
|------|------|
| Precise symbol definition | `definition` (language-server MCP) |
| All references to a symbol | `references` (language-server MCP) |
| File diagnostics (errors) | `diagnostics` (language-server MCP) |
| Rename across project | `rename_symbol` (language-server MCP) |
| Augment's cross-file usages | `find_referencing_symbols` |
| Interface implementations | `find_implementations` |

Use **both** Augment semantic tools and the language-server MCP tools for
confidence — they complement each other.

### Prohibited Patterns

- ❌ Changing a signature and only updating the definition file
- ❌ Reporting "done" without running `pyright` after signature changes
- ❌ Leaving `TODO: update callers` comments as a substitute for updating them

## Structured Thinking

For complex debugging, architecture, or investigations, use the
`structured-thinking` skill.
See the skill for strategy selection, examples, and advanced features (session
management, tool integration, quality reflection).

## Design Principles

Based on "A Philosophy of Software Design":

- **Deep modules**:
  Simple interfaces hiding complex implementation
- **Avoid shallow modules**:
  Interface should be simpler than implementation
- **Strategic over tactical**:
  Design for evolution, not just immediate needs
- **Consolidate**:
  One cohesive module over multiple fragmented ones

## Python Best Practices

- Type hints on all public functions (enforced by ty)
- Docstrings on all public APIs
- Specific exception types with context
- Comments on their own line (not inline)

## Package Management

**Primary Reference**:
See `python-development.md` for detailed Python package management.

### Quick Reference

| Lock File Present | Use Package Manager |
|-------------------|---------------------|
| `poetry.lock` | Poetry |
| `uv.lock` or none | uv (default) |

**CRITICAL**:
Never bypass lock files with low-level commands (`pip install`, `uv pip
install`).

**Non-Python Languages**:
Use appropriate package managers (npm/yarn/pnpm for JS, cargo for Rust, go mod
for Go).
Never manually edit package files when commands are available.
See `authorization-policies.md` for installation authorization requirements.

## Testing and Quality

See the `test-driven-development` skill for detailed testing patterns including:

- AAA (Arrange, Act, Assert) pattern
- Test documentation guidelines
- Avoiding mocks (use real implementations or fakes)
- Fuzzing with Polyfactory, Hypothesis, Faker
- Boolean assertion patterns

**Key rules (enforced by ast-grep):**

- No `unittest.mock`, `pytest-mock`, or `monkeypatch`
- No `time.sleep` in tests
- No `assert x == True/False`

**Linting:** See `linting-enforcement.md` for workflow.

## Code Organization

- **Single Responsibility**:
  Each module/class/function does one thing well
- **Naming**:
  snake_case (functions/vars), PascalCase (classes), UPPER_CASE (constants)
- **Config**:
  Centralize config, use environment variables, no magic numbers

## Version Control

**CRITICAL**:
All git operations MUST use git MCP server tools.
See `git-mcp-required.md`.

**Git Authorization** (see `authorization-policies.md` for full matrix):

- **Worktree exception:** In `.worktrees/` directories, commit freely (atomic,
  well-structured)
- **Main checkout:** NEVER commit/push/merge without explicit user authorization
- "save", "finish", "complete" do NOT authorize commits
- Must use word "commit", "push", "merge", etc.
- Always confirm commit message before executing (main checkout only)

**When work is complete:** Inform user changes are ready, ask if they want to
commit.

### Objective Language in Code and Documentation

**Rule**:
Use objective, factual language in all code-related content.
See `response-style-communication.md` for comprehensive guidelines.

**Quick reference:**

- ❌ "Greatly improve error handling" → ✅ "Refactor error handling to use custom
  exception types"
- ❌ "Add amazing new feature" → ✅ "Add user authentication feature"
- ❌ "Perfect the API design" → ✅ "Simplify API by consolidating endpoints"

### GitHub API Operations

Use the GitHub MCP server tools (e.g., `list_issues_github`,
`list_pull_requests_github`, `search_code_github`) for remote GitHub operations.
Never use `web-fetch` for GitHub URLs.

**Configuration:** GitHub MCP server has read-write capabilities.
Write operations require user approval via tool permissions.

**Key rules:**

- Use GitHub MCP server tools (`*_github` suffix) for all GitHub operations
- NEVER use `web-fetch` for github.com or raw.githubusercontent.com
- Read operations are auto-approved; write operations prompt for approval

## Notes Management

See the `knowledge-capture` skill for detailed notes guidance including:

- **Proactive decision capture** (during conversation, automatic)
- Mandatory triggers (session start, task completion, end of session)
- What to capture and what to avoid
- Person note formatting

### CRITICAL: Proactive Decision Capture

**Automatically capture design decisions, architectural choices, and technical
trade-offs to Basic Memory immediately when they occur during conversation.**

| Capture When | Directory | Example |
|--------------|-----------|---------|
| Architecture decisions made | `artifacts/architecture/` | Framework choice, component structure |
| Design decisions made | `artifacts/specs/` | API design, data models |
| Patterns established | `knowledge/patterns/` | Implementation conventions |
| Trade-offs chosen | `artifacts/architecture/` | Option A over B with rationale |

**Behavior**:

- Do NOT ask permission - capture automatically
- Notify user:
  `📝 Captured decision:
  [title]`
- Include:
  Context, Decision, Alternatives Considered, Consequences
- Tag observations:
  `[decision]`, `[tradeoff]`, `[constraint]`

**Critical requirements:**

- MUST check basic-memory at session start when context likely exists
- MUST capture decisions immediately when made (not deferred to session end)
- MUST evaluate notes update after completing significant work

**Failure to capture decisions when triggers are met is a CRITICAL violation.**
