---
description: Quick capture notes, ideas, todos, and thoughts to Basic Memory
argument-hint: <content> [type:todo|idea|meeting|thought] [priority:P0-P3] [project:name]
allowed-tools: write_note_basic-memory, search_notes_basic-memory
---

# Note

Quickly capture any type of note to Basic Memory.
Fast capture with sensible defaults - no questions asked.

## IMPORTANT: Use Basic Memory Tools

**ALWAYS use `write_note_basic-memory()` to create notes.** Do NOT use
filesystem tools.

## Note Types

| Type | Directory | Use Case |
|------|-----------|----------|
| `thought` | `_meta/working/` | Default - quick thoughts, observations |
| `todo` | `planning/tasks/backlog/` | Tasks and action items |
| `idea` | `_meta/working/ideas/` | Ideas to explore later |
| `meeting` | `_meta/working/meetings/` | Quick meeting notes |

## Arguments

- `$1` - Note content (required)
- `type:<type>` - Note type (optional, default:
  `thought`)
- `priority:P0|P1|P2|P3` - For todos only (default:
  P2)
- `project:<name>` - Related project (optional)

## Your Task

### 1. Parse Input

Extract from `$ARGUMENTS`:
- **Content**:
  The main text
- **Type**:
  Look for `type:todo`, `type:idea`, etc. (default:
  `thought`)
- **Priority**:
  For todos, look for `priority:P0`, etc. (default:
  P2)
- **Project**:
  Look for `project:<name>` (optional)

**Type inference** - If no explicit type, infer from content:
- Contains "fix", "add", "implement", "update", "refactor" → `todo`
- Contains "what if", "maybe", "could we", "idea:" → `idea`
- Contains "meeting", "standup", "retro", "sync" → `meeting`
- Otherwise → `thought`

### 2. Create Note Based on Type

#### Type: `thought` (default)

```python
write_note_basic-memory(
    title="<Brief Title from Content>",
    content="""# <Title>

<Content>

## Observations

- [thought] <key insight> #raw

## Relations

- indexed_by [[Knowledge Graph Index]]
""",
    directory="_meta/working",
    tags=["thought", "raw", "<project-if-provided>"]
)
```

#### Type: `todo`

```python
write_note_basic-memory(
    title="<Task Description>",
    content="""# <Task Description>

## Summary

<One sentence description>

## Acceptance Criteria

- [ ] <Main goal>

## Observations

- [status] not_started #backlog
- [priority] <P0|P1|P2|P3> #task

## Relations

- indexed_by [[Planning Index]]
""",
    directory="planning/tasks/backlog",
    tags=["task", "<priority>", "<project-if-provided>"]
)
```

#### Type: `idea`

```python
write_note_basic-memory(
    title="Idea: <Brief Title>",
    content="""# Idea: <Title>

## The Idea

<Content>

## Why It Might Work

- <Potential benefit>

## Open Questions

- <What needs exploration>

## Observations

- [idea] <core concept> #explore

## Relations

- indexed_by [[Knowledge Graph Index]]
""",
    directory="_meta/working/ideas",
    tags=["idea", "explore", "<project-if-provided>"]
)
```

#### Type: `meeting`

```python
write_note_basic-memory(
    title="Meeting: <Topic> - <Date>",
    content="""# Meeting: <Topic>

## Details

- **Date**: <today>
- **Attendees**: TBD

## Notes

<Content>

## Action Items

- [ ] TBD

## Observations

- [meeting] <topic> #raw

## Relations

- indexed_by [[Knowledge Graph Index]]
""",
    directory="_meta/working/meetings",
    tags=["meeting", "raw", "<project-if-provided>"]
)
```

### 3. Confirm

Brief confirmation based on type:

```
✅ Captured: **<Title>**
   Type: thought | Location: _meta/working/<name>.md

✅ Added to backlog: **<Task>**
   Priority: P2 | Location: planning/tasks/backlog/<name>.md

✅ Idea saved: **<Title>**
   Location: _meta/working/ideas/<name>.md

✅ Meeting note: **<Title>**
   Location: _meta/working/meetings/<name>.md
```

## Examples

```
/note The API response time seems slow lately
→ Creates thought in _meta/working/

/note Fix the flaky test in alert-summarizer
→ Infers todo, creates in planning/tasks/backlog/

/note type:todo Implement user dashboard priority:P1
→ Creates P1 task in backlog

/note type:idea What if we used GraphQL instead of REST
→ Creates idea in _meta/working/ideas/

/note type:meeting Standup - Sarah blocked on API
→ Creates meeting note in _meta/working/meetings/

/note Database connection pooling might help project:data-layer
→ Creates thought tagged with data-layer
```

## Quick Capture Philosophy

This command is for **fast capture**.
Don't ask questions - just save it with sensible defaults.
Notes can be enhanced later with `/enhance`.
