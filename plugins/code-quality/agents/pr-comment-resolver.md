# PR Comment Resolver Agent

## Purpose
Automatically address review comments on your own PRs by analyzing validity,
proposing fixes, and updating all relevant files (code, tests, docs, configs).

## Prerequisites
- ✅ GitHub CLI (`gh`) is installed and authenticated
- ✅ Repository:
  `imprivata-ai/workstation-clustering`
- ✅ You are on the correct branch for the PR

## CRITICAL: Agent Auto Mode Required

⚠️ **This agent REQUIRES "Agent Auto" mode to function properly.**

When you see "Address comments on PR #XXX", you MUST:
1. Switch to **Agent Auto** mode in the Augment panel
2. Then execute the workflow

**Why?** This workflow uses `gh` CLI commands and makes code changes that
require autonomous execution.

## Trigger Phrases

Any of these phrases should trigger this agent:
- "Address comments on PR #123"
- "Address PR #123 comments"
- "Address comments on PR 123"
- "Resolve PR 123 comments"
- "Resolve comments for PR 123"

## Workflow

When triggered, follow these steps IN ORDER:

### Step 1: Verify Branch

Check that the user is on the correct branch for the PR:

```bash
# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Get PR branch
PR_BRANCH=$(gh pr view <number> --repo imprivata-ai/workstation-clustering --json headRefName --jq '.headRefName')

# Compare
if [ "$CURRENT_BRANCH" != "$PR_BRANCH" ]; then
  echo "⚠️ You are on branch '$CURRENT_BRANCH' but PR #<number> is for branch '$PR_BRANCH'"
  echo "Please switch branches: git checkout $PR_BRANCH"
  exit 1
fi
```

If branches don't match, ask user to switch branches and stop.

### Step 2: Fetch All Comments

Fetch both inline and general comments:

```bash
# Get inline review comments (attached to specific lines)
INLINE_COMMENTS=$(gh api /repos/imprivata-ai/workstation-clustering/pulls/<number>/comments)

# Get general PR comments (conversation tab)
GENERAL_COMMENTS=$(gh api /repos/imprivata-ai/workstation-clustering/issues/<number>/comments)
```

Parse and extract:
- Comment ID, author, body
- File path and line number (for inline comments)
- Created/updated timestamps
- Whether comment is from a bot or human

**Filter out:**
- Bot-generated summaries (e.g., Augment PR Summary)
- Comments that are just reactions or "LGTM"
- Comments already marked as resolved

### Step 3: Analyze Each Comment for Validity

For each comment, determine:

**Is it valid and actionable?**
- ✅ **VALID**:
  Points to a real issue (bug, security, performance, code quality)
- ✅ **VALID**:
  Suggests improvement that aligns with project standards
- ✅ **VALID**:
  Identifies missing tests, docs, or error handling
- ❌ **NOT VALID**:
  Subjective style preference that conflicts with project standards
- ❌ **NOT VALID**:
  Already addressed in a later commit
- ❌ **NOT VALID**:
  Misunderstands the code's purpose
- ❌ **NOT VALID**:
  Suggests defensive checks for scenarios that cannot happen (e.g., checking for
  null when guaranteed by workflow triggers or branch protection)
- ⚠️ **DEBATABLE**:
  Valid point but may have trade-offs

**IMPORTANT:
If you and the user have already discussed a comment and decided not to address
it:**
- Treat the comment as **NOT VALID**
- Write a short response explaining the reasoning from your discussion
- Do NOT implement the suggested change

Use `codebase-retrieval` to:
- Understand the context of the code being commented on
- Check if similar patterns exist elsewhere in the codebase
- Verify if the suggestion aligns with project conventions

### Step 4: Present Summary and Propose Fixes

Present findings in this format:

```
📋 PR #<number> Comment Analysis

Found X comments to address:

---
Comment #1 (by @username)
Location: src/file.py:42
Comment: "Missing null check for user input"

✅ VALID - Should address
Issue: Function doesn't validate input before processing
Proposed Fix:
- Add input validation at line 42
- Raise ValueError for invalid input
- Update docstring to document validation
- Add test case for invalid input

Files to update:
- src/file.py (add validation)
- tests/test_file.py (add test case)
- src/file.py (update docstring)

---
Comment #2 (by @username)
Location: src/api.py:100
Comment: "Use snake_case instead of camelCase"

❌ NOT VALID - Will not address
Reason: Project uses camelCase for API response fields to match external API contract (see api.py:10-50). This is intentional and documented in specs/api-design.md.

---
Comment #3 (by @username)
Location: General
Comment: "Consider adding integration tests"

⚠️ DEBATABLE - Needs discussion
Reason: Valid suggestion but integration tests require Docker setup. This could be a follow-up PR.
Recommendation: Respond to comment explaining this is tracked in issue #456.

---

Apply fixes for valid comments? (yes/no/selective)
```

### Step 5: Apply Fixes (After Approval)

For each VALID comment that user approves:

1. **Make the code change** using `str-replace-editor`
2. **Update related files**:
   - Tests (add/update test cases)
   - Docstrings (update function documentation)
   - Type hints (add/fix type annotations)
   - Comments (add explanatory comments if needed)
   - README/docs (update if public API changed)
   - Config files (update helm charts, workflows if needed)
   - Error messages (update if error handling changed)

3. **Use `codebase-retrieval`** to find ALL downstream changes:
   - Find all callers of modified functions
   - Find all implementations of modified interfaces
   - Find all tests that need updates
   - Find all docs that reference changed behavior

4. **Verify completeness**:
   - Check that all imports are correct
   - Check that all type hints are consistent
   - Check that all tests still make sense

### Step 6: Run Tests

After applying all fixes:

```bash
# Run tests to verify fixes don't break anything
uv run pytest -n auto

# If tests fail, analyze failures and fix them
# Repeat until all tests pass
```

### Step 7: Ask for Approval to Commit and Push

**IMPORTANT:
Do NOT commit or push without explicit user approval.**

After all tests pass, present a summary:

```
✅ All tests passed!

Changes made:
- Fixed <issue 1> in <file>
- Updated <file> to address <issue 2>
- Added tests for <scenario>

Ready to commit and push these changes to PR #<number>?
(yes/no)
```

### Step 8: Commit and Push (Only After Approval)

Only proceed if user approves:

```bash
# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "Address PR review comments

- Fix: <summary of fix 1>
- Fix: <summary of fix 2>
- Update tests and docs accordingly

Addresses comments from @reviewer1, @reviewer2"

# Push to PR branch
git push origin <branch-name>
```

### Step 9: Respond to Comments (Optional)

For each addressed comment, optionally post a reply:

```bash
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/imprivata-ai/workstation-clustering/pulls/<number>/comments/<comment_id>/replies \
  -f body="✅ Fixed in <commit_sha>. Added validation and test case as suggested."
```

For NOT VALID comments, explain why:

```bash
gh pr comment <number> --body "Re: comment on line 100 - We use camelCase for API fields to match external contract (see specs/api-design.md). This is intentional."
```

## Important Notes

1. **Always verify branch first** - Don't make changes on wrong branch
2. **Use codebase-retrieval extensively** - Understand context before changing
   code
3. **Update ALL related files** - Tests, docs, configs, not just the code
4. **Run tests before committing** - Ensure fixes don't break anything
5. **Be thorough** - Find all downstream changes needed
6. **Explain decisions** - For comments you don't address, explain why
7. **Ask for approval TWICE** - Once before making changes, once before
   committing/pushing
8. **NEVER commit or push without approval** - Always wait for explicit user
   confirmation

## Configuration

**Comment types to address:**
- Security issues (always)
- Bugs (always)
- Missing tests (always)
- Code quality (if valid)
- Style (only if aligns with project standards)

**Comment types to skip:**
- Bot summaries
- "LGTM" / "+1" reactions
- Already resolved
- Purely subjective preferences

**Files to check for updates:**
- Source code (obviously)
- Tests (always)
- Docstrings (if function behavior changed)
- Type hints (if signatures changed)
- README.md (if public API changed)
- Helm charts (if config/deployment changed)
- GitHub workflows (if CI/CD affected)
- Specs/docs (if requirements changed)
