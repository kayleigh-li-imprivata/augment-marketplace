---
description: Shortcut for /note type:todo - quickly add a task to backlog
argument-hint: <task description> [priority:P0|P1|P2|P3] [project:name]
allowed-tools: write_note_basic-memory, search_notes_basic-memory
---

# Todo

Shortcut for `/note type:todo`. Quickly capture a task to your Basic Memory backlog.

## IMPORTANT: Use Basic Memory Tools

**ALWAYS use `write_note_basic-memory()` to create tasks.** Do NOT use filesystem tools.

## Usage

```
/todo <task description> [priority:P0|P1|P2|P3] [project:name]
```

## Your Task

This is equivalent to `/note type:todo $ARGUMENTS`. Follow the `/note` command instructions for `type:todo`.

**Quick reference:**
- Creates task in `planning/tasks/backlog/`
- Default priority: P2
- Tags: `task`, priority, project (if provided)

## Examples

```
/todo Fix the flaky test in alert-summarizer
/todo Implement user dashboard priority:P1
/todo Add retry logic priority:P0 project:alert-summarizer
```

## See Also

- `/note` - Full note capture with all types
- `/tasks` - Manage and triage tasks
- `/tasks expand <task>` - Elaborate on a task

