---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

You write test cases (pressure scenarios with subagents), watch them fail
(baseline behavior), write the skill (documentation), watch tests pass (agents
comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you
don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development
before using this skill.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools.
Skills help future instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## When to Create a Skill

**Create when:**

- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**

- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions
- Mechanical constraints (automate instead)

## Skill Types

### By Content

| Type | Purpose | Example |
|------|---------|---------|
| **Technique** | Concrete method with steps | condition-based-waiting, root-cause-tracing |
| **Pattern** | Way of thinking about problems | flatten-with-flags, test-invariants |
| **Reference** | API docs, syntax guides | helm-kubernetes, fastapi |

### By Rigidity

| Type | Characteristics | Examples |
|------|-----------------|----------|
| **Rigid** | Iron Law, no exceptions, explicit loophole closing | TDD, verification-before-completion |
| **Flexible** | Principles that adapt to context, "prefer" language | brainstorming, api-design |

The skill itself should declare which type it is.
Rigid skills require complete adherence.

## Directory Structure

```text
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```

## SKILL.md Structure

**Frontmatter (YAML):**

- Only two fields supported:
  `name` and `description`
- Max 1024 characters total (Augment) / 200 characters description (Anthropic)
- `name`:
  Lowercase letters, numbers, and hyphens only (1-64 chars)
- `description`:
  Describes ONLY when to use (NOT what it does)
  - Start with "Use when..."
  - Include specific symptoms, situations, and contexts
  - **NEVER summarize the skill's process or workflow**

### Description Examples

| Quality | Example | Why |
|---------|---------|-----|
| ✅ Good | "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes" | Specifies trigger conditions |
| ✅ Good | "Use when about to claim work is complete, fixed, or passing, before committing" | Describes WHEN, not WHAT |
| ❌ Bad | "A systematic four-phase debugging process with root cause analysis" | Describes the process, not when to use |
| ❌ Bad | "Helps with testing and quality assurance" | Vague, no trigger conditions |

### Progressive Disclosure

Skills load in layers to preserve context window:

1. **Metadata** (~100 tokens) - loaded at startup for discovery
2. **Body** (<5000 tokens recommended) - loaded on activation
3. **Resources** (optional) - loaded on demand via file references

If your skill exceeds 5000 tokens, extract reference material to separate files.

## The Iron Law (Same as TDD)

```text
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to NEW skills AND EDITS to existing skills.

Write skill before testing?
Delete it.
Start over.

## RED-GREEN-REFACTOR for Skills

### RED: Write Failing Test (Baseline)

Run pressure scenario with subagent WITHOUT the skill.
Document exact behavior:

- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?

### GREEN: Write Minimal Skill

Write skill that addresses those specific rationalizations.
Don't add extra content for hypothetical cases.

Run same scenarios WITH skill.
Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization?
Add explicit counter.
Re-test until bulletproof.

## Bulletproofing Skills Against Rationalization

### Close Every Loophole Explicitly

Don't just state the rule - forbid specific workarounds:

```text
❌ "Write tests first"
✅ "Write test first. Write code before test? Delete it. Start over.
   Don't keep as reference. Don't adapt. Delete means delete."
```

### Address "Spirit vs Letter" Arguments

Add foundational principle early in rigid skills:

```text
**Violating the letter of the rules is violating the spirit of the rules.**
```

### Build Rationalization Table

Capture rationalizations from baseline testing.
Every excuse agents make goes in the table:

| Excuse | Reality |
|--------|---------|
| "Too simple for this process" | Simple tasks have requirements too. Process is fast for simple cases. |
| "I'll do it properly next time" | First attempt sets the pattern. Do it right from the start. |
| "Emergency, no time" | Systematic process is FASTER than ad-hoc thrashing. |
| "I'm confident this works" | Confidence ≠ evidence. Run verification. |
| "Just this once" | No exceptions. "Just this once" is how all failures start. |

### Create Red Flags List

Make it easy for agents to self-check when rationalizing:

**If you're thinking any of these, STOP:**

- "This is just a simple case"
- "I'll come back and do it properly"
- "The skill is overkill for this"
- "I know what I'm doing"
- "Let me just try this first"
- Using "should", "probably", "seems to" about outcomes

## Skill Creation Checklist

**RED Phase:**

- [ ] Create pressure scenarios
- [ ] Run scenarios WITHOUT skill - document baseline
- [ ] Identify patterns in rationalizations

**GREEN Phase:**

- [ ] Name uses only letters, numbers, hyphens
- [ ] YAML frontmatter with only name and description
- [ ] Description starts with "Use when..."
- [ ] Address specific baseline failures
- [ ] One excellent example
- [ ] Run scenarios WITH skill - verify compliance

**REFACTOR Phase:**

- [ ] Identify NEW rationalizations
- [ ] Add explicit counters
- [ ] Build rationalization table
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Deployment:**

- [ ] Commit skill to git
- [ ] Consider contributing back via PR

## Security Considerations

- Never hardcode sensitive information in skills
- Review any downloaded skills before enabling
- Use MCP connections for external service access
- Exercise caution with executable scripts

## Verification Gate

Before claiming a skill is complete:

```text
1. BASELINE: Did you watch agents fail WITHOUT the skill?
2. COMPLIANCE: Did you verify agents comply WITH the skill?
3. LOOPHOLES: Did you counter observed rationalizations?
4. DESCRIPTION: Does it start with "Use when..." and specify triggers?
5. TESTED: Did you run pressure scenarios?

All five = ready to deploy.
Missing any = not done.
```

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law:
No skill without failing test first.

Same cycle:
RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).

**Violating the letter of this skill is violating the spirit of skill
creation.**
