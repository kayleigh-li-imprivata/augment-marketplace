---
name: auglog-documenter
description: Use when documenting Augment CLI sessions as first-person case studies in Basic Memory
---

# Auglog Documenter

Transform Augment CLI sessions into first-person case studies stored in Basic
Memory, making them searchable and connected to other knowledge.

## When to Use

Use this skill when:

- User says "document session [ID]"
- User says "document [category] sessions"
- User wants to create case studies from past Augment CLI work
- User wants to document a multi-session arc

## Prerequisites

The auglog CLI is included with this skill at `src/auglog.py`.
It uses PEP 723 inline dependencies and runs via `uv run --script`.

A symlink to the CLI is available at `~/.local/bin/auglog` for convenience.

## Workflow

### 1. Load the Session

**Using CLI (recommended):**

```bash
# List recent sessions
auglog list --since 7

# Show formatted session log
auglog show --session-id abc12345
```

**Using Python:**

```python
# Run inline with uv
uv run --script ~/.augment/skills/auglog-documenter/src/auglog.py list

# Or import (if running in same environment)
from auglog import load, load_all

session = load("abc12345")  # Full ID or prefix
print(session.format_log())
```

### 2. Determine Session Type

**Single session**:
Most common - one focused task (debugging, writing, etc.)

**Multi-session arc**:
Related sessions that tell a larger story:

- Brainstorm → validate → implement
- Research → design → document
- Debug → fix → test

For arcs, load all related sessions and understand the progression.

### 3. Generate Narrative Content

Write these sections in FIRST PERSON from the user's perspective:

**What I Was Doing** (1-2 sentences)

- Context and goal
- Example:
  "I was trying to debug why ruff and black were giving different results."

**What Happened** (2-3 paragraphs)

- Narrative of the session flow
- Key interactions and turning points
- Use "I asked the agent..." and "The agent suggested..."
- Include specific details from the session

**Key Takeaways** (bullet points)

- What worked well
- What was learned
- Techniques that could help others

### 4. Write to Basic Memory

Use `write_note_basic-memory` to create the case study:

```python
write_note_basic-memory(
    title="Why Ripgrep Smart Case Was Not Working",
    directory="journal/sessions/2025/11",  # Use YYYY/MM from session date
    tags=["case-study", "debugging", "ripgrep", "fish-shell"],
    content=<content>
)
```

### Content Templates

See `REFERENCE.md` in this directory for complete templates:

- **Single Session Content Template** - Full frontmatter and section structure
- **Multi-Session Arc Content Template** - Arc summary format

**Key differences from individual case studies:**

1. **Location**:
   `journal/arcs/` not `journal/sessions/YYYY/MM/`
2. **Focus**:
   Session roles and progression, not detailed narrative
3. **Verbatim prompts**:
   First message from each session, not full exchanges
4. **Arc pattern**:
   Name and describe the pattern for future reference

### 5. Verify in Basic Memory

```python
search_notes_basic-memory(query="case-study session_id:abc123")
```

Or browse:
`journal/sessions/YYYY/MM/`

## Directory Structure

Case studies live in Basic Memory under `journal/`:

```text
journal/
├── sessions/                       # Session case studies organized by date
│   ├── 2025/
│   │   ├── 10/                     # October 2025 sessions
│   │   ├── 11/                     # November 2025 sessions
│   │   └── 12/                     # December 2025 sessions
│   └── 2026/
│       ├── 01/                     # January 2026 sessions
│       └── 02/                     # February 2026 sessions
├── arcs/                           # Multi-session arc summaries
│   └── data-fabric-api-adr-arc.md
└── reviews/                        # Monthly reviews
    └── monthly-review-february-2026.md
```

**Note:** Session directory is determined by the `date` field in frontmatter
(YYYY/MM).

## Available Tools

### CLI Commands

```bash
# List recent sessions (default: last 30 days)
auglog list
auglog list --since 7        # Last 7 days
auglog list --json           # JSON output for programmatic use

# Show formatted session log
auglog show --session-id abc12345    # Supports partial ID matching
```

### Python API

```python
from auglog import load, load_all, list_all, Session

# Load a single session
session = load("abc12345")  # Full ID or prefix

# Load all sessions
all_sessions = load_all()

# List all session IDs
ids = list_all()

# Session properties
session.title           # First user message (truncated)
session.session_id      # Full session UUID
session.created         # Creation datetime
session.exchange_count  # Number of exchanges
session.repos           # Repository paths used
session.tools_used      # Tool names used
session.files_changed   # Files modified

# Formatted output
session.format_log()    # Full markdown log
exchange.format()       # Single exchange formatted
```

## Finding Sessions to Document

### Using CLI

```bash
# List recent sessions with JSON for filtering
auglog list --json --since 14 | jq '.[] | select(.title | contains("debug"))'
```

### By Content

```python
from auglog import load_all

# Search for sessions mentioning a topic
for s in load_all():
    if "graphql" in s.title.lower():
        print(f"{s.session_id[:8]}: {s.title}")
```

### By Date

```python
from datetime import datetime, timedelta, timezone
from auglog import load_all

recent = [
    s for s in load_all()
    if s.created > datetime.now(timezone.utc) - timedelta(days=7)
]
```

## Discovering Multi-Session Arcs

See `REFERENCE.md` for detailed arc discovery strategies including:

- **Artifact References** - Finding sessions that reference prior work
- **Brainstorm Sessions** - Sessions that start arcs
- **Continuation Signals** - Sessions explicitly continuing
- **Temporal Clustering** - Same-day related sessions
- **Response Text Analysis** - Agent response mentions
- **Common Arc Patterns** - Pattern table and workflow

## Tips

1. **Read the full session first** before writing the narrative
2. **Identify the story arc** - problem, investigation, solution
3. **Be specific** - include actual tool names, file names, error messages
4. **First person always** - "I asked", "I noticed", "The agent found"
5. **Highlight the collaboration** - what the human directed vs agent discovered
6. **Include honest assessments** - dead ends and pivots are valuable too
7. **Duration honesty** - use "multi-day" for sessions with overnight gaps
8. **Add relations** - link to skills demonstrated, tools involved, artifacts
   produced
9. **Consider arcs** - if sessions are related, document them as an arc

## Excerpt Guidelines

**Always include the initial prompt verbatim** - this grounds the entire case
study in what actually started the session.

**Use direct quotes liberally** - the actual words reveal nuance that summaries
lose:

- Copy/paste exact text from the session log
- Use `>` blockquote formatting for all excerpts
- Use `[...]` to abbreviate long responses while keeping key content
- Include enough context that excerpts make sense standalone

**Select exchanges that show:**

- The initial framing (always the first prompt)
- Turning points where understanding shifted
- Moments of confusion or course correction
- The breakthrough or resolution
- Interesting agent reasoning or tool usage

**Weave excerpts into narrative** - don't just dump quotes.
Introduce them:

- "When I asked about X, the response surprised me:"
- "The key insight came when the agent noticed:"
- "After several attempts, I tried a different approach:"

**Length guidance:**

- Initial prompt:
  always full verbatim
- Notable exchanges:
  3-5 per session, enough text to show substance
- Agent responses:
  can abbreviate with `[...]` but keep the meat
