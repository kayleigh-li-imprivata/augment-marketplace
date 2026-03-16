---
name: git-workflow
description: Use when working with git - conventional commits, branch naming, PR guidelines, merge strategies, and workflow best practices
---

# Git Workflow

Use this skill when working with git commits, branches, PRs, or version control
workflows.

## Conventional Commits Format

`<type>(<scope>):
<description>`

**Keep concise:** Subject line 50-72 chars, imperative mood, no period.

**Types:**

| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Formatting (no code change) |
| `refactor` | Code restructuring |
| `perf` | Performance |
| `test` | Tests |
| `build` | Build/dependencies |
| `ci` | CI/CD config |
| `chore` | Other maintenance |

**Examples:**

```text
feat(auth): add OAuth2 support
fix(api): resolve race condition in user creation
refactor(database): simplify query builder
```

**Breaking changes:** Add `!` after type:
`feat(api)!:
change auth response`

**Body:** Only when necessary.
Most commits should be subject-line only.

## Commit Workflows

### In Worktrees (`.worktrees/` directory)

Commit freely without asking permission:

- Make atomic commits (one logical change per commit)
- Use conventional commit format
- Commit as work progresses, not one giant commit at the end

### In Main Checkout

Confirmation required:

1. User requests commit (explicit language required)
2. AI generates concise Conventional Commit message
3. AI presents message and asks:
   "Is this acceptable?
   (yes/no/modify)"
4. AI waits for confirmation before executing
5. If user provides own message, validate format and suggest corrections

## Branch Naming

**Pattern:** `<type>/<description>` with lowercase and hyphens.

| Branch Type | From | Purpose |
|-------------|------|---------|
| `main` | - | Production-ready |
| `develop` | - | Integration branch |
| `feature/<desc>` | develop | New features |
| `fix/<desc>` | develop or main | Bug fixes (all types) |

**Examples:**

```text
feature/user-authentication
feature/123-oauth-integration
fix/login-validation
fix/security-patch
```

## Merge Strategy

**Prefer merge over rebase** for shared branches:

```javascript
// Merge feature into develop
git_checkout_git({ target: "develop" })
git_merge_git({ branch: "feature/user-auth", noFastForward: true })
```

**Exception:** Use rebase to clean up your own branch before merging.

**Never rebase:** `main`, `develop`, or any shared branch.

## PR Guidelines

**Title:** Follow conventional commit format.

**Description checklist:**

- Brief description of changes
- Type of change (bug fix, feature, breaking, docs)
- List of specific changes made
- How it was tested
- Related issues (Closes #123)

**Best practices:**

- Keep PRs < 500 lines when possible
- Include tests for new functionality
- Ensure CI passes before review
- Respond to comments promptly

## Workflow Processes

### Feature Development

1. `git_checkout_git({ target:
   "feature/x", createBranch:
   true, startPoint:
   "develop" })`
2. Make commits following conventional format
3. `git_push_git({ setUpstream:
   true })` and create PR
4. Address review, merge to develop, delete branch

### Fix Process

1. Branch from main or develop:
   `fix/critical-bug`
2. Fix and commit
3. Merge to target branch
4. If from main, also merge to develop to sync
5. Delete fix branch

## Edge Cases

### Uncommitted Changes + Branch Switch

Ask user:
"You have uncommitted changes.
(a) commit, (b) stash, or (c) discard?" Do NOT automatically choose.

### "Save My Work"

This means "write to files" (already done), NOT "commit".
Respond:
"Changes saved to files.
Would you like to commit them?"

### Creating PRs

If changes aren't committed, inform user and get explicit commit authorization
first, then separate authorization for push/PR.

### Amending Commits

Treat as equivalent to new commit - requires explicit permission.
Warn if already pushed (will require force push).

### Interactive Rebase

Requires explicit permission.
Explain what happens.
Warn if commits already pushed (will require force push).
