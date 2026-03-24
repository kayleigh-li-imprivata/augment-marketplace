# Agent Triggers

## 🚨 Global Agent Rules - MANDATORY 🚨

### Marketplace Changes - ALWAYS Require Approval

When ANY agent makes changes to agent files in the marketplace (`~/.augment/plugins/marketplaces/kayleigh-li-imprivata/`):

**Workflow:**
1. **Show the diff** of what changed
2. **Ask for approval** before committing
3. **Ask for approval** before pushing to kayleigh-li-imprivata marketplace
4. **Sync to Auggie** after push:
   ```bash
   cd ~/.augment/plugins/marketplaces/kayleigh-li-imprivata
   git add <changed-files>
   git commit -m "..."
   git push
   auggie reindex  # This makes changes available to Augment CLI/chat
   ```

**IMPORTANT:**
- ✅ Use **kayleigh-li-imprivata** as the single source of truth
- ✅ Auggie reads from `kayleigh-li-imprivata` directly (no copying needed)
- ✅ Run `auggie reindex` after pushing to update the local index
- ❌ **NO** `augment-marketplace` repo exists - don't try to push to it
- ❌ **NO** copying between marketplaces - consolidate to kayleigh-li-imprivata only

**Never:**
- ❌ Auto-commit agent changes without approval
- ❌ Auto-push to marketplace without approval
- ❌ Try to push to augment-marketplace repo (doesn't exist!)
- ❌ Copy files between marketplaces (use single source)

---


## PR Code Review Agent

When the user mentions reviewing a PR, automatically:
1. Read
   `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/code-quality/agents/pr-code-reviewer.md`
2. Follow all instructions in that file step-by-step
3. Execute the complete code review workflow

### Trigger Phrases

Any of these phrases should trigger the PR code review agent:
- "Review PR #123"
- "Review PR 123"
- "Review the latest PR"
- "Code review PR #123"
- "Can you review PR #123"
- "Please review PR 123"

### Workflow

1. **Read the agent instructions:**
   - Load
     `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/code-quality/agents/pr-code-reviewer.md`
   - Follow every step in the workflow section

2. **Execute the review:**
   - Fetch PR data using `gh` CLI
   - Analyze all changes with codebase context
   - Generate review comments with severity levels
   - Present summary to user
   - Ask for approval before submitting

3. **Never skip:**
   - Reading the AGENT.md file first
   - Using codebase-retrieval for context
   - Asking for approval before submitting

## PR Comment Resolver Agent

When the user mentions addressing PR comments, automatically:
1. Read
   `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/code-quality/agents/pr-comment-resolver.md`
2. Follow all instructions in that file step-by-step
3. Execute the complete comment resolution workflow

### Trigger Phrases

Any of these phrases should trigger the PR comment resolver agent:
- "Address comments on PR #123"
- "Address PR #123 comments"
- "Fix comments on PR 123"
- "Resolve PR #123 feedback"
- "Handle PR 123 review comments"

### Workflow

1. **Read the agent instructions:**
   - Load
     `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/code-quality/agents/pr-comment-resolver.md`
   - Follow every step in the workflow section

2. **Execute the resolution:**
   - Verify user is on correct branch
   - Fetch all PR comments using `gh` CLI and API
   - Analyze each comment for validity
   - Propose fixes for valid comments
   - Ask for approval before applying changes
   - Update code, tests, docs, and all related files
   - Run tests to verify fixes
   - Commit and push changes

3. **Never skip:**
   - Reading the AGENT.md file first
   - Verifying the correct branch
   - Using codebase-retrieval for context
   - Updating ALL related files (tests, docs, configs)
   - Running tests before committing
   - Asking for approval before making changes

## CI Failure Diagnoser Agent

When the user mentions fixing CI failures for a PR, automatically:
1. Read
   `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/code-quality/agents/ci-failure-diagnoser.md`
2. Follow all instructions in that file step-by-step
3. Execute the complete CI diagnosis workflow

### Trigger Phrases

Any of these phrases should trigger the CI failure diagnoser agent:
- "Fix CI failure PR #123"
- "Fix CI failures PR 123"
- "Diagnose CI failure PR #123"
- "Debug CI PR 123"
- "Fix failing CI for PR #123"

### Workflow

1. **Read the agent instructions:**
   - Load
     `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/code-quality/agents/ci-failure-diagnoser.md`
   - Follow every step in the workflow section

2. **Execute the diagnosis:**
   - Extract PR number from trigger phrase
   - Fetch PR details (branch, latest commit)
   - Fetch latest workflow run for that commit (not all runs)
   - Download and parse logs from failed jobs
   - Classify failures by type (lint, test, dependency, build, infra, coverage)
   - Extract error snippets and identify root causes
   - Generate structured fix suggestions
   - Create local diagnosis markdown file (ci_diagnosis_pr_<number>.md)
   - Present summary to user
   - Ask for approval before applying fixes
   - Apply fixes locally using str-replace-editor and package managers
   - Run tests to verify fixes
   - Remove diagnosis file after successful fixes
   - Present summary and next steps

3. **Never skip:**
   - Reading the AGENT.md file first
   - Extracting PR number from trigger
   - Fetching CI from the PR's branch (not current branch)
   - Using codebase-retrieval for context
   - Creating the local diagnosis file
   - Asking for approval before applying fixes
   - Running tests after applying fixes
   - Removing diagnosis file after success
   - Providing actionable fix commands

## Issue Resolver Agent

When the user mentions resolving a GitHub issue, automatically:
1. Read
   `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/code-quality/agents/issue-resolver.md`
2. Follow all instructions in that file step-by-step
3. Execute the complete issue resolution workflow

### Trigger Phrases

Any of these phrases should trigger the issue resolver agent:
- "Resolve ticket 89"
- "Resolve issue 89"
- "Fix ticket #89"
- "Fix issue #89"
- "Implement ticket 89"
- "Implement issue #89"

### Workflow

1. **Read the agent instructions:**
   - Load
     `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/code-quality/agents/issue-resolver.md`
   - Follow every step in the workflow section

2. **Execute the resolution:**
   - Extract issue number from trigger phrase
   - Fetch issue details and comments using `gh` CLI
   - Analyze issue and generate 2-3 implementation approaches
   - Create temporary analysis markdown file (issue_<number>_analysis.md)
   - Present summary to user with recommendation
   - Ask for approval before implementing
   - Create feature branch
   - Implement the solution using str-replace-editor
   - Add/update tests
   - Update documentation
   - Run tests to verify implementation
   - Ask for approval before committing/pushing
   - Commit and push changes
   - Create PR using `gh` CLI
   - Remove analysis file after PR is created
   - Present final summary with PR link

3. **Never skip:**
   - Reading the AGENT.md file first
   - Extracting issue number from trigger
   - Using codebase-retrieval for context
   - Creating the analysis file
   - Proposing multiple approaches
   - Asking for approval TWICE (before implementing, before committing)
   - Running tests before committing
   - Creating descriptive PR with issue link
   - Removing analysis file after success

## Marketplace Maintainer Agent

When the user asks to update, create, or modify marketplace content (agents, rules, commands, skills, memory), automatically:
1. Read
   `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/meta/agents/marketplace-maintainer.md`
2. Follow all instructions in that file step-by-step
3. Execute the complete marketplace maintenance workflow

### Trigger Phrases

**Flexible triggers** - any mention of updating/creating/modifying marketplace content:
- "update marketplace **code review** agent to check for type hints"
- "create new marketplace agent for running tests"
- "add what we discussed to marketplace memory"
- "update marketplace to check for global linting rules when diagnosing ci failures"
- "modify marketplace **linting** rules"
- "add to global memory about ArgoCD patterns"
- "add to workstation-clustering memory"
- "capture this to memory"
- "save this to memory"

**Keywords:** "update marketplace", "create marketplace", "modify marketplace", "add to marketplace", "add to global memory", "add to {project} memory"

### Workflow

1. **Read the agent instructions:**
   - Load
     `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/plugins/meta/agents/marketplace-maintainer.md`
   - Follow every step in the workflow section

2. **Execute the maintenance:**
   - Read registries (agents.md, rules.md, memorized.md)
   - Parse user intent and find ALL relevant files
   - Recommend approach (update existing vs. create new)
   - Get user confirmation
   - Make changes to content files
   - Update registries if needed
   - Show git diff and ask for approval
   - Commit and push to marketplace
   - Reindex (auggie + basic-memory if memory changed)

3. **Never skip:**
   - Reading registries first
   - Finding ALL relevant files (not just one)
   - Recommending expand vs. create new
   - Updating registries when content changes
   - Showing the diff before pushing
   - Asking for approval before committing/pushing
   - Reindexing after push
