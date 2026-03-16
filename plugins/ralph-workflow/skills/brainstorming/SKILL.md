---
name: brainstorming
description: Use when doing any creative work - creating features, building components, adding functionality, or modifying behavior; explores user intent, requirements and design before implementation
---

# Brainstorming Ideas Into Designs

## Overview

Help turn ideas into fully formed designs and specs through natural
collaborative dialogue.

Start by understanding the current project context, then ask questions one at a
time to refine the idea.
Once you understand what you're building, present the design in small sections
(200-300 words), checking after each section whether it looks right so far.

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it
  into multiple questions
- Focus on understanding:
  purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover:
  architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:** Save the validated design to Basic Memory:

```python
write_note_basic-memory(
    title="Design: <topic>",
    content="[design content]",
    directory="artifacts/specs",
    tags=["design", "spec", "<topic-tags>"]
)
```

The note should follow this structure:

```markdown
# Design: <Topic>

## Summary
[2-3 sentence overview of what we're building]

## Requirements
[Key requirements discovered during brainstorming]

## Architecture
[High-level architecture decisions]

## Components
[Key components and their responsibilities]

## Data Flow
[How data moves through the system]

## Error Handling
[Error handling approach]

## Testing Strategy
[How this will be tested]

## Open Questions
[Any remaining uncertainties]

## Observations

- [decision] Architecture choice made #design
- [requirement] Key requirement identified
- [constraint] Important constraint discovered

## Relations

- implements [[Related Feature]]
- relates_to [[Related System]]
- informs [[Implementation Plan]]
```

**Implementation (if continuing):**

- Ask:
  "Ready to set up for implementation?"
- Use superpowers:using-git-worktrees to create isolated workspace
- Use superpowers:writing-plans to create detailed implementation plan

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense
