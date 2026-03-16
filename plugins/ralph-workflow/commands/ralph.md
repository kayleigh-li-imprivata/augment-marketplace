---
description: Full Ralph Wiggum specs-based development flow using subagents
argument-hint: <feature or goal description>
---

# Ralph Wiggum Development Flow

Execute the complete specs-based development workflow using specialized
subagents for each phase.

## The Ralph Wiggum Philosophy

"Don't assume not implemented." Before building anything, understand what
exists.
Specs are source of truth.
Plan is disposable.
One task at a time.

## Model Strategy

| Phase | Agent | Model | Reasoning |
|-------|-------|-------|-----------|
| 1. Specs | **orchestrator** (brainstorming) | opus4.5 | Collaborative design dialogue |
| 2. Gap Analysis | ralph-explore | sonnet4.5 | Searching/comparing - structured |
| 3. Planning | ralph-plan | sonnet4.5 | Following template - straightforward |
| 4. Building | ralph-implement | sonnet4.5 | Following plan - TDD |
| 4. Review | ralph-spec-review, ralph-quality-review | sonnet4.5 | Two-stage review |
| Escalation | **architect** | opus4.5 | When stuck or ambiguous |

## Workflow Phases

```text
Phase 1: Specs        → Collaborative brainstorming to define requirements (brainstorming skill)
Phase 2: Gap Analysis → Compare specs vs existing code (explore)
Phase 3: Planning     → Create implementation plan from gaps (plan)
Phase 4: Building     → Execute plan with subagent-per-task + two-stage review
Phase 5: Completion   → Finish branch with verification
```

## Execution

### Phase 1: Spec Creation (brainstorming skill)

Use superpowers:brainstorming skill to collaboratively develop the spec.

**Step 1:** Dispatch explore subagent (sonnet4.5) to gather context:

```text
Explore the codebase to understand:
1. What functionality related to "<topic>" already exists?
2. What patterns, conventions, and structures are used?
3. What would a new feature need to integrate with?

Search thoroughly before reporting. Remember: "Don't assume not implemented."
Report findings as: existing capabilities, patterns to follow, integration points.
```

**Step 2:** Run brainstorming process (orchestrator stays active):

The orchestrator (you) conducts the brainstorming directly with the user:

1. **Share exploration context** with user
2. **Ask questions one at a time** to refine the idea:
   - Purpose and user outcomes
   - Constraints and requirements
   - Success criteria
3. **Propose 2-3 approaches** with trade-offs
4. **Present design incrementally** (200-300 words per section)
5. **Validate each section** before moving on

**Step 3:** Convert design to spec format:

After brainstorming is complete, save spec to `specs/<topic>.md` with:

- Job to Be Done:
  what user outcome this enables
- Acceptance Criteria:
  observable, verifiable outcomes (checkboxes)
- Scope:
  what's IN and OUT of scope
- Dependencies:
  other specs or systems needed
- Notes:
  design decisions and constraints

Topic scope test:
can you describe it in one sentence without "and" conjoining unrelated
capabilities?

**Step 4:** Update Basic Memory (REQUIRED):

After saving the spec file, update the knowledge graph:

**4a.
Save spec to Basic Memory:**

```python
write_note_basic-memory(
    title="Spec: <Topic Name>",
    directory="artifacts/specs",
    tags=["spec", "ralph", "<project-tag>"],
    content="""
# Spec: <Topic Name>

## Summary
[2-3 sentence overview from brainstorming]

## Job to Be Done
[User outcome this enables]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Scope
**In scope:** ...
**Out of scope:** ...

## Key Design Decisions
- [decision] <Decision made during brainstorming> #design
- [decision] <Another decision> #architecture

## Observations
- [goal] Primary objective #spec
- [constraint] Known limitation
- [approach] Chosen approach and why

## Relations
- implements [[Project: <Project Name>]]
- relates_to [[Spec: <Related Spec>]]
- depends_on [[<Dependency>]]
"""
)
```

**4b.
Update project tracking note:**

Check if project note exists at `projects/<project-name>.md`.
Create or update:

```python
# If project note doesn't exist, create it:
write_note_basic-memory(
    title="Project: <Project Name>",
    directory="projects",
    tags=["project", "ralph", "active"],
    content="""
# Project: <Project Name>

## Overview
[Brief project description]

## Active Specs
| Spec | Status | Created |
|------|--------|---------|
| [[Spec: <Topic>]] | drafting | <date> |

## Key Decisions
- [decision] <Major decision from brainstorming> #architecture
- [decision] <Another key decision> #design

## Observations
- [status] Project initiated with Ralph workflow
- [scope] Initial scope defined

## Relations
- contains [[Spec: <Topic>]]
- relates_to [[<Related Project or System>]]
"""
)

# If project note exists, use edit_note_basic-memory to append:
edit_note_basic-memory(
    identifier="projects/<project-name>",
    operation="append",
    section="Active Specs",
    content="| [[Spec: <New Topic>]] | drafting | <date> |"
)
```

**What to capture in Basic Memory:**

- Design decisions and their rationale from brainstorming
- Trade-offs considered and why one approach was chosen
- Constraints discovered during discussion
- Links between specs (dependencies, relates_to)
- Project-level status for tracking multiple specs

### Phase 2: Gap Analysis (sub-agent-ralph-explore)

Dispatch ralph-explore subagent:

```text
Perform gap analysis for specs in specs/ directory.

For each spec:
1. Read the acceptance criteria carefully
2. Search codebase for existing implementations
3. Compare what's required vs what exists
4. Identify specific gaps (missing, partial, or wrong)

Report: spec-by-spec gap analysis with:
- ✅ Already implemented: [what exists]
- ⚠️ Partial: [what's missing]
- ❌ Missing: [what needs building]
```

### Phase 3: Planning (sub-agent-ralph-plan)

Dispatch ralph-plan subagent:

```text
Create implementation plan from gap analysis.

Use superpowers:writing-plans skill. Save to docs/plans/YYYY-MM-DD-<feature>.md

Requirements:
- Every task references which spec acceptance criteria it satisfies
- Bite-sized tasks (2-5 minutes each)
- Full TDD: write failing test, verify fail, implement, verify pass, commit
- Exact file paths, complete code, exact commands
- DRY, YAGNI principles

Header must include: "For Claude: REQUIRED SUB-SKILL: Use superpowers:executing-plans"
```

### Phase 4: Building (Autonomous Loop)

Execute plan using ralph subagents with autonomous loop:

For each task:

1. **ralph-implement** - implements task, tests, commits, self-reviews
2. **ralph-spec-review** - verifies against acceptance criteria (distrust
   implementer)
3. **ralph-quality-review** - reviews code quality (only after spec passes)

Loop until both reviewers approve, then next task.

### Phase 5: Completion

Use superpowers:finishing-a-development-branch for final steps.

## Autonomous Loop Protocol

After user approves the plan, ask:

```text
Run autonomously or step-by-step?
1. Autonomous (I'll handle all tasks, pause if stuck)
2. Step-by-step (confirm each task)
```

### Autonomous Mode

When user selects autonomous mode:

1. **Initialize state** - Create `.ralph/state.json` with task list
2. **Loop through tasks:**
   - Dispatch `sub-agent-ralph-implement` with task
   - Dispatch `sub-agent-ralph-spec-review` to verify
   - If spec fails:
     fix and re-review
   - If spec passes:
     dispatch `sub-agent-ralph-quality-review`
   - If quality fails:
     fix and re-review
   - Mark task complete, move to next

3. **Monitor circuit breaker** - Hook tracks progress automatically:
   - No file changes for 3 iterations → STOP
   - Same task for 3 iterations → STOP
   - On trip:
     pause and ask user for guidance

4. **External monitoring** - User can `tail -f .ralph/logs/progress.log`

### Circuit Breaker Recovery

When circuit breaker trips:

1. Report what's stuck and why
2. Present options:
   - Escalate to architect for help
   - Skip task and continue
   - Abort and save state
   - User provides guidance

### State Persistence

Files created in `.ralph/`:

- `state.json` - Current progress (task, loop count, phase)
- `circuit-breaker.json` - Stuck detection counters
- `logs/progress.log` - External monitoring log

Resume with `/ralph --resume` if session interrupted.

## Escalation to Architect

Escalate to the **architect** agent (opus4.5) when:

- Requirements are ambiguous or conflicting
- Architecture decisions need deep reasoning
- Implementation gets stuck with unclear path forward
- Specs need revision based on discoveries
- Trade-offs require sophisticated analysis

## Quick Start

When user runs `/ralph <goal>`:

1. **Set up workspace** (if not in worktree):
   - Use superpowers:using-git-worktrees to create isolated workspace

2. **Phase 1:
   Create Specs**
   - Dispatch `sub-agent-ralph-explore` for context
   - Use superpowers:brainstorming to collaboratively develop spec with user
   - Save spec to `specs/` directory
   - Update Basic Memory:
     spec note + project tracking note (REQUIRED)

3. **Phase 2:
   Gap Analysis**
   - Dispatch `sub-agent-ralph-explore`
   - Present gaps to user

4. **Phase 3:
   Create Plan**
   - Dispatch `sub-agent-ralph-plan`
   - Save plan to docs/plans/

5. **Phase 4:
   Execute (Autonomous)**
   - Ask:
     autonomous or step-by-step?
   - Loop:
     `ralph-implement` → `ralph-spec-review` → `ralph-quality-review`
   - Circuit breaker monitors for stuck states
   - Escalate to architect if stuck

6. **Phase 5:
   Finish**
   - Run superpowers:finishing-a-development-branch

## User Checkpoints

Pause for user approval at:

- After specs created (Phase 1)
- After gap analysis (Phase 2)
- After plan created (Phase 3)
- After all tasks complete (Phase 5)

## See Also

- `superpowers:brainstorming` - Collaborative spec creation (Phase 1)
- `superpowers:knowledge-capture` - Basic Memory note patterns and relations
- `superpowers:spec-driven-development` - Full spec workflow details
- `superpowers:subagent-driven-development` - Task execution pattern
- `superpowers:writing-plans` - Plan creation details
- `superpowers:finishing-a-development-branch` - Branch completion
