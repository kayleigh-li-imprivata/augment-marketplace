# Knowledge Organize Reference

Detailed API queries and workflow patterns for knowledge graph organization.

## Find Orphan Notes

Identify notes that have no relations to other notes.

```python
# Get all notes
mcp__basic - memory__search_notes(query="*", page_size=50, project="main")

# For each note, check if it has relations
# Orphans have empty Relations sections
```

**What to do with orphans:**

- Suggest potential relations based on content similarity
- Ask if they should be linked to existing topics
- Propose creating hub notes to connect related orphans

## Suggest Relations

Analyze note content and suggest meaningful connections.

```python
# Read a note
mcp__basic - memory__read_note(identifier="note-to-analyze", project="main")

# Search for potentially related notes
mcp__basic - memory__search_notes(query="key terms from the note", project="main")

# Suggest relations based on:
# - Shared topics or concepts
# - Complementary content (problem/solution, question/answer)
# - Sequential relationship (part 1, part 2)
# - Hierarchical (parent concept, child detail)
```

**Relation types to suggest:**

- `relates-to` - General topical connection
- `extends` - Builds upon or expands
- `implements` - Realizes a concept
- `depends-on` - Requires understanding of
- `contradicts` - Presents alternative view
- `learned-from` - Source of insight
- `enables` - Makes something possible

## Identify Similar/Duplicate Notes

Find notes that may cover the same topic.

```python
# Search for notes with similar titles or content
mcp__basic - memory__search_notes(query="topic keywords", project="main")

# Compare results for overlap
# Look for:
# - Similar titles
# - Overlapping observations
# - Same tags
```

## Suggest Tags

Analyze note content and suggest appropriate tags.

```python
# Get existing tags for consistency
mcp__basic - memory__search_notes(query="tags:*", project="main")

# Suggest tags based on:
# - Existing tag vocabulary (consistency)
# - Note content and topics
# - Related notes' tags
```

## Create Hub Notes / Indexes

Create central notes that link related content.

```python
mcp__basic - memory__write_note(
    title="Architecture Decisions Index",
    content="""
# Architecture Decisions Index

A hub linking all architecture-related decisions and patterns.

## Decisions

- [[decisions/database-selection-decision|Database Selection Decision]]
- [[decisions/api-design-patterns|API Design Patterns]]

## Relations

- indexes [[Architecture]]
""",
    directory="indexes",
    project="main",
)
```

## Analyze Note Structure

Check if notes follow standard template patterns.

```python
# Read note content
content = mcp__basic - memory__read_content(path="path/to/note.md", project="main")

# Look for standard sections:
# - ## Observations -> suggest if missing
# - ## Relations -> check for valid targets
# - ## Context -> suggest adding background
```

## Comprehensive Knowledge Graph Audit

### Person Notes Audit

1. Query GitHub for each person's recent commit activity (last 30-60 days)
2. Update "Total Commits" count if changed
3. Verify "Primary Repositories" list based on current activity
4. Ensure skills use inline hashtags format (`#architecture-design`)

```bash
# Get commits for a user in last 60 days
gh api "/repos/{owner}/{repo}/commits?author={username}&since=$(date -d '60 days ago' -I)"
```

### Project Notes Audit

1. Check linked repository for recent activity
2. Update project status (active, maintenance, archived, planning)
3. Verify the project is linked from the projects-index
4. Ensure specs and architecture docs are linked

### Repository Notes Audit

1. Verify contributor list is current
2. Update technology stack if dependencies changed
3. Check that CI/CD status reflects current state
4. Ensure repository is linked from relevant project notes

### Audit Summary Report

After completing an audit, generate a summary with:

- Files updated, notes created
- Notes requiring manual review
- Missing links identified and resolved
- Stub pages created

## Fixing Broken Wiki Links (Obsidian Compatibility)

When wiki links like `[[AI Engineering Team]]` don't resolve in Obsidian:

**Root cause:** Obsidian resolves `[[Link Text]]` by looking for a file named
`Link Text.md`.
Slugified filenames (`ai-engineering-team.md`) may NOT resolve even with
`aliases` in frontmatter - alias resolution can be unreliable.

**Solution:** Rename files to match their wiki link text exactly:

```bash
# Broken: ai-engineering-team.md
# Fixed: AI Engineering Team.md
mv "ai-engineering-team.md" "AI Engineering Team.md"
```

**When creating frequently-linked notes** (teams, indexes, key concepts):

1. Use exact title with spaces in filename:
   `AI Engineering Team.md`
2. Do NOT rely on aliases for link resolution
3. Test the link resolves in Obsidian before committing

**Diagnosing broken links:**

1. Use Obsidian MCP tools to inspect the file exists
2. Check if filename matches the link text exactly
3. If slugified, rename to include spaces

## Convert Session References to Wiki Links

For arc documents that reference sessions by ID, convert them to wiki-style
links pointing to the actual case study notes.

**Before:**

```markdown
- **3bb59894**: Created ADR for simplified data layer access interface
```

**After:**

```markdown
- [[journal/sessions/2025/12/creating-an-adr|Creating an ADR]]: Created ADR...
```

**Process:**

1. Read the arc document to find session ID patterns (`**xxxxxxxx**:`)
2. For each session ID, search Basic Memory:

   ```python
   mcp__basic - memory__search_notes(
       query="session_id: 3bb59894", page_size=2, project="main"
   )
   ```

3. Get the **permalink** from the search result
4. If found, use `edit_note_basic-memory` with `find_replace` operation
5. Replace `**session_id**:
   description` with `[[permalink|Title]]:
   description`
6. If not found, keep the bold session ID format

**Tips:**

- Search for session IDs in parallel batches (10-12 at a time)
- Use the **permalink** for the link target, **title** for display text
- Format:
  `[[permalink|Title]]` works in both Obsidian AND Basic Memory
