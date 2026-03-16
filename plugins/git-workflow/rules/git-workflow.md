---
type: always_apply
priority: HIGH
description: Critical git constraints - MCP tools, staging rules, authorization
last_updated: 2026-02-19
---

# Git Workflow - Critical Constraints

For detailed conventions (commits, branches, PRs), see the `git-workflow` skill.

## CRITICAL: Use Git MCP Server Tools

**All git operations MUST use git MCP server tools.** Direct `git` commands via
`launch-process` are blocked.

See `git-mcp-required.md` for complete tool reference.

## CRITICAL: Staging Rules

**NEVER use `git_add_git` with `all:
true`** - stages all changes indiscriminately.

**ALWAYS stage specific files:**

```javascript
git_add_git({ files: ["path/to/file1.py", "path/to/file2.py"] })
```

**Before committing:** Review staged files with `git_status_git`.

**Exception:** None.
Always use explicit file paths.

## Authorization Requirements

| Operation | Authorization | Notes |
|-----------|---------------|-------|
| `git_commit_git` | EXPLICIT | Must confirm message first |
| `git_push_git` | EXPLICIT | Requires commit first |
| `git_merge_git` | EXPLICIT | History-modifying |
| `git_rebase_git` | REFUSE | Never rebase. Suggest merge instead. |
| `git_reset_git` (hard) | EXPLICIT | Destructive |
| `git_add_git` | SUGGEST | Suggest files, never auto-stage all |

## Commit Confirmation (Required)

1. User requests commit with explicit language
2. AI proposes Conventional Commit message
3. AI asks:
   "Is this acceptable?
   (yes/no/modify)"
4. AI waits for confirmation before executing

## Ambiguous Phrases - Do NOT Interpret as Commit

| Phrase | Response |
|--------|----------|
| "Save my work" | "Changes saved to files. Would you like to commit?" |
| "Save this" | Ask: commit, stage, or just edit? |
| "Create a PR" | Check if committed first, get explicit authorization |

## CRITICAL: Merge Conflict Resolution

**NEVER resolve merge conflicts by blindly checking out entire files from one
branch.**

Each conflict region must be considered individually:

1. **Understand both sides**:
   Before resolving, understand what each branch intended
2. **Review the PR/commit context**:
   Check PR descriptions, commit messages, and review comments to understand the
   intent of changes
3. **Resolve conflict-by-conflict**:
   Use `str-replace-editor` to fix each conflict region individually, not `git
   checkout <branch> -- <file>`
4. **Preserve intentional changes**:
   Both branches may have valid changes that need to be merged together, not one
   discarded
5. **Ask when uncertain**:
   If the correct resolution is unclear, ask the user rather than guessing

**Prohibited approaches:**

- `git checkout origin/dev -- <file>` (discards all feature branch changes)
- `git checkout --ours <file>` or `git checkout --theirs <file>` (picks one side
  entirely)
- Assuming "take the newer branch" is correct

**Required approach:**

```text
1. View the conflicted file to see all conflict markers
2. For each <<<<<<< ... ======= ... >>>>>>> region:
   a. Understand what HEAD (current branch) changed and why
   b. Understand what the incoming branch changed and why
   c. Determine the correct resolution (may be combination of both)
   d. Edit to remove markers and create correct merged content
3. After all conflicts resolved, verify no conflict markers remain
4. Stage the resolved file
```

## Never Commit

- Secrets, API keys, sensitive data
- Large binary files (use Git LFS)
- Generated files, build artifacts
- Debug code, temporary files
