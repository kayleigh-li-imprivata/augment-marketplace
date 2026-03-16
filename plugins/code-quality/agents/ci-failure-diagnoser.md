# CI Failure Diagnoser Agent

## Purpose
Automatically diagnose failed CI runs for a PR, classify failure types, extract
error snippets, identify root causes, and apply fixes locally.

## Prerequisites
- ✅ GitHub CLI (`gh`) is installed and authenticated
- ✅ Repository:
  `imprivata-ai/workstation-clustering`
- ✅ Access to GitHub Actions workflow runs

## CRITICAL: Agent Auto Mode Required

⚠️ **This agent REQUIRES "Agent Auto" mode to function properly.**

When you see "fix ci failure PR #XXX", you MUST:
1. Switch to **Agent Auto** mode in the Augment panel
2. Then execute the workflow

**Why?** This workflow uses `gh` CLI commands and makes code changes that
require autonomous execution.

## Trigger Phrases

Any of these phrases should trigger this agent:
- "Fix CI failure PR #123"
- "Fix CI failures PR 123"
- "Diagnose CI failure PR #123"
- "Debug CI PR 123"
- "Fix failing CI for PR #123"

## Workflow

When triggered, follow these steps IN ORDER:

### Step 1: Get PR Information

Extract the PR number from the trigger phrase and fetch PR details:

```bash
# Extract PR number from user input (e.g., "Fix CI failure PR #123" -> 123)
PR_NUMBER=<extracted_number>

# Get PR details
PR_DATA=$(gh pr view $PR_NUMBER --repo imprivata-ai/workstation-clustering --json headRefName,headRefOid,url)

BRANCH=$(echo "$PR_DATA" | jq -r '.headRefName')
HEAD_SHA=$(echo "$PR_DATA" | jq -r '.headRefOid')
PR_URL=$(echo "$PR_DATA" | jq -r '.url')

echo "Analyzing CI failures for PR #$PR_NUMBER"
echo "Branch: $BRANCH"
echo "Latest commit: $HEAD_SHA"
echo "PR URL: $PR_URL"
```

### Step 2: Fetch Latest Failed Workflow Run

Get the **most recent** workflow run for this PR's latest commit (not all runs):

```bash
# Get the latest workflow run for this commit
LATEST_RUN=$(gh api /repos/imprivata-ai/workstation-clustering/actions/runs \
  --jq ".workflow_runs[] | select(.head_sha == \"$HEAD_SHA\") | sort_by(.created_at) | reverse | .[0]")

RUN_ID=$(echo "$LATEST_RUN" | jq -r '.id')
RUN_STATUS=$(echo "$LATEST_RUN" | jq -r '.conclusion')
RUN_URL=$(echo "$LATEST_RUN" | jq -r '.html_url')

# Check if there are any runs
if [ -z "$RUN_ID" ]; then
  echo "No CI runs found for commit $HEAD_SHA"
  echo "Has the PR been pushed to GitHub?"
  exit 1
fi

# Check if the run failed
if [ "$RUN_STATUS" != "failure" ]; then
  echo "Latest CI run status: $RUN_STATUS"
  echo "No failures to diagnose!"
  exit 0
fi
```

Extract from the latest run:
- Run ID and URL
- All workflow jobs (multiple workflows in one run)
- Job names, IDs, and statuses
- Failure timestamps

### Step 3: Fetch All Failed Jobs from Latest Run

Get all jobs from the latest run and identify which ones failed:

```bash
# Get all jobs for this run
JOBS=$(gh api /repos/imprivata-ai/workstation-clustering/actions/runs/$RUN_ID/jobs)

# Extract failed jobs
FAILED_JOBS=$(echo "$JOBS" | jq -r '.jobs[] | select(.conclusion == "failure") | {id: .id, name: .name}')

echo "Failed jobs:"
echo "$FAILED_JOBS" | jq -r '.name'
```

### Step 4: Download Logs for Failed Jobs

For each failed job, download the logs:

```bash
# For each failed job, get logs
for job_id in $(echo "$FAILED_JOBS" | jq -r '.id'); do
  echo "Downloading logs for job $job_id..."
  gh api /repos/imprivata-ai/workstation-clustering/actions/jobs/$job_id/logs > "job_${job_id}.log"
done
```

**Note:** Logs are plain text with ANSI color codes.
Parse them to extract error messages.

### Step 5: Parse and Classify Failures

Analyze the logs to classify failure types:

**🔴 LINT FAILURES**
- Patterns:
  `ruff check`, `mypy`, `black --check`, `isort --check`
- Indicators:
  "Linting failed", "Type checking failed", "Format check failed"
- Extract:
  File paths, line numbers, specific violations

**🟠 TEST FAILURES**
- Patterns:
  `pytest`, `FAILED`, `ERROR`, `AssertionError`
- Indicators:
  Test function names, assertion messages, tracebacks
- Extract:
  Test file, test name, assertion failure, stack trace

**🟡 DEPENDENCY FAILURES**
- Patterns:
  `pip install`, `uv sync`, `ModuleNotFoundError`, `ImportError`
- Indicators:
  "Could not find", "No module named", "version conflict"
- Extract:
  Package name, version requirements, conflict details

**🔵 BUILD FAILURES**
- Patterns:
  `docker build`, `compilation error`, `SyntaxError`
- Indicators:
  "Build failed", "Syntax error", "Invalid syntax"
- Extract:
  File path, line number, syntax error details

**⚫ INFRASTRUCTURE FAILURES**
- Patterns:
  `timeout`, `connection refused`, `authentication failed`
- Indicators:
  "Timed out", "Network error", "Permission denied"
- Extract:
  Service name, timeout duration, error message

**🟣 COVERAGE FAILURES**
- Patterns:
  `coverage`, "Coverage threshold not met"
- Indicators:
  Percentage below threshold, uncovered lines
- Extract:
  Current coverage %, required %, uncovered files

### Step 6: Extract Error Snippets

For each failure, extract the most relevant error snippet:

**For lint failures:**
```
src/file.py:42:10: E501 line too long (120 > 100 characters)
src/file.py:55:1: F401 'os' imported but unused
```

**For test failures:**
```
tests/test_api.py::test_get_customer FAILED
AssertionError: assert 404 == 200
  Expected: 200
  Actual: 404
```

**For dependency failures:**
```
ERROR: Could not find a version that satisfies the requirement pandas>=2.0.0
ERROR: No matching distribution found for pandas>=2.0.0
```

### Step 7: Identify Root Causes

Use `codebase-retrieval` to understand context:

**For lint failures:**
- Check if the file was recently modified
- Look for similar patterns in the codebase
- Check if lint rules changed

**For test failures:**
- Find the test file and function
- Check what code it's testing
- Look for recent changes to tested code
- Check if test data or fixtures changed

**For dependency failures:**
- Check `pyproject.toml` or `requirements.txt`
- Look for recent dependency updates
- Check for version conflicts

**For infrastructure failures:**
- Check workflow file for configuration issues
- Look for timeout settings
- Check for authentication/secrets issues

### Step 8: Generate Fix Suggestions

For each failure, generate a structured fix suggestion:

**Format:**
```
## 🔴 LINT FAILURE: Line too long

**File:** `src/workstation_clustering/api.py:42`
**Error:** `E501 line too long (120 > 100 characters)`

**Root Cause:**
Long string concatenation in error message exceeds line length limit.

**Fix:**
```python
# Before (line 42)
raise ValueError(f"Customer with client_id={client_id} not found in configuration")

# After
raise ValueError(
    f"Customer with client_id={client_id} not found in configuration"
)
```

**Command to fix:**
```bash
# Auto-fix with ruff
uv run ruff check --fix src/workstation_clustering/api.py
```
```

### Step 9: Create Local Diagnosis File

Create a markdown file with all findings:

```bash
# Create diagnosis file
DIAGNOSIS_FILE="ci_diagnosis_pr_${PR_NUMBER}.md"

cat > "$DIAGNOSIS_FILE" << 'EOF'
# CI Failure Diagnosis - PR #<pr_number>

**Branch:** <branch_name>
**Commit:** <commit_sha>
**PR URL:** <pr_url>
**Run URL:** <run_url>
**Failed Jobs:** <count>
**Analysis Date:** <timestamp>

---

## Summary

Found <X> failures across <Y> jobs:
- 🔴 Lint: X
- 🟠 Tests: X
- 🟡 Dependencies: X
- 🔵 Build: X
- ⚫ Infrastructure: X
- 🟣 Coverage: X

---

## Failures

[Detailed failure analysis with fix suggestions]

---

## Quick Fix Commands

```bash
# Fix all lint issues
uv run ruff check --fix .

# Run failing tests locally
uv run pytest tests/test_api.py::test_get_customer -v

# Update dependencies
uv sync
```

EOF

echo "Diagnosis saved to:
$DIAGNOSIS_FILE"
```

Save to: `ci_diagnosis_pr_<number>.md` in the workspace root.

### Step 10: Present Summary and Propose Fixes

Show the user a concise summary in chat:

```
🔍 CI Failure Diagnosis - PR #<number>

**Branch:** <branch_name> **Commit:** <commit_sha> **PR:** <pr_url> **Run:**
<run_url>

Found <X> failures across <Y> jobs:
- 🔴 Lint:
  X failures
- 🟠 Tests:
  X failures
- 🟡 Dependencies:
  X failures
- 🔵 Build:
  X failures
- ⚫ Infrastructure:
  X failures
- 🟣 Coverage:
  X failures

📄 Full diagnosis saved to:
ci_diagnosis_pr_<number>.md

---

**Failures to Fix:**

1. 🔴 LINT:
   Line too long in api.py:42 Issue:
   E501 line too long (120 > 100 characters) Fix:
   Break long string into multiple lines

2. 🟠 TEST:
   test_get_customer failed in tests/test_api.py::test_get_customer Issue:
   AssertionError:
   assert 404 == 200 Fix:
   Update test to expect 404 or change API to return 200

3. 🟡 DEPENDENCY:
   pandas version conflict Issue:
   Could not find pandas>=2.0.0 Fix:
   Update pandas to >=2.0.0 in pyproject.toml

---

Apply fixes?
(yes/no/selective)
```

**Rules:**
- ✅ Show top 5 failures (prioritized by severity)
- ✅ Include file path, line number, and exact error
- ✅ Provide specific fix suggestion for each
- ✅ Ask for approval before applying fixes

### Step 11: Apply Fixes (If Approved)

If user approves, apply fixes locally using `str-replace-editor` and package managers:

**For lint failures:**
```bash
# Auto-fix with ruff
uv run ruff check --fix <file_path>

# Or use str-replace-editor for specific changes
```

**For test failures:** Use `codebase-retrieval` to understand the test and the
code it's testing, then:
- Update test expectations if API behavior is correct
- Fix the code if test expectations are correct
- Use `str-replace-editor` to make changes

**For dependency failures:**
```bash
# Update dependencies using package manager
uv add <package>@<version>

# Or sync dependencies
uv sync
```

**For build/syntax failures:** Use `str-replace-editor` to fix syntax errors
based on error messages.

**For infrastructure failures:**
- Update workflow files (`.github/workflows/*.yml`)
- Adjust timeout settings
- Fix authentication/secrets issues

**Important:**
- ✅ Use `codebase-retrieval` before making changes to understand context
- ✅ Use `str-replace-editor` for code changes (never overwrite files)
- ✅ Use package managers for dependency changes
- ✅ Make changes one at a time
- ✅ Explain each change before applying

### Step 12: Run Tests Locally

After applying fixes, run tests to verify:

```bash
# Run all tests
uv run pytest -n auto

# Run specific failing tests
uv run pytest tests/test_api.py::test_get_customer -v

# Run with coverage
uv run pytest --cov=src --cov-report=term-missing
```

**Present results:**
```
✅ Tests passed! Ready to commit and push.

Or:

❌ Tests still failing. Let me analyze the new failures...
[Continue diagnosis loop]
```

### Step 13: Clean Up Diagnosis File

After fixes are successfully applied and tests pass, remove the diagnosis file:

```bash
# Remove the diagnosis file
rm -f "$DIAGNOSIS_FILE"
echo "Removed diagnosis file: $DIAGNOSIS_FILE"
```

### Step 14: Summary and Next Steps

After fixes are applied, tests pass, and cleanup is done:

```
✅ All fixes applied successfully!

**Changes made:**
- Fixed 3 lint issues in api.py
- Updated test_get_customer to expect 404
- Updated pandas to >=2.0.0 in pyproject.toml

**Tests:** ✅ All passing

**Next steps:**
1. Review the changes
2. Commit: `git add . && git commit -m "fix: address CI failures for PR #<number>"`
3. Push: `git push`
4. Monitor CI re-run on PR #<number>
```

## Important Notes

1. **Extract PR number from trigger** - Parse "Fix CI failure PR #123" to get PR
   number
2. **Fetch CI from PR's branch** - Get the PR's head branch and latest commit,
   then fetch CI runs for that commit
3. **Focus on latest run only** - Analyze the most recent CI run for the PR's
   latest commit
4. **Local-only workflow** - No PR comments, all fixes applied locally
5. **Use codebase-retrieval extensively** - Understand context before making
   changes
6. **Provide actionable fixes** - Include exact commands and code changes
7. **Save diagnosis locally** - Create markdown file for reference
   (ci_diagnosis_pr_<number>.md)
8. **Ask for approval** - Always present summary before applying fixes
9. **Handle multiple failures** - Group by type, prioritize by severity
10. **Run tests after fixes** - Verify fixes work before committing
11. **Clean up after success** - Remove diagnosis file after fixes are applied
    and tests pass
12. **Iterative process** - If tests still fail, diagnose again

## Configuration

**Failure priority (highest to lowest):**
1. Infrastructure (blocks everything)
2. Dependencies (blocks tests)
3. Build (blocks tests)
4. Tests (blocks merge)
5. Lint (blocks merge)
6. Coverage (informational)

**Max failures to analyze:** 20 (prioritize by severity)

**Diagnosis file location:** `ci_diagnosis_pr_<number>.md` in workspace root

**Workflow:** Local fixes only (no PR comments)

**Cleanup:** Remove diagnosis file after successful fixes

## Example Usage

```
Developer: *pushes changes to PR #120, CI fails*

Developer: "Fix CI failure PR #120"

Agent:
1. Extracts PR number (120) from trigger
2. Fetches PR details (branch: feat/error-handling, commit: abc123)
3. Fetches latest workflow run for commit abc123
4. Downloads logs from all failed jobs
5. Classifies failures (3 lint, 2 test, 1 dependency)
6. Extracts error snippets and identifies root causes
7. Generates fix suggestions for each failure
8. Creates ci_diagnosis_pr_120.md
9. Presents summary in chat with top failures
10. Asks: "Apply fixes? (yes/no/selective)"

Developer: "yes"

Agent:
11. Applies fixes locally using str-replace-editor and package managers
12. Runs tests to verify fixes
13. Tests pass! Removes ci_diagnosis_pr_120.md
14. Presents summary: "✅ All fixes applied! Tests passing. Ready to commit."

Developer: *commits and pushes*
Developer: *monitors CI re-run on PR #120*
```
