---
description: Perform a comprehensive health check on your Basic Memory knowledge graph
allowed-tools: mcp__basic-memory__search_notes, mcp__basic-memory__read_note, mcp__basic-memory__list_directory, mcp__basic-memory__edit_note, mcp__basic-memory__write_note, mcp__basic-memory__recent_activity
---

# Organize

Perform a comprehensive health check on your default Basic Memory project. This command analyzes your knowledge graph and identifies issues that need attention.

## Prerequisites

First, read and follow the skill at: `~/.augment/skills/knowledge-organize/SKILL.md`

## Your Task

When the user runs `/organize`, perform ALL of the following checks on the default project:

### 1. Overview Statistics

1. List the directory structure to count total notes
2. Get recent activity to understand the current state
3. Report folder distribution and note counts

### 2. Find Orphan Notes

1. Search for notes that have no Relations sections or empty Relations
2. List all orphan notes found
3. For each orphan, suggest potential relations based on content similarity

### 3. Detect Potential Duplicates

1. Search for notes with similar titles
2. Compare content for significant overlap
3. Flag potential duplicates for review
4. Suggest: merge, differentiate, or link with `supersedes`

### 4. Tag Consistency Check

1. Gather all tags used across notes
2. Identify similar/duplicate tags (e.g., `arch` vs `architecture`)
3. Find over-used or under-used tags
4. Suggest normalization opportunities

### 5. Relation Suggestions

1. For notes with few relations, search for related content
2. Suggest relation types:
   - `relates-to` - General connection
   - `extends` - Builds upon
   - `implements` - Realizes concept
   - `depends-on` - Requires understanding of

## Output Format

Present findings in a clear, actionable report:

```
## 📊 Knowledge Graph Health Report

### Overview
- Total notes: X
- Folders: [list]
- Last activity: [date]

### 🔴 Issues Found

#### Orphan Notes (X found)
- [note1] - suggested relation: relates-to [note2]
- [note3] - suggested relation: extends [note4]

#### Potential Duplicates (X pairs)
- [noteA] ↔ [noteB] - 80% title similarity

#### Tag Inconsistencies (X issues)
- "arch" and "architecture" - suggest consolidating to "architecture"

### 🟡 Suggestions

#### Notes That Could Use More Relations
- [note5] - only 1 relation, consider linking to [note6]

### ✅ Healthy
- X notes have 2+ relations
- X folders with consistent organization
```

## Interaction

1. Run all checks automatically - no arguments needed
2. Present the complete report
3. Ask user which issues they'd like to address
4. For each fix, show what will change and get approval before modifying
5. Apply fixes using edit_note or write_note when user approves

Always confirm before modifying notes. Show the exact changes that will be made.

## Example Session

```
User: /organize

Agent: ## 📊 Knowledge Graph Health Report

### Overview
- Total notes: 47
- Folders: specs/, decisions/, research/, notes/
- Last activity: 2 hours ago

### 🔴 Issues Found

#### Orphan Notes (3 found)
1. "Quick Thought on Caching" - no relations
   → Suggested: relates-to [[Architecture Overview]]

2. "API Design Notes" - no relations  
   → Suggested: extends [[REST Guidelines]]

...

Would you like me to:
1. Add suggested relations to orphan notes?
2. Review and merge potential duplicates?
3. Normalize inconsistent tags?

Or pick specific items to address.
```

