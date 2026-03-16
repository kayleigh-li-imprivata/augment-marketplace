---
description: Review, triage, and manage tasks in your Basic Memory backlog
argument-hint: [list|triage|expand <task>|active|done|search <query>]
allowed-tools: list_directory_basic-memory, search_notes_basic-memory, read_note_basic-memory, edit_note_basic-memory, move_note_basic-memory, write_note_basic-memory
---

# Tasks

Review, triage, and manage tasks across your Basic Memory planning system.

## IMPORTANT: Use Basic Memory Tools

**ALWAYS use Basic Memory MCP tools for all operations.** Do NOT use filesystem tools.

| Operation | Use This Tool |
|-----------|---------------|
| List tasks | `list_directory_basic-memory(dir_name="planning/tasks/...")` |
| Read task | `read_note_basic-memory(identifier="planning/tasks/...")` |
| Search | `search_notes_basic-memory(query="...")` |
| Edit task | `edit_note_basic-memory(identifier="...", ...)` |
| Move task | `move_note_basic-memory(identifier="...", destination_path="...")` |

## Subcommands

| Command | Description |
|---------|-------------|
| `/tasks` | Show dashboard overview |
| `/tasks list` | List all backlog tasks |
| `/tasks triage` | Interactive review of backlog tasks one-by-one |
| `/tasks expand <task>` | Elaborate on a task through clarifying questions |
| `/tasks active` | Show tasks currently in progress |
| `/tasks done` | Show recently completed tasks |
| `/tasks search <query>` | Search tasks by keyword |

## Your Task

### `/tasks` (no arguments) - Dashboard

Show a quick overview. Call these Basic Memory tools:

```python
list_directory_basic-memory(dir_name="planning/tasks/backlog", depth=1)
list_directory_basic-memory(dir_name="planning/tasks/active", depth=1)
list_directory_basic-memory(dir_name="planning/tasks/done", depth=1)
```

Present as:

```
## 📋 Task Dashboard

| Status | Count |
|--------|-------|
| 🔴 Backlog | X tasks |
| 🟡 Active | X tasks |
| ✅ Done | X tasks |

### 🔥 High Priority (P0/P1)
- [Task Name] - P0, backlog
- [Task Name] - P1, active

### Recent Activity
- [Task] moved to done (2 days ago)
- [Task] created (3 days ago)

**Quick actions:** `/tasks triage` | `/tasks list` | `/tasks active`
```

### `/tasks list` - List Backlog

List all tasks in backlog with priority:

```
## 📝 Backlog Tasks

### P0 - Critical
- [ ] **Task Name** - [brief description]

### P1 - Important  
- [ ] **Task Name** - [brief description]

### P2 - Normal
- [ ] **Task Name** - [brief description]

### P3 - Nice to Have
- [ ] **Task Name** - [brief description]

**Total:** X tasks | `/tasks triage` to review one-by-one
```

### `/tasks triage` - Interactive Review

Go through backlog tasks one at a time:

1. Read the first/next task from backlog
2. Present it with full details
3. Ask what to do:

```
## 🔍 Triage: [Task Name]

**Priority:** P2 | **Created:** 3 days ago

### Summary
[Task summary from note]

### Acceptance Criteria
- [ ] [Criteria from note]

---

**What would you like to do?**
1. ▶️ **Start** - Move to active
2. ⬆️ **Bump priority** - Increase priority
3. ⬇️ **Lower priority** - Decrease priority  
4. 📝 **Edit** - Add details or clarify
5. ❌ **Delete** - Remove task
6. ⏭️ **Skip** - Move to next task
7. 🛑 **Stop** - End triage session
```

After each action, move to the next task until done or user stops.

### `/tasks active` - Show Active Tasks

```
## 🟡 Active Tasks

1. **[Task Name]** - P1
   Started: 2 days ago
   [Brief summary]

2. **[Task Name]** - P2
   Started: 1 week ago
   [Brief summary]

**Actions:** Pick a number to see details, or `/tasks triage` for backlog
```

### `/tasks done` - Show Completed

```
## ✅ Recently Completed

- **[Task Name]** - Completed 2 days ago
- **[Task Name]** - Completed 1 week ago
- **[Task Name]** - Completed 2 weeks ago

**Total:** X completed tasks
```

### `/tasks search <query>` - Search

Search across all task folders:

```python
search_notes_basic-memory(query="<query> task")
```

Present matching tasks with their status and location.

### `/tasks expand <task>` - Elaborate Through Questions

Take a quick task note and flesh it out through clarifying questions.

1. **Find the task** - Search or match by name:
```python
search_notes_basic-memory(query="<task>")
read_note_basic-memory(identifier="planning/tasks/backlog/<task>")
```

2. **Analyze what's missing** - Review the task and identify gaps:
   - Is the goal clear and specific?
   - Are acceptance criteria defined?
   - Is scope bounded?
   - Are dependencies identified?
   - Is technical approach outlined?

3. **Ask clarifying questions one at a time:**

```
## 🔍 Expanding: [Task Name]

Current summary: [existing summary]

---

**Question 1 of ~5**

What specific outcome should this task achieve?

a) [Inferred option based on context]
b) [Alternative interpretation]
c) Something else (please describe)
```

4. **Question categories to cover:**

| Category | Example Question |
|----------|------------------|
| **Goal** | What does "done" look like for this task? |
| **Scope** | Should this include X, or is that separate? |
| **Approach** | Would you prefer A or B approach? |
| **Dependencies** | Does this need anything else first? |
| **Acceptance** | How will we verify this works? |
| **Priority** | Is the current priority (P2) right? |

5. **After each answer, update the note:**
```python
edit_note_basic-memory(
    identifier="<task-path>",
    operation="replace_section",
    section="Summary",
    content="[Updated summary with new details]"
)
```

6. **When complete, show the updated task:**

```
## ✅ Task Expanded: [Task Name]

### Summary
[Now detailed and specific]

### Acceptance Criteria
- [ ] [Specific criterion 1]
- [ ] [Specific criterion 2]
- [ ] [Specific criterion 3]

### Technical Approach
[If discussed]

### Dependencies
[If identified]

---

Task updated at: planning/tasks/backlog/<task>.md

**Next:** `/tasks triage` | `/tasks start <task>`
```

**Key principles:**
- One question at a time
- Prefer multiple choice when possible
- Update the note after each answer
- Stop when task is well-defined (usually 3-6 questions)
- Don't over-engineer - keep it actionable

## Task Actions

When user selects an action during triage:

### Start (Move to Active)
```python
move_note_basic-memory(
    identifier="planning/tasks/backlog/<task>",
    destination_path="planning/tasks/active/<task>"
)
edit_note_basic-memory(
    identifier="planning/tasks/active/<task>",
    operation="find_replace",
    find_text="[status] not_started",
    content="[status] in_progress"
)
```

### Complete (Move to Done)
```python
move_note_basic-memory(
    identifier="planning/tasks/active/<task>",
    destination_path="planning/tasks/done/<task>"
)
edit_note_basic-memory(
    identifier="planning/tasks/done/<task>",
    operation="find_replace",
    find_text="[status] in_progress",
    content="[status] done"
)
```

### Change Priority
```python
edit_note_basic-memory(
    identifier="<task-path>",
    operation="find_replace",
    find_text="[priority] P2",
    content="[priority] P1"
)
```

## Examples

```
/tasks                    # Show dashboard
/tasks list               # List all backlog
/tasks triage             # Start interactive review
/tasks active             # Show in-progress tasks
/tasks done               # Show completed tasks
/tasks search auth        # Find tasks mentioning "auth"
```

