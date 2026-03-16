---
description: Collaboratively explore and design an idea before implementation
argument-hint: <idea or topic>
allowed-tools: write_note_basic-memory, search_notes_basic-memory, read_note_basic-memory, build_context_basic-memory, codebase-retrieval, view
---

# Brainstorm

Collaboratively explore an idea and turn it into a well-formed design through natural dialogue.

## IMPORTANT: Use the Brainstorming Skill

**Read and follow the skill at:** `~/.augment/skills/brainstorming/SKILL.md`

This command invokes the brainstorming skill. The skill contains the full process.

## Quick Reference

The brainstorming process:

1. **Understand context** - Check project state, existing code, recent work
2. **Ask questions one at a time** - Refine the idea through dialogue
3. **Explore approaches** - Propose 2-3 options with trade-offs
4. **Present design incrementally** - 200-300 word sections, validate each
5. **Save to Basic Memory** - Store validated design in `specs/`

## Your Task

When the user runs `/brainstorm <idea>`:

1. **Read the skill file:**
```
view ~/.augment/skills/brainstorming/SKILL.md
```

2. **Follow the skill instructions exactly**

3. **Start by understanding context:**
   - What project/codebase is this for?
   - What existing code or patterns are relevant?
   - What's the user trying to accomplish?

4. **Ask your first clarifying question** (one at a time, prefer multiple choice)

## Examples

```
/brainstorm API rate limiting
→ Explores rate limiting approaches, asks about requirements, designs solution

/brainstorm user notification system
→ Asks about notification types, delivery methods, designs architecture

/brainstorm refactoring the auth module
→ Understands current state, proposes refactoring approaches, creates plan
```

## Output

After brainstorming completes, the design is saved to Basic Memory:

```python
write_note_basic-memory(
    title="Design: <topic>",
    content="[validated design]",
    directory="specs",
    tags=["design", "spec", "<topic-tags>"]
)
```

## See Also

- `/research` - Research a topic before brainstorming
- `/tasks expand` - Elaborate on an existing task
- `superpowers:writing-plans` - Create implementation plan from design

