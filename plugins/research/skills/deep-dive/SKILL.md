---
name: deep-dive
description: Use when thoroughly investigating a specific topic, codebase area, or concept - intensive exploration through layered questioning, code tracing, and progressive understanding
---

# Deep Dive

Intensive, focused exploration of a specific topic through progressive layers of
understanding.
Unlike STORM (multi-perspective research) or brainstorming (design
collaboration), deep dive is about thoroughly understanding one thing through
persistent investigation.

## When to Use

- User says "deep dive into...", "let's understand...", "walk me through..."
- Need to understand how something works before modifying it
- Investigating unfamiliar code, system, or concept
- Building mental model of complex subsystem
- Preparing to debug or extend existing functionality

## Output Storage

**CRITICAL:** All deep dive output MUST be saved to Basic Memory using
`write_note_basic-memory`.
NEVER use `save-file` or write files to the local filesystem.

## Related Skills

**Use `storm` instead if:** You need multi-perspective research on external
options, trade-off analysis with citations, or are making decisions that require
outside context (e.g., "should we use X or Y?").

**Use `storm` after if:** Deep dive reveals gaps that require researching
external solutions, best practices, or alternative approaches.

## Deep Dive Process

```text
┌─────────────────────────────────────────────────────────────────┐
│ LAYER 1: Surface Survey                                        │
│ → What exists? Entry points, public interfaces, high-level     │
├─────────────────────────────────────────────────────────────────┤
│ LAYER 2: Structure Analysis                                    │
│ → How is it organized? Components, relationships, data flow    │
├─────────────────────────────────────────────────────────────────┤
│ LAYER 3: Implementation Details                                │
│ → How does it work? Critical code paths, algorithms, state     │
├─────────────────────────────────────────────────────────────────┤
│ LAYER 4: Edge Cases and Boundaries                             │
│ → What are the limits? Error handling, constraints, gotchas    │
├─────────────────────────────────────────────────────────────────┤
│ LAYER 5: Synthesis and Mental Model                            │
│ → Consolidated understanding, diagrams, key insights           │
└─────────────────────────────────────────────────────────────────┘
```

## Layer 1: Surface Survey

**Goal:** Get oriented.
What are we looking at?

**For codebase topics:**

```python
# Find the entry points
codebase-retrieval(information_request="entry points for [topic]")

# Get file/directory overview
view(path="relevant/directory", type="directory")

# Find main symbols
find_symbol(name_path_pattern="MainClass", include_body=False, include_info=True)
```

**For concepts/documentation:**

```python
# Search existing knowledge
search_notes_basic-memory(query="topic keywords")

# External search
web-search(query="[topic] overview introduction")
```

**Output:** List the key artifacts, entry points, or concepts discovered.

## Layer 2: Structure Analysis

**Goal:** How is this organized?
What relates to what?

**Questions to answer:**

- What are the main components/modules?
- How do they relate to each other?
- What's the data flow?
- What are the dependencies?

**For code:**

```python
# Get symbol overview of key files
get_symbols_overview(relative_path="path/to/file.py", depth=1)

# Find relationships
find_referencing_symbols(name_path="MainClass", relative_path="file.py")

# Trace imports and dependencies
view(path="file.py", search_query_regex="^import|^from")
```

**Output:** Describe the structure, draw relationships between components.

## Layer 3: Implementation Details

**Goal:** How does this actually work?

**For code - trace critical paths:**

```python
# Read the implementation
find_symbol(name_path="critical_function", include_body=True)

# Follow the call chain
find_referencing_symbols(name_path="called_function", relative_path="file.py")
```

**Use structured thinking for complex logic:**

```python
think-strategies_think-strategies(
  strategy="chain_of_thought",
  thought="Tracing how [X] processes [Y]: Step 1...",
  thoughtNumber=1,
  totalThoughts=5,
  nextThoughtNeeded=True
)
```

**Output:** Explain the critical logic, algorithms, or mechanisms.

## Layer 4: Edge Cases and Boundaries

**Goal:** What are the limits, failure modes, and gotchas?

**Questions to investigate:**

- What happens when inputs are invalid?
- What are the error handling patterns?
- What assumptions does this code make?
- What are known limitations or TODOs?

```python
# Find error handling
view(path="file.py", search_query_regex="raise|except|Error")

# Find TODOs and FIXMEs
view(path="file.py", search_query_regex="TODO|FIXME|HACK|XXX")

# Find validation logic
view(path="file.py", search_query_regex="if.*not|assert|validate")
```

**Output:** Document constraints, failure modes, and caveats.

## Layer 5: Synthesis and Mental Model

**Goal:** Consolidate understanding into communicable form.

**Create the mental model:**

1. **Summary** - One paragraph explaining what this is and does
2. **Key Components** - The essential pieces and their roles
3. **Data Flow** - How information moves through the system
4. **Critical Paths** - The most important code/logic paths
5. **Gotchas** - Things to watch out for
6. **Questions Answered** - What we now understand
7. **Questions Remaining** - What's still unclear

**Save to Basic Memory (REQUIRED):**

MUST use `write_note_basic-memory` - NEVER use `save-file` or write to the local
filesystem.
The `directory` parameter is a Basic Memory path, not a filesystem path.

```python
write_note_basic-memory(
  title="[Topic]",
  content="[synthesis content]",
  directory="knowledge/research",
  tags=["deep-dive", "understanding", "<topic-tags>"]
)
```

## Output Format

Present findings progressively during exploration, then provide final synthesis:

```markdown
## Deep Dive Complete: [Topic]

**Saved to Basic Memory:** `memory://knowledge/research/[topic]`

### Mental Model

[2-3 sentence summary of how this works]

### Key Components

| Component | Purpose | Key File(s) |
|-----------|---------|-------------|
| [X] | [Does Y] | [path/to/file.py] |

### Critical Path

[Most important flow through the system]

### Gotchas

- [Important caveat 1]
- [Important caveat 2]

### Now You Can

- [What understanding enables - modify X, extend Y]

Would you like me to:
- Go deeper into any component?
- Trace a specific code path?
- Document this for future reference?
```

## Depth Control

Adjust depth based on request:

| Depth | Layers | Duration | Use Case |
|-------|--------|----------|----------|
| Quick | 1-2 | 5-10 min | Orientation, overview |
| Standard | 3-4 | 15-20 min | Working understanding |
| Thorough | All 5 | 30+ min | Deep expertise needed |

Default to **Standard** unless user specifies otherwise.
