---
description: Research a topic and save a structured report to Basic Memory
argument-hint: <topic> [folder]
allowed-tools: mcp__basic-memory__write_note, mcp__basic-memory__search_notes, mcp__basic-memory__read_note, mcp__basic-memory__build_context, web-search, web-fetch, codebase-retrieval, view
---

# Research

Research a topic thoroughly and produce a structured report saved to Basic
Memory.

## Prerequisites

First, read and follow the skill at:
`~/.augment/skills/storm/SKILL.md`

## Arguments

- `$1` - Topic to research (required)
- `$2` - Folder to save report (optional, default:
  "artifacts/research")

## Your Task

Conduct thorough research on:
**$ARGUMENTS**

### 1. Check Existing Knowledge

First, see what we already know:

```python
search_notes_basic - memory(query="$1")
```

Read any relevant existing notes to avoid duplicating research.
Build context from related notes:

```python
build_context_basic - memory(url="memory://related-topic", depth=2)
```

### 2. Gather Information

Depending on the topic, use appropriate tools:

**For codebase topics:**

- Use `codebase-retrieval` to find relevant code
- Use `view` to read specific files
- Check tests for usage examples

**For external topics:**

- Use `web-search` for current information
- Use `web-fetch` for documentation
- Look for official sources

**For Basic Memory context:**

- Build context from related notes
- Check for prior decisions or research

### 3. Analyze Findings

Synthesize what you learned:

- Identify key concepts
- Note patterns and trade-offs
- Form recommendations if applicable
- Flag uncertainties

### 4. Produce Report

Create a structured report following the template in the research skill.

### 5. Save Report

```python
write_note_basic - memory(
    title="Research: $1",
    content="[report content]",
    directory="$2" or "artifacts/research",
    tags=["research", ...],
)
```

### 6. Present Summary

After saving, present:

- Key findings summary (3-5 bullet points)
- Main recommendation (if applicable)
- Where the report was saved
- Offer to dive deeper into any aspect

## Examples

```text
/research MCP protocol
/research "database migration patterns"
/research "authentication options" decisions
/research "BERTopic vs LDA" research
/research "Graphiti knowledge graph"
```

## Output Format

Always end with:

```text
## 📝 Research Complete

**Saved to:** artifacts/research/[topic].md

**Key Findings:**
1. [Most important finding]
2. [Second finding]
3. [Third finding]

**Recommendation:** [If applicable]

Would you like me to:
- Dive deeper into any finding?
- Research a related topic?
- Connect this to existing notes?
```
