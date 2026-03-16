---
description: Thoroughly investigate a topic, codebase area, or concept through layered exploration
argument-hint: <topic or path> [quick|standard|thorough]
---

# Deep Dive

Intensive, focused exploration through progressive layers of understanding.

## Prerequisites

First, read and follow the skill at:
`~/.augment/skills/deep-dive/SKILL.md`

## Arguments

- `$1` - Topic, file path, or concept to explore (required)
- `$2` - Depth level:
  `quick`, `standard`, or `thorough` (optional, default:
  standard)

## Your Task

Deep dive into:
**$ARGUMENTS**

### 1. Identify the Target

Determine what we're exploring:

**If it looks like a path** (contains `/` or `.py`, `.ts`, etc.):

- Start with that file/directory
- Use `view` and `get_symbols_overview`

**If it's a symbol name** (CamelCase or snake_case):

- Use `find_symbol` to locate it
- Then trace from there

**If it's a concept**:

- Search Basic Memory first
- Then codebase-retrieval or web-search

### 2. Follow the Layers

Based on depth level:

| Depth | Layers to Complete |
|-------|-------------------|
| quick | Surface Survey, Structure Analysis |
| standard | + Implementation Details, Edge Cases |
| thorough | + Full Synthesis with documentation |

### 3. Present Progressively

As you explore each layer:

- Share key findings as you go
- Ask if the user wants to go deeper on any aspect
- Offer to trace specific paths

### 4. Synthesize

Create the mental model at the end:

- Summary of understanding
- Key components and their roles
- Critical paths
- Gotchas and caveats

### 5. Save (for standard/thorough)

```python
write_note_basic - memory(
    title="Deep Dive: $1",
    content="[synthesis content]",
    directory="knowledge/deep-dives",
    tags=["deep-dive", "understanding"],
)
```

## Examples

```text
/dive src/auth/
→ Explores the auth module, traces key flows, documents understanding

/dive PaymentProcessor thorough
→ Full deep dive into PaymentProcessor class with complete synthesis

/dive "how rate limiting works" quick
→ Quick overview of rate limiting implementation

/dive kubernetes service mesh
→ Standard exploration of the concept with codebase and web search
```

## Output Format

Always end with:

```markdown
## 🔍 Deep Dive Complete: [Topic]

**Saved to:** knowledge/deep-dives/[topic].md

### Mental Model

[How this works in 2-3 sentences]

### Key Components

| Component | Purpose |
|-----------|---------|
| [X] | [Does Y] |

### Critical Path

[Most important flow]

### Gotchas

- [Caveat 1]
- [Caveat 2]

### Now You Can

- [What this understanding enables]

Would you like me to:

- Go deeper into any component?
- Trace a specific code path?
- Explore related areas?
```

## See Also

- `/storm` - Multi-perspective research with expert viewpoints
- `/brainstorm` - Collaborative design exploration
- `/research` - General research and documentation
