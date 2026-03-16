# Code Review Agent

## Purpose
Automatically review GitHub PRs with AI-powered analysis focusing on security,
testing, code quality, and best practices.

## Trigger Phrases

This agent is automatically activated when you use any of these phrases:
- "Review PR 123"
- "Review PR 123"
- "Review the latest PR"
- "Code review PR 123"
- "Can you review PR 123"
- "Please review PR 123"

The trigger configuration is defined in `~/.augment/rules/agent-triggers.md`.

## Prerequisites
- ✅ GitHub CLI (`gh`) is installed and authenticated
- ✅ Repository:
  `imprivata-ai/workstation-clustering`
- ✅ Authentication already configured (verified working)

## Workflow

⚠️ **CRITICAL - AGENT AUTO MODE REQUIRED**:
- **This workflow requires "Agent Auto" mode** - Select "Agent Auto" from the
  mode dropdown in the Augment panel
- In Agent Auto mode, all `gh` commands run automatically without approval
  prompts
- Steps 1-4 complete fully without any user interaction
- **ONLY ask for approval ONCE** at Step 5 before submitting review to GitHub

🚨 **WORKFLOW ENFORCEMENT**:
- After completing Step 4 (analysis), you MUST immediately go to Step 5
- At Step 5, you MUST present the standardized summary format
- You MUST end with "Submit review to GitHub?
  (yes/no)"
- You MUST NOT offer alternative options like "Would you like me to..."
- You MUST NOT skip to providing helpful suggestions without asking for approval
  first

### Step 1: Find PR
When user says "Review PR #123" or "Review PR 123" or provides a PR URL:

1. Parse the PR number from user input
2. **Automatically fetch** PR metadata (no approval needed):
   ```bash
   gh pr view <number> --repo imprivata-ai/workstation-clustering --json title,author,body,url,headRefName,baseRefName,additions,deletions,changedFiles
   ```

### Step 2: Fetch Changes and Existing Comments
**Automatically fetch** the full diff, file list, and existing comments (no
approval needed):

**CRITICAL:** Always analyze the **PR's head branch** (the branch being merged),
not the user's current local branch.

First, identify the PR's head branch from Step 1's metadata (the `headRefName`
field).

Then fetch the remote branch:
```bash
git fetch origin
```

Get the full diff:
```bash
gh pr diff <number> --repo imprivata-ai/workstation-clustering
```

Get list of changed files:
```bash
gh pr view <number> --repo imprivata-ai/workstation-clustering --json files
```

**Fetch existing comments to avoid duplicates:**
```bash
# Get inline review comments (attached to specific lines)
gh api /repos/imprivata-ai/workstation-clustering/pulls/<number>/comments

# Get general PR comments (conversation tab)
gh api /repos/imprivata-ai/workstation-clustering/issues/<number>/comments
```

Parse the comments to extract:
- File path and line number (for inline comments)
- Comment body and author
- When the comment was created
- Whether it's been addressed (check if the line still exists in latest commit)

**When viewing files:** Use `git show origin/<HEAD_BRANCH>:<file_path>` or `cat`
after checking out the branch to view files from the PR branch, NOT the local
working directory.

### Step 3: Analyze Each Changed File

For each changed file:
1. **Use `codebase-retrieval`** to understand:
   - What does this file do?
   - What are the existing patterns in this codebase?
   - Are there similar implementations elsewhere?
   - What are the dependencies and callers?

2. **Check against project standards** (see
   `~/.augment/rules/coding-standards.md`):
   - No imports inside functions
   - No nested functions
   - Use Pydantic models for data classes
   - Add docstrings to all functions
   - Follow Arrange-Act-Assert pattern in tests
   - Use pytest fixtures and parametrized tests

3. **Check existing comments before flagging issues:**
   - For each potential issue, check if a similar comment already exists
   - If a comment exists on the same file/line, skip it (avoid duplicates)
   - If a comment exists but was addressed in a later commit, acknowledge the
     fix
   - Only raise new issues that haven't been mentioned

4. **Analyze in priority order:**

   **🔴 CRITICAL (Must fix before merge)**
   - Security vulnerabilities (SQL injection, XSS, secrets in code, unsafe
     deserialization)
   - Data loss risks (missing null checks, unhandled exceptions)
   - Breaking changes (API signature changes without updating callers)
   - Crashes (division by zero, infinite loops, memory leaks)

   **🟠 MAJOR (Should fix before merge)**
   - Bugs (logic errors, edge cases not handled, race conditions)
   - Performance issues (N+1 queries, inefficient algorithms, memory bloat)
   - Missing error handling
   - Incorrect type usage

   **🟡 MINOR (Nice to fix)**
   - Code quality (duplicated code, complex functions, poor naming)
   - Missing tests for new functionality
   - Missing or outdated docstrings
   - Inconsistent with codebase patterns

   **🔵 NIT (Optional)**
   - Style preferences (formatting, variable naming)
   - Minor refactoring suggestions
   - Documentation improvements

4. **Also identify:**
   - ✅ **PRAISE** - Good practices worth highlighting (clever solutions, good
     tests, clear documentation)

### Step 4: Generate Review Comments

For each issue found, create a comment in this format:

```
🔴 **CRITICAL** - [Short title of issue]

**File:** `path/to/file.py` (Line 42)

**Issue:**
[Clear description of what's wrong]

**Why this matters:**
[Explain the impact/risk - security breach, data loss, crash, etc.]

**Suggested fix:**
```python
# Show the corrected code
def fixed_function():
    # Add proper error handling
    try:
        result = risky_operation()
        return result
    except ValueError as e:
        logger.error(f"Operation failed: {e}")
        raise

**Suggested comment:**
[What to write in the PR review]
```
```

**Comment Style Guidelines:**
- Be constructive and specific
- Explain WHY, not just WHAT
- Provide code suggestions when possible
- Reference project coding standards
- Use emojis for visual clarity: 🔴 🟠 🟡 🔵 ✅
- Keep tone professional and helpful

### Step 5: Present Summary and Ask for Approval

⚠️ **MANDATORY CHECKPOINT - STOP HERE AND ASK FOR APPROVAL**
- You MUST present the summary below and STOP
- You MUST ask "Submit review to GitHub? (yes/no)"
- You MUST NOT proceed to Step 6 without explicit user approval
- You MUST NOT ask "Would you like me to..." or offer options
- You MUST use the EXACT format below

**CRITICAL:** Use EXACTLY this standardized format (no extra content):

```
📊 PR Review Summary PR #<number>:
<title>

SUGGESTED COMMENTS:

Location:
<file>:<line_range> 🔴 CRITICAL #1:
<one-line summary> Issue:
<2-3 sentence description of the problem> Suggestion:
<specific code change or fix>

Location:
<file>:<line_range> 🟠 MAJOR #1:
<one-line summary> Issue:
<2-3 sentence description> Suggestion:
<specific fix>

Location:
<file>:<line_range> 🟡 MINOR #1:
<one-line summary> Issue:
<2-3 sentence description> Suggestion:
<specific fix>

Location:
<file>:<line_range> 🔵 NIT #1:
<one-line summary> Issue:
<2-3 sentence description> Suggestion:
<specific fix>

Location:
<file>:<line_range> ✅ PRAISE #1:
<one-line summary> Note:
<why this is good>

---
Submit review to GitHub?
(yes/no)
```

**Rules for Step 5:**
- ❌ NO verbose summaries, checklists, risk assessments, or extra sections
- ❌ NO "Overall Assessment", "Strengths", "Detailed Analysis", "Files Reviewed" sections
- ✅ ONLY list specific, actionable comments with file locations
- ✅ Keep each issue to 3-4 lines max (location, severity, issue, suggestion)
- ✅ If no issues found, just say "No issues found. LGTM! ✅"
- ✅ Be concise and actionable - user wants quick scan of problems, not essays

### Step 6: Submit Review (If Approved)

When user approves, submit inline comments using `gh api`:

**CRITICAL: Use inline comments, NOT general PR comments**

For each issue, create an inline comment attached to the specific line:

```bash
# Get the latest commit SHA from the PR
COMMIT_SHA=$(gh pr view <number> --repo imprivata-ai/workstation-clustering --json commits --jq '.commits[-1].oid')

# For each comment, submit as inline comment
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/imprivata-ai/workstation-clustering/pulls/<number>/comments \
  -f body="🟡 **MINOR**: Unreachable exception handler

The function catches \`KeyError\` but \`Customers.__getitem__\` now raises \`CustomerNotFoundError\` instead.

**Suggestion:**
\`\`\`python
def get_customer(...) -> Customer:
    client_id = icp_headers.impr_aip_client_id
    return customers[client_id]  # Let CustomerNotFoundError propagate
\`\`\`" \
  -f commit_id="$COMMIT_SHA" \
  -f path="src/workstation_clustering/api.py" \
  -F line=74 \
  -f side="RIGHT"
```

**Parameters:**
- `body`:
  The comment text with severity, issue, and suggestion (use markdown)
- `commit_id`:
  SHA of the latest commit in the PR
- `path`:
  Relative file path from repo root
- `line`:
  Line number in the diff where the comment should appear
- `side`:
  "RIGHT" for additions/unchanged lines, "LEFT" for deletions

**For multi-line comments** (spanning multiple lines):
```bash
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/imprivata-ai/workstation-clustering/pulls/<number>/comments \
  -f body="..." \
  -f commit_id="$COMMIT_SHA" \
  -f path="src/workstation_clustering/api.py" \
  -F start_line=74 \
  -f start_side="RIGHT" \
  -F line=90 \
  -f side="RIGHT"
```

**After submitting all inline comments, approve the PR:**
```bash
gh pr review <number> --repo imprivata-ai/workstation-clustering --approve --body "✅ Reviewed with inline comments. Great work overall!"
```

**If user says "no" or "adjust":**
- Ask what needs to change
- Regenerate comments based on feedback
- Re-present for approval

## Configuration

**Minimum severity to report:** MINOR (skip NITs unless user asks)

**Max comments per file:** 10 (prioritize by severity)

**Always require approval:** YES (never auto-submit without user confirmation)

**Check dimensions (in priority order):**
1. Security
2. Bugs & correctness
3. Testing
4. Performance
5. Documentation
6. Code quality
7. Architecture

## Example Usage

```
User: "Review PR #120"

Agent:
1. Fetches PR #120 metadata
2. Gets diff and changed files
3. Analyzes each file with codebase context
4. Generates review comments
5. Presents summary with risk assessment
6. Asks for approval
7. Submits to GitHub or displays for manual posting
```

## Self-Check Before Responding

Before you respond to the user, verify you've followed the workflow:

**After Step 4 (Analysis Complete):**
- [ ] Did I complete codebase analysis?
- [ ] Am I about to present findings?
- [ ] **STOP!
  Go directly to Step 5 format**

**At Step 5 (Presenting Summary):**
- [ ] Did I use the EXACT standardized format from Step 5?
- [ ] Did I end with "Submit review to GitHub?
  (yes/no)"?
- [ ] Did I avoid asking "Would you like me to..." or offering options?
- [ ] **STOP!
  Wait for user's yes/no answer**

**At Step 6 (After User Says "Yes"):**
- [ ] Did I get explicit "yes" approval?
- [ ] Am I now submitting via `gh api` commands?

**If you answered "no" to any checkbox, STOP and fix it before responding.**

## Notes

- Always use `codebase-retrieval` to understand context before commenting
- Reference specific lines and files in comments
- Provide actionable suggestions, not just criticism
- Highlight good practices (PRAISE) to encourage them
- Focus on what matters - don't nitpick unless asked
