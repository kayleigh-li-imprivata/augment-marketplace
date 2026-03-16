# Issue Resolver Agent

## Purpose
Automatically resolve GitHub issues by analyzing the issue description and
comments, proposing implementation approaches, creating a feature branch,
implementing the solution, and creating a PR.

## Prerequisites
- ✅ GitHub CLI (`gh`) is installed and authenticated
- ✅ Repository:
  `imprivata-ai/workstation-clustering`
- ✅ User has write access to create branches and PRs

## CRITICAL: Agent Auto Mode Required

⚠️ **This agent REQUIRES "Agent Auto" mode to function properly.**

When you see "resolve ticket 89", you MUST:
1. Switch to **Agent Auto** mode in the Augment panel
2. Then execute the workflow

**Why?** This workflow uses `gh` CLI commands, creates branches, makes code
changes, and creates PRs that require autonomous execution.

## Trigger Phrases

Any of these phrases should trigger this agent:
- "Resolve ticket 89"
- "Resolve issue 89"
- "Fix ticket 89"
- "Fix issue 89"
- "Implement ticket 89"
- "Implement issue 89"

## Workflow

When triggered, follow these steps IN ORDER:

### Step 1: Extract Issue Number and Fetch Issue Data

Extract the issue number from the trigger phrase and fetch issue details:

```bash
# Extract issue number from user input (e.g., "resolve ticket 89" -> 89)
ISSUE_NUMBER=<extracted_number>

# Get issue details
ISSUE_DATA=$(gh issue view $ISSUE_NUMBER --repo imprivata-ai/workstation-clustering --json title,body,url,labels,assignees,state)

TITLE=$(echo "$ISSUE_DATA" | jq -r '.title')
BODY=$(echo "$ISSUE_DATA" | jq -r '.body')
URL=$(echo "$ISSUE_DATA" | jq -r '.url')
STATE=$(echo "$ISSUE_DATA" | jq -r '.state')
LABELS=$(echo "$ISSUE_DATA" | jq -r '.labels[].name' | tr '\n' ', ')

echo "Analyzing issue #$ISSUE_NUMBER: $TITLE"
echo "State: $STATE"
echo "Labels: $LABELS"
echo "URL: $URL"
```

**Validation:**
- If issue is already closed, ask user if they want to reopen or create a new
  implementation
- If issue is assigned to someone else, warn user and ask for confirmation

### Step 2: Fetch Issue Comments

Get all comments on the issue to understand context and requirements:

```bash
# Get all comments
COMMENTS=$(gh api /repos/imprivata-ai/workstation-clustering/issues/$ISSUE_NUMBER/comments)

# Parse comments
echo "$COMMENTS" | jq -r '.[] | "[\(.user.login)] \(.body)"'
```

Extract from comments:
- Additional requirements or clarifications
- Suggested approaches or solutions
- Related issues or PRs
- Technical constraints or considerations

### Step 3: Analyze Issue and Generate Implementation Approaches

Use `codebase-retrieval` to understand the codebase context:

**Questions to answer:**
- What part of the codebase does this issue relate to?
- Are there similar implementations or patterns in the codebase?
- What files will likely need to be modified?
- What tests will need to be added or updated?
- Are there any dependencies or related components?

**Generate 2-3 implementation approaches:**
- **Approach 1 (Recommended):** Most aligned with existing patterns
- **Approach 2 (Alternative):** Different trade-offs (e.g., performance vs
  simplicity)
- **Approach 3 (Minimal):** Smallest change to address the issue

For each approach, identify:
- Files to create/modify
- Key changes needed
- Pros and cons
- Estimated complexity
- Testing strategy

### Step 4: Create Temporary Analysis File

Create a markdown file with the analysis and proposed approaches:

```bash
ANALYSIS_FILE="issue_${ISSUE_NUMBER}_analysis.md"

cat > "$ANALYSIS_FILE" << 'EOF'
# Issue Resolution Analysis - #<issue_number>

**Title:** <title>
**URL:** <url>
**State:** <state>
**Labels:** <labels>

---

## Issue Description

<body>

---

## Comments Summary

<summary of key points from comments>

---

## Codebase Context

<findings from codebase-retrieval>

---

## Proposed Implementation Approaches

### ✅ Approach 1: <name> (Recommended)

**Description:**
<what this approach does>

**Files to modify:**
- `path/to/file1.py` - <what changes>
- `path/to/file2.py` - <what changes>

**Files to create:**
- `path/to/new_file.py` - <purpose>

**Tests to add/update:**
- `tests/test_file.py` - <what to test>

**Pros:**
- ✅ <advantage 1>
- ✅ <advantage 2>

**Cons:**
- ❌ <disadvantage 1>

**Complexity:** Medium

---

### 🔄 Approach 2: <name> (Alternative)

[Same structure as Approach 1]

---

### 🎯 Approach 3: <name> (Minimal)

[Same structure as Approach 1]

---

## Recommendation

I recommend **Approach 1** because <reasoning>.

EOF

echo "Analysis saved to: $ANALYSIS_FILE"
```

Save to:
`issue_<number>_analysis.md` in the workspace root.

### Step 5: Present Analysis and Ask for Approval

⚠️ **MANDATORY CHECKPOINT - STOP HERE AND ASK FOR APPROVAL**

Present a concise summary in chat:

```
🎯 Issue Resolution Analysis - #<number>: <title>

**Issue:** <one-line summary>
**URL:** <url>
**Comments:** <key points from comments>

---

**Proposed Approaches:**

✅ **Approach 1 (Recommended): <name>**
- Files to modify: <count> files
- Files to create: <count> files
- Tests to add: <count> tests
- Complexity: <level>
- Why: <brief reasoning>

🔄 **Approach 2 (Alternative): <name>**
- Files to modify: <count> files
- Complexity: <level>
- Trade-off: <key difference>

🎯 **Approach 3 (Minimal): <name>**
- Files to modify: <count> files
- Complexity: <level>
- Trade-off: <key difference>

---

📄 Full analysis saved to: issue_<number>_analysis.md

**Recommendation:** Approach 1 - <brief reasoning>

---

Proceed with Approach 1? (yes/no/2/3)
```

**Rules:**
- ✅ Keep summary concise (under 20 lines)
- ✅ Highlight key differences between approaches
- ✅ Provide clear recommendation with reasoning
- ✅ Ask for approval before proceeding
- ❌ Do NOT start implementation without approval

### Step 6: Create Feature Branch (After Approval)

Only proceed if user approves an approach:

```bash
# Ensure we're on main/dev branch
git checkout main
git pull origin main

# Create feature branch with descriptive name
BRANCH_NAME="fix/issue-${ISSUE_NUMBER}-<short-description>"

git checkout -b "$BRANCH_NAME"

echo "Created branch: $BRANCH_NAME"
```

**Branch naming convention:**
- `fix/issue-<number>-<short-description>` for bug fixes
- `feat/issue-<number>-<short-description>` for new features
- `refactor/issue-<number>-<short-description>` for refactoring

Determine type from issue labels or description.

### Step 7: Implement the Solution

Based on the approved approach, implement the changes:

**For each file to modify:**
1. Use `codebase-retrieval` to understand current implementation
2. Use `view` to read the file
3. Use `str-replace-editor` to make changes
4. Explain each change as you make it

**For each file to create:**
1. Use `codebase-retrieval` to find similar files for patterns
2. Use `save-file` to create the new file
3. Follow project coding standards (see `~/.augment/rules/coding-standards.md`)

**Important implementation guidelines:**
- ✅ Follow existing code patterns and architecture
- ✅ Add docstrings to all new functions
- ✅ Use Pydantic models for data classes
- ✅ Add type hints to all functions
- ✅ Keep functions modular and single-responsibility
- ✅ Add comments only for non-obvious logic
- ❌ No imports inside functions
- ❌ No nested functions

### Step 8: Add/Update Tests

For every code change, add or update tests:

**Test requirements:**
- ✅ Follow Arrange-Act-Assert (AAA) pattern
- ✅ Use pytest fixtures for setup
- ✅ Use parametrized tests for multiple cases
- ✅ Test new behaviors, edge cases, and error conditions
- ✅ Add `@pytest.mark.target()` decorator to mark test targets
- ✅ Keep assertions clean and readable

**Find existing tests:**
```bash
# Find related test files
find tests -name "*test_*.py" | grep <related_module>
```

Use `codebase-retrieval` to find existing test patterns and fixtures.

### Step 9: Update Documentation

Update documentation if needed:

**Files to check:**
- README.md (if public API changed)
- Docstrings (update if behavior changed)
- Inline comments (add for complex logic)
- Specs/design docs (if architecture changed)

### Step 10: Run Tests Locally

Run tests to verify the implementation:

```bash
# Run all tests
uv run pytest -n auto

# Run specific tests
uv run pytest tests/test_<module>.py -v

# Run with coverage
uv run pytest --cov=src --cov-report=term-missing
```

**If tests fail:**
- Analyze failures
- Fix issues
- Re-run tests
- Repeat until all tests pass

### Step 11: Ask for Approval to Commit and Push

⚠️ **MANDATORY CHECKPOINT - STOP HERE AND ASK FOR APPROVAL**

After all tests pass, present a summary:

```
✅ Implementation Complete - Issue #<number>

**Changes made:**
- Modified: <list of modified files>
- Created: <list of new files>
- Tests: <count> tests added/updated

**Tests:** ✅ All passing (<count> tests, <coverage>% coverage)

**Branch:** <branch_name>

**Summary of changes:**
1. <change 1>
2. <change 2>
3. <change 3>

---

Commit and push changes? (yes/no)
```

**Do NOT commit or push without explicit user approval.**

### Step 12: Commit Changes (Only After Approval)

Only proceed if user approves:

```bash
# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "<type>: <short description>

<detailed description of changes>

Fixes #<issue_number>"

# Example:
# git commit -m "feat: add customer validation endpoint
#
# - Add new /validate endpoint to check customer credentials
# - Implement CustomerValidator class with retry logic
# - Add comprehensive tests for validation scenarios
# - Update API documentation
#
# Fixes #89"
```

**Commit message format:**
- First line:
  `<type>:
  <short description>` (50 chars max)
- Types:
  `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- Body:
  Detailed description of changes
- Footer:
  `Fixes #<issue_number>` to auto-close issue

### Step 13: Push to Remote

Push the branch to remote:

```bash
# Push branch to remote
git push origin "$BRANCH_NAME"

echo "Pushed to: origin/$BRANCH_NAME"
```

### Step 14: Create Pull Request

Create a PR using `gh`:

```bash
# Create PR with title and body
gh pr create \
  --repo imprivata-ai/workstation-clustering \
  --base main \
  --head "$BRANCH_NAME" \
  --title "<type>: <short description>" \
  --body "## Description

<detailed description of changes>

## Changes
- <change 1>
- <change 2>
- <change 3>

## Testing
- <test 1>
- <test 2>

## Related Issues
Fixes #<issue_number>

## Checklist
- [x] Tests added/updated
- [x] Documentation updated
- [x] All tests passing locally
- [x] Follows project coding standards"

# Get PR URL
PR_URL=$(gh pr view --json url --jq '.url')
echo "PR created: $PR_URL"
```

### Step 15: Clean Up Analysis File

After PR is created successfully, remove the analysis file:

```bash
# Remove the analysis file
rm -f "$ANALYSIS_FILE"
echo "Removed analysis file: $ANALYSIS_FILE"
```

### Step 16: Present Final Summary

Present the final summary to the user:

```
🎉 Issue #<number> Resolution Complete!

**Issue:** <title>
**Branch:** <branch_name>
**PR:** <pr_url>

**Changes:**
- Modified: <count> files
- Created: <count> files
- Tests: <count> tests added/updated
- Coverage: <coverage>%

**Next Steps:**
1. Review the PR: <pr_url>
2. Wait for CI to pass
3. Request reviews from team members
4. Merge when approved

**Note:** The PR will automatically close issue #<number> when merged.
```

## Important Notes

1. **Extract issue number from trigger** - Parse "resolve ticket 89" to get
   issue number
2. **Analyze issue thoroughly** - Read description and all comments
3. **Propose multiple approaches** - Give user options with trade-offs
4. **Use codebase-retrieval extensively** - Understand context before
   implementing
5. **Follow project standards** - Maintain consistency with existing code
6. **Update ALL related files** - Code, tests, docs, configs
7. **Run tests before committing** - Ensure implementation works
8. **Ask for approval TWICE** - Once before implementing, once before
   committing/pushing
9. **Create descriptive PR** - Include context, changes, testing, and link to
   issue
10. **Clean up after success** - Remove analysis file after PR is created
11. **NEVER commit or push without approval** - Always wait for explicit user
    confirmation

## Configuration

**Default base branch:** `main` (check repo default)

**Branch naming:**
- Bug fixes:
  `fix/issue-<number>-<description>`
- Features:
  `feat/issue-<number>-<description>`
- Refactoring:
  `refactor/issue-<number>-<description>`

**Commit message format:** Conventional Commits (feat, fix, refactor, etc.)

**PR template:** Include description, changes, testing, related issues,
checklist

**Analysis file location:** `issue_<number>_analysis.md` in workspace root

**Cleanup:** Remove analysis file after PR is created

## Example Usage

```
User: "Resolve ticket 89"

Agent:
1. Extracts issue number (89)
2. Fetches issue details and comments
3. Uses codebase-retrieval to understand context
4. Generates 3 implementation approaches
5. Creates issue_89_analysis.md
6. Presents summary with recommendation
7. Asks: "Proceed with Approach 1? (yes/no/2/3)"

User: "yes"

Agent:
8. Creates feature branch: fix/issue-89-customer-validation
9. Implements the solution (modifies files, adds tests)
10. Runs tests locally
11. Tests pass!
12. Asks: "Commit and push changes? (yes/no)"

User: "yes"

Agent:
13. Commits with descriptive message
14. Pushes to remote
15. Creates PR with detailed description
16. Removes issue_89_analysis.md
17. Presents final summary with PR link
```

## Self-Check Before Responding

**After Step 4 (Analysis Complete):**
- [ ] Did I analyze the issue and comments thoroughly?
- [ ] Did I use codebase-retrieval to understand context?
- [ ] Did I generate 2-3 distinct approaches?
- [ ] Did I create the analysis markdown file?
- [ ] **STOP!
  Go to Step 5 and ask for approval**

**At Step 5 (Presenting Summary):**
- [ ] Did I present a concise summary?
- [ ] Did I ask "Proceed with Approach X?
  (yes/no/2/3)"?
- [ ] **STOP!
  Wait for user's approval**

**At Step 11 (Implementation Complete):**
- [ ] Did all tests pass?
- [ ] Did I update all related files (code, tests, docs)?
- [ ] Did I ask "Commit and push changes?
  (yes/no)"?
- [ ] **STOP!
  Wait for user's approval**

**At Step 14 (Creating PR):**
- [ ] Did I get explicit approval to commit and push?
- [ ] Did I create a descriptive PR with all required sections?
- [ ] Did I link the PR to the issue with "Fixes #<number>"?

**If you answered "no" to any checkbox, STOP and fix it before responding.**

## Notes

- Always use `codebase-retrieval` to understand context before making changes
- Follow existing patterns and architecture in the codebase
- Provide multiple approaches to give user flexibility
- Be thorough in testing - add tests for new behaviors and edge cases
- Create descriptive commits and PRs for better code review
- Clean up temporary files after successful completion
