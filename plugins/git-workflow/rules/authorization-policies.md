---
type: always_apply
priority: HIGH
description: Unified authorization policies for all operations requiring explicit user permission
last_updated: 2026-02-13
---

# Authorization Policies

This file consolidates all authorization requirements.
Other rule files reference this as the single source of truth.

## Authorization Matrix

| Operation Category | Authorization Level | Authorizing Keywords | Notes |
|-------------------|---------------------|---------------------|-------|
| **Git:
  commit (worktree)** | ALLOWED | - | In `.worktrees/` directory, commit freely with atomic commits |
| **Git:
  commit (main checkout)** | EXPLICIT | "commit", "git commit" | Must confirm message before executing |
| **Git:
  push** | EXPLICIT | "push" | Requires commit first |
| **Git:
  merge** | EXPLICIT | "merge" | History-modifying operations |
| **Git:
  rebase** | REFUSE | - | Never rebase. Suggest merge instead. |
| **Git:
  staging** | SUGGEST | - | Can suggest; never use `git add -A` or `git add .` |
| **Package:
  install** | EXPLICIT | "install", "add" + package name | Inform which packages before executing |
| **Package:
  update** | EXPLICIT | "update", "upgrade" + package name | Show version changes |
| **Package:
  remove** | EXPLICIT | "remove", "uninstall" + package name | Confirm before removing |
| **Refactoring:
  small** | ALLOWED | - | <10 lines, within scope of user's request |
| **Refactoring:
  medium** | CONFIRM | - | 50-200 lines, present plan first |
| **Refactoring:
  large** | EXPLICIT | - | >200 lines, detailed plan + approval |
| **Security:
  auth changes** | EXPLICIT | - | Any authentication/authorization logic |
| **Security:
  secrets** | REFUSE | - | Never write hardcoded secrets |
| **Database:
  schema** | EXPLICIT | - | Migrations, DDL operations |
| **Database:
  data modification** | EXPLICIT | - | UPDATE, DELETE on production data |
| **File:
  create** | ALLOWED | - | Only when necessary for task |
| **File:
  delete** | EXPLICIT | "delete", "remove" + file | Confirm before deleting |
| **ML:
  model training** | EXPLICIT | "train", "fit" | Resource-intensive operations |
| **ML:
  model deployment** | EXPLICIT | "deploy", "publish" | Production-affecting operations |
| **Network:
  download** | EXPLICIT | "download", "fetch", "get" | Any curl, wget, or file downloads |

## Authorization Levels

| Level | Meaning |
|-------|---------|
| **EXPLICIT** | User must use specific keywords. Ambiguous phrases do NOT authorize. |
| **CONFIRM** | Present plan and wait for approval before proceeding. |
| **SUGGEST** | Can suggest the operation; wait for user response before executing. |
| **ALLOWED** | Can proceed without asking, within scope of user's request. |
| **REFUSE** | Never perform, even if explicitly requested. Explain why and offer alternatives. |

## Phrases That Do NOT Authorize

| Phrase | Correct Response |
|--------|------------------|
| "Save this" / "Save my work" | Ask: commit, stage, or just edit? |
| "Fix the import error" | Explain what's needed, ask permission to install |
| "Make this work" | Identify specific operations, ask permission |
| "Finish this feature" | Complete code, inform ready to commit |
| "Set up the project" | Ask which dependencies to install |
| "Push this to the repo" | Inform commit needed first, ask for both |
| "Install this" / "Get this for me" | Ask permission before downloading files |

## Git Operations Quick Reference

**CRITICAL:
All git operations MUST use the git MCP server tools.** Direct `git` commands
via `launch-process` are blocked.
See `git-mcp-required.md`.

**Worktree exception:** When working in a `.worktrees/` directory,
`git_commit_git` is allowed without permission.
Commits should be atomic and well-structured.
Enforced by `worktree_commit_guard.sh` hook.

**Prohibited without explicit permission (main checkout):** `git_commit_git`,
`git_push_git`, `git_merge_git`, `git_reset_git` (hard), `git_clean_git`,
`git_branch_git` (force delete), `git_cherry_pick_git`

**NEVER use (REFUSE):** `git_rebase_git` - rebase is prohibited.
Suggest merge instead.

**Allowed (read-only):** `git_status_git`, `git_diff_git`, `git_log_git`,
`git_show_git`, `git_fetch_git`

**CRITICAL**:
Never use `git_add_git` with `all:
true` - always stage specific files.

## Refactoring Scope Quick Reference

| Scope | Lines | Authorization |
|-------|-------|---------------|
| Small | <10 | Proceed if within user's request scope |
| Medium | 50-200 | Present plan, wait for confirmation |
| Large | >200 | Detailed plan with risks, explicit approval |

**Never refactor without permission:** Public APIs, database schema, config
formats, build scripts.

## Security Quick Reference

**Always refuse:** Hardcoded secrets, committing secrets, SQL injection
vulnerabilities.

**Always require permission:** Auth logic, authorization rules, CORS, session
management.

## Cross-Reference

Referenced by:
`core-development-rules.md`, `git-workflow.md`, `python-development.md`,
`refactoring-and-maintenance.md`, `security.md`, `data-science-ml-patterns.md`
