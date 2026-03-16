# Auglog Documenter Reference

Templates and detailed patterns for documenting Augment CLI sessions.

## Single Session Content Template

```markdown
---
title: Title
type: note
permalink: main/journal/sessions/YYYY/MM/title-slug
tags:
- case-study
- [category]
- [relevant-tags]
session_id: short-session-id
date: YYYY-MM-DD
exchanges: N
category: debugging|documentation|exploration|etc
---

# Title

## Initial Prompt

> [Exact verbatim text of the user's first message that started the session]

This provides immediate context for what triggered the session.

## What I Was Doing

[1-2 sentences of context beyond the prompt - why this mattered, what led to it]

## What Happened

[2-3 paragraphs narrative with direct quotes woven in]

Include direct excerpts from key moments:

> **Me:** [verbatim user message]
>
> **Agent:** [verbatim agent response, can be abbreviated with [...] for long
> responses]

The narrative should flow around these excerpts, not just summarize them.

## Key Takeaways

- Point one
- Point two
- Point three

## Notable Exchanges

Include 3-5 pivotal moments with full verbatim text:

### [Descriptive Label - e.g., "The Breakthrough Moment"]

Context for this exchange:

> **Me:** [exact text, possibly spanning multiple messages if related]

> **Agent:** [exact text]

[Brief commentary]

## Relations

- demonstrates [[skill-or-technique]]
- involves [[tool-or-technology]]
- produced [[artifact-if-any]]
```

## Multi-Session Arc Content Template

For arcs, create an arc summary in `journal/arcs/`.
Individual session case studies are optional - the arc note can stand alone.

**Arc Summary Template:**

```markdown
---
title: Multi-Session Arc: [Arc Name]
type: note
permalink: main/journal/arcs/multi-session-arc-[name-slug]
tags:
- multi-session-arc
- [pattern-type]
- [relevant-tags]
---

# Multi-Session Arc: [Arc Name]

[One sentence describing what the arc accomplished]

## Arc Metadata

- arc_type: [brainstorm-to-document | plan-create-refine | investigation | etc]
- sessions: N
- total_exchanges: N
- date_range: YYYY-MM-DD to YYYY-MM-DD
- outcome: [What was produced or resolved]

---

## Session Timeline

Session IDs link to their case study notes using wiki link format:
`[[Case Study Title|short_id]]`

### Session 1: [[Case Study Title|short_id]] ([N] exch) - YYYY-MM-DD HH:MM

**Key contribution:** [1-2 sentences]

Key exchange:

> **Me:** [brief excerpt]
>


## Discovering Multi-Session Arcs

Arcs are 2-4+ sessions focused on a specific task - not just "all sessions
about a topic" but sessions that form a coherent unit of work with progression.

### Arc Discovery Strategies

Use ALL of these strategies to find complete arcs.

**Setup:**

```python
from auglog import load_all
all_sessions = load_all()
```

### 1. Artifact References

Sessions that reference specs, ADRs, or artifacts created in earlier sessions:

```python
# Find sessions referencing prior work
artifact_patterns = [
    "considering the",
    "based on the",
    "the spec",
    "the adr",
    "we discussed",
    "we created",
    "prior work",
    "following up",
]
for s in all_sessions:
    first_msg = s.chat_history[0].exchange.request_message.lower()
    if any(p in first_msg for p in artifact_patterns):
        print(f"{s.session_id[:8]} | {s.created} | {first_msg[:80]}")
```

### 2. Brainstorm Sessions (Arc Starters)

Sessions using `/brainstorm` often CREATE the artifacts other sessions
reference:

```python
# Find brainstorm sessions - these often START arcs
for s in all_sessions:
    first_msg = s.chat_history[0].exchange.request_message
    if "# Brainstorm" in first_msg or "brainstorm" in first_msg.lower()[:100]:
        print(f"{s.session_id[:8]} | {s.created} | {len(s.chat_history)} exch")
```

### 3. Continuation Signals

Sessions explicitly continuing prior work:

```python
continuation_signals = [
    "continue",
    "resume",
    "memory://",
    "## TODO",
    "pick up where",
    "following up",
    "as we discussed",
]
for s in all_sessions:
    first_msg = s.chat_history[0].exchange.request_message.lower()
    if any(sig in first_msg for sig in continuation_signals):
        print(f"{s.session_id[:8]} references prior work")
```

### 4. Temporal Clustering

Multiple sessions on the same day working on related topics:

```python
from collections import defaultdict

# Group sessions by date
by_date = defaultdict(list)
for s in all_sessions:
    date_str = s.created.strftime("%Y-%m-%d")
    first_msg = s.chat_history[0].exchange.request_message[:100]
    by_date[date_str].append((s.session_id[:8], len(s.chat_history), first_msg))

# Find dates with multiple related sessions
for date, sessions_list in by_date.items():
    if len(sessions_list) >= 3:
        print(f"\n=== {date} ({len(sessions_list)} sessions) ===")
        for sid, exch, msg in sessions_list:
            print(f"  {sid} | {exch:3} | {msg[:60]}")
```

### 5. Response Text Analysis

Check agent responses for artifact mentions (catches indirect references):

```python
# Search both user messages AND agent responses
for s in all_sessions:
    all_text = ""
    for exch in s.chat_history[:5]:
        all_text += exch.exchange.request_message.lower() + " "
        if exch.exchange.response_text:
            all_text += exch.exchange.response_text[:500].lower() + " "

    if "data fabric" in all_text:  # or other artifact name
        print(f"{s.session_id[:8]} mentions artifact")
```

### Common Arc Patterns

| Pattern | Description | Example |
|---------|-------------|---------|
| Brainstorm -> Build -> Document | Spec creation, implementation, then ADR | Data Fabric |
| Plan -> Create -> Refine | Planning session, main work, follow-up polish | API Versioning |
| Context -> Debug -> Document | Investigation with memory:// references | Bifrost Caching |
| Test -> Debug -> Fix | Iterative development with issues | Docs Crawler |
| Systematic Triage | Same-day multi-session focused effort | Linting Review |
| Progressive Integration | Spread over time, building on prior work | Basic Memory MCP |

### Arc Documentation Workflow

1. **Find the precursor session** - Often a brainstorm or planning session
2. **Map the full timeline** - All sessions referencing the artifact/work
3. **Identify session roles** - Which created, which extended, which refined
4. **Note parallel deep dives** - Sessions that branch off for investigation
5. **Document in journal/arcs/** - Separate from individual session case studies

### Arc Note Location

Multi-session arcs go in `journal/arcs/`, NOT in `journal/sessions/YYYY/MM/`:

```text
journal/
├── sessions/           # Individual case studies by date
│   └── 2026/02/
└── arcs/               # Multi-session arc summaries
    ├── multi-session-arc-data-fabric-architecture.md
    └── multi-session-arcs-index.md
```
