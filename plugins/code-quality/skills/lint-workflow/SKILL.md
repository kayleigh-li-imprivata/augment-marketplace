---
name: lint-workflow
description: Use when fixing linting errors - iterate with individual linters for speed, verify with actual CI before claiming success
---

# Lint Workflow

## Overview

Fix linting errors systematically:
iterate locally with individual linters, then verify with actual CI.

**Core principle:** Local `act` is a pre-flight check, not proof.
CI is the source of truth.

## The Iron Law

```text
LINTING FIXES MUST NOT CHANGE FUNCTIONALITY
```

Only make changes that address linting errors.
If a fix would change behavior, STOP and ask for approval.

## The Iteration Loop

```text
1. Identify failing linter(s) from error output
2. Run ONLY that linter (fast iteration)
3. Fix issues
4. Re-run single linter until it passes
5. Move to next failing linter
6. Run full suite once at the end
7. Push and wait for CI verification
8. Only claim success when CI passes
```

### Running Individual Linters

Use `ENABLE_LINTERS` to run a single linter at a time:

```bash
# Run a single linter by name
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint --env ENABLE_LINTERS=PYTHON_RUFF

# Run with auto-fix enabled
act -s GITHUB_TOKEN=$GITHUB_TOKEN -j lint --env ENABLE_LINTERS=PYTHON_RUFF --env APPLY_FIXES=all
```

**Common linter names:**

| Language | Linters |
|----------|---------|
| Python | `PYTHON_RUFF`, `PYTHON_MYPY`, `PYTHON_PYRIGHT` |
| JavaScript | `JAVASCRIPT_ESLINT`, `JAVASCRIPT_PRETTIER` |
| TypeScript | `TYPESCRIPT_ES`, `TYPESCRIPT_PRETTIER` |
| YAML | `YAML_YAMLLINT` |
| Shell | `BASH_SHELLCHECK`, `BASH_SHFMT` |
| Dockerfile | `DOCKERFILE_HADOLINT` |
| Markdown | `MARKDOWN_MARKDOWNLINT` |

### Auto-Fix Tools

Try auto-fix first, then review changes:

| Tool | Fix Command |
|------|-------------|
| ruff | `ruff check --fix . && ruff format .` |
| eslint | `npx eslint --fix .` |
| prettier | `npx prettier --write .` |
| shfmt | `shfmt -w .` |
| markdownlint | `npx markdownlint --fix .` |

**Always review diffs after auto-fix** before proceeding.

## CI Verification (Required)

Local `act` sometimes passes when CI fails.
Always verify:

```bash
# Push changes
git push

# Wait for CI
gh pr checks --watch
```

**Only claim "linting fixed" when CI passes.**

If local passed but CI failed, investigate the difference and document it in the
Known Differences section below.

## Known act/CI Differences

Document linters that behave differently between local act and GitHub CI:

| Linter | Difference | Workaround |
|--------|------------|------------|
| (add as discovered) | | |

## Scope Reminder

| Allowed | Requires Approval |
|---------|-------------------|
| Formatting, whitespace | Any logic change |
| Import ordering | Adding/removing code |
| Adding type hints | Changing function signatures |
| Removing unused imports | Removing "unused" code that may be used dynamically |
| Style fixes | Renaming beyond what linter requires |

## Red Flags

If you catch yourself thinking:

- "I'll just fix this bug while I'm here"
- "This code is wrong, let me correct it"
- "The linter is wrong, I'll suppress it"

**STOP.
Ask user first.**

## Related Skills

- **verification-before-completion** - Verify fixes before claiming success
- **git-workflow** - Commit message conventions
