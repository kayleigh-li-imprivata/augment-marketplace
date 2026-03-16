---
name: knowledge-organize
description: Use when organizing the Basic Memory knowledge graph - find orphan notes, suggest relations, identify duplicates, and improve structure
---

# Knowledge Organize

This skill helps users maintain a healthy, well-connected knowledge graph.
As notes accumulate, it becomes valuable to periodically organize, link, and
curate the knowledge base.

## When to Use

Use this skill when:

- User asks to organize their notes
- User wants to find connections between notes
- User mentions orphan or unlinked notes
- User wants to clean up or improve their knowledge base
- User asks about duplicate or similar notes
- User wants help with folder organization
- User asks to review or audit their notes
- Phrases like "help me organize", "find related notes", "what's not linked",
  "clean up my notes"

## Organization Capabilities

See `REFERENCE.md` for detailed API queries and patterns:

- **Find Orphan Notes** - Identify isolated notes in the graph
- **Suggest Relations** - Analyze content for connection opportunities
- **Identify Duplicates** - Find similar or overlapping notes
- **Suggest Tags** - Tag recommendations based on existing vocabulary
- **Create Hub Notes** - Index notes that link related content
- **Analyze Structure** - Check notes follow standard templates
- **Knowledge Graph Audit** - Comprehensive person/project/repo audits
- **Fix Wiki Links** - Obsidian compatibility fixes
- **Convert Session References** - Transform IDs to wiki links

## Organization Workflows

### Quick Health Check

1. Count total notes
2. Identify orphan count
3. List recently modified
4. Check for obvious duplicates
5. Report folder distribution

### Deep Organization Session

1. **Audit phase** - Catalog all notes, identify issues
2. **Orphan phase** - Address unlinked notes
3. **Relation phase** - Suggest new connections
4. **Duplicate phase** - Merge or differentiate similar notes
5. **Structure phase** - Reorganize folders if needed
6. **Index phase** - Create hub notes for major topics

### Topic-Focused Organization

1. Find all notes related to topic
2. Map existing relations
3. Identify gaps in the topic graph
4. Suggest new notes to fill gaps
5. Create topic index note

## Wiki Link Format

Basic Memory and Obsidian use different link formats for different purposes:

### Body/Navigation Links

For clickable links in the note body (outside the Relations section), use:

```markdown
[[permalink|Display Title]]
```

**Example:**

```markdown
- [[journal/sessions/2025/12/creating-an-adr|Creating an ADR]]: Description here
```

- `permalink`:
  The note's path without `.md` (e.g., `case-studies/documentation/my-note`)
- `Display Title`:
  Human-readable title shown in rendered markdown

This format works in **both** Obsidian AND Basic Memory because:

- Obsidian uses the permalink to locate the file
- Basic Memory resolves the note via permalink

**Why title-only links don't work:**

- `[[Creating an ADR]]` fails because filenames are slugified
  (`creating-an-adr.md`)
- Obsidian can't find a file matching the exact title

### Relations Section Links

For semantic relations in the Relations section, use standard wiki-link format:

```markdown
## Relations

- relates_to [[Topic Name]]
- implements [[Parent Concept]]
```

These are standard Obsidian wiki links that Basic Memory parses for the
knowledge graph.

## Best Practices

1. **Work incrementally** - Don't reorganize everything at once
2. **Confirm before changing** - Always ask before moving/editing notes
3. **Preserve permalinks** - Moving is okay, changing permalinks breaks links
4. **Show the graph** - Help user visualize connections
5. **Explain suggestions** - Say why a relation makes sense
6. **Respect user's system** - Enhance their organization, don't impose a new
   one
7. **Use correct link format** - `[[permalink|Title]]` for body links,
   `[[Topic]]` for relations

## Example Conversations

**User:** "Help me organize my notes"

**Claude:**

1. Runs health check on the knowledge base
2. Reports:
   "You have 47 notes.
   I found 12 orphan notes and 3 potential duplicates."
3. Asks:
   "Would you like to start by connecting the orphan notes, or review the
   duplicates first?"

**User:** "Find notes that should be linked to my API design note"

**Claude:**

1. Reads the API design note
2. Searches for related content
3. Suggests:
   "I found 5 notes that could relate:
   - 'REST Best Practices' -> relates-to
   - 'Authentication Flow' -> implements
   - 'Rate Limiting Decision' -> extends Would you like me to add any of these
     relations?"

**User:** "Are there any notes about similar topics?"

**Claude:**

1. Analyzes note titles and content
2. Identifies clusters of similar notes
3. Reports:
   "I found these potential overlaps:
   - 'Auth Flow' and 'Authentication Design' cover similar ground
   - 'DB Schema v1' and 'DB Schema v2' might need a 'supersedes' relation Would
     you like to review any of these?"
