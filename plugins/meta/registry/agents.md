# Agent Registry

Quick reference for all available agents in the marketplace.

## Code Quality Agents

### PR Code Reviewer
**Path:** `plugins/code-quality/agents/pr-code-reviewer.md`  
**Purpose:** Automatically review GitHub PRs with AI-powered analysis focusing on security, testing, code quality, and best practices.  
**Triggers:** "review PR", "code review PR #123", "review the latest PR"

### PR Comment Resolver
**Path:** `plugins/code-quality/agents/pr-comment-resolver.md`  
**Purpose:** Address and resolve PR review comments by making code changes and responding to feedback.  
**Triggers:** "address comments on PR", "fix comments on PR #123", "resolve PR feedback"

### CI Failure Diagnoser
**Path:** `plugins/code-quality/agents/ci-failure-diagnoser.md`  
**Purpose:** Diagnose CI failures by fetching logs, analyzing errors, and suggesting fixes.  
**Triggers:** "diagnose ci failure", "why did ci fail", "check ci logs"

### Issue Resolver
**Path:** `plugins/code-quality/agents/issue-resolver.md`  
**Purpose:** Automatically resolve GitHub issues by analyzing the issue, creating a feature branch, implementing the solution, and creating a PR.  
**Triggers:** "resolve issue #123", "fix issue", "implement issue"

### Plan Reviewer
**Path:** `plugins/code-quality/agents/plan-reviewer.md`  
**Purpose:** Review implementation plans for completeness, feasibility, and alignment with requirements.  
**Triggers:** "review plan", "check implementation plan"

### Refactor Agent
**Path:** `plugins/code-quality/agents/refactor.md`  
**Purpose:** Perform code refactoring while maintaining functionality and improving code quality.  
**Triggers:** "refactor", "clean up code", "improve code structure"

## Ralph Workflow Agents

### Architect
**Path:** `plugins/ralph-workflow/agents/architect.md`  
**Purpose:** Complex architecture decisions, spec creation, and escalation for difficult problems. Senior-level reasoning for system design and requirements analysis.  
**Triggers:** Called by other agents for escalation, spec creation, or architecture decisions

### Ralph Explore
**Path:** `plugins/ralph-workflow/agents/ralph-explore.md`  
**Purpose:** Explore codebase and gather context for planning and implementation.  
**Triggers:** Part of Ralph workflow - exploration phase

### Ralph Plan
**Path:** `plugins/ralph-workflow/agents/ralph-plan.md`  
**Purpose:** Create detailed implementation plans based on requirements and codebase exploration.  
**Triggers:** Part of Ralph workflow - planning phase

### Ralph Implement
**Path:** `plugins/ralph-workflow/agents/ralph-implement.md`  
**Purpose:** Execute implementation plans by writing code and making changes.  
**Triggers:** Part of Ralph workflow - implementation phase

### Ralph Spec Review
**Path:** `plugins/ralph-workflow/agents/ralph-spec-review.md`  
**Purpose:** Review specifications for completeness and clarity before implementation.  
**Triggers:** Part of Ralph workflow - spec review phase

### Ralph Quality Review
**Path:** `plugins/ralph-workflow/agents/ralph-quality-review.md`  
**Purpose:** Review implementation quality, test coverage, and adherence to standards.  
**Triggers:** Part of Ralph workflow - quality review phase


## Meta Agents

### Marketplace Maintainer
**Path:** `plugins/meta/agents/marketplace-maintainer.md`  
**Purpose:** Intelligently update, create, or delete marketplace content (agents, rules, commands, skills, memory) with context-aware file discovery, multi-file updates, and automated sync workflow. Replaces and extends the functionality of memory-capture agent.  
**Triggers:** "update marketplace", "create marketplace", "modify marketplace", "add to marketplace", "add to global memory", "add to {project} memory", "capture this to memory"
