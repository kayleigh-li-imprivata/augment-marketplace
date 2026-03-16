---
name: finishing-a-development-branch
description: Use when AI completes work in a worktree - walks through changes and offers to merge into user's current branch
---

# Finishing a Development Branch

## Overview

When AI completes implementation work in a worktree, walk through the changes
with the user and offer to merge into their current branch.

**Core principle:** Verify tests → Present summary → Offer walk-through → Merge
to user's branch.

**AI initiates this flow when work is complete** (tests pass, task fulfilled).

## The Process

### Step 1: Verify Tests

**Before presenting summary, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Fix them.
Don't proceed until tests pass.

### Step 2: Present Summary

Present a concise summary of the work:

```text
Work complete on `feature/user-auth`.

Changes:
- Added OAuth2 provider (3 files)
- Updated user model with auth fields (1 file)
- Added tests (2 files)

6 files changed, 247 insertions, 12 deletions
Tests: 42 passed

Would you like to:
1. Walk through changes file-by-file
2. Merge into your current branch (`develop`)
3. Keep the branch for later
```

### Step 3: Handle Choice

**If walk-through requested:**

For each changed file:

1. Show the file path and change summary
2. Explain what the changes do
3. Ask "Continue to next file?" or "Questions?"

After walk-through, re-offer merge.

**If merge requested:**

1. Switch to user's main checkout
2. Identify user's current branch
3. Merge the worktree branch into it
4. Clean up worktree (Step 4)

**If keep for later:**

Report:
"Keeping branch `<name>`.
Worktree at `<path>`." Don't clean up.

### Step 4: Cleanup Worktree

After merge:

```bash
git worktree remove <worktree-path>
```

If keeping for later, don't clean up.

## Quick Reference

| Choice | Merge | Cleanup Worktree |
|--------|-------|------------------|
| Walk-through | After review | After merge |
| Merge now | Yes | Yes |
| Keep for later | No | No |

## Red Flags

**Never:**

- Proceed with failing tests
- Merge without verifying tests on result

**Always:**

- Verify tests before presenting summary
- Offer walk-through option
- Clean up worktree after merge

## Integration

**Initiated by AI** when implementation work is complete (tests pass, task
fulfilled).

**Pairs with:**

- **using-git-worktrees** - Cleans up worktree created by that skill
