---
name: showcase-generation
description: Use when generating or updating annotated files for the showcase repository
---

# Showcase Generation

## Planning Phase (Required Before Generation)

Before generating any showcase content, complete this planning phase to ensure
depth and coverage.
This prevents the "breadth without depth" failure mode of autonomous generation.

### Step 1: Discover Available Content

Query Basic Memory for source material:

```text
1. Search for multi-session arcs: search_notes(query="multi-session arc")
2. List arc notes: build_context(url="memory://journal/arcs/*")
3. Check session notes: recent_activity(timeframe="30d")
```

### Step 2: Inventory Case Study Candidates

Create a candidate list with selection criteria:

| Arc | Sessions | Exchanges | Pattern | Showcase Value |
| --- | -------- | --------- | ------- | -------------- |
| {name} | {count} | {total} | {pattern} | High/Medium/Low |

**Showcase value criteria:**

- **High**:
  Multiple sessions, clear narrative arc, demonstrates skill/command usage,
  contains pivots or insights
- **Medium**:
  Useful pattern, fewer sessions, less dramatic arc
- **Low**:
  Routine work, minimal learning content

### Step 3: Plan Reference Depth

Decide which items get full-depth (100-200 lines) vs summary (30-60 lines):

| Category | Full Depth | Summary | Skip |
| -------- | ---------- | ------- | ---- |
| Rules | Core workflow rules | Utility rules | - |
| Skills | Top 6-8 most used | Domain-specific | Rarely used |
| Agents | Ralph loop agents | Utility agents | Experimental |
| Hooks | Core hooks | Simple wrappers | - |
| Commands | /brainstorm, /ralph, /dive | Utility commands | - |

### Step 4: Identify Emergent Insights

Before writing, identify insights that require dialogue to surface:

- What patterns emerged across multiple arcs?
- What "bootstrap" moments changed the configuration?
- What named concepts exist (e.g., "The Iron Law", "Bootstrap Pattern")?
- What trade-offs were consciously chosen?

**If running autonomously:** Flag these for later interactive enrichment rather
than inventing generic content.

### Step 5: Create Content Plan

Output a content plan before generating files:

```markdown
## Content Plan

### Case Studies (prioritized)
1. {name} - {why high value} - Full treatment
2. {name} - {why medium value} - Standard treatment
3. {name} - Skip or brief mention

### Reference Sections
- Rules: Full depth for {list}, summary for {list}
- Skills: Full depth for {list}, summary for {list}
- etc.

### Identified Gaps
- Need interactive session to surface: {topic}
- Missing source material for: {topic}
```

## Perspective: First-Person from the user's POV

All showcase content is written from **the user's perspective as the developer** who
configured this system.
The AI is a tool he uses, not the narrator.

### Correct Framing

| Context | Correct | Incorrect |
| --- | --- | --- |
| Describing a skill | "I use this skill to ensure the AI writes tests first" | "I invoke this skill to prevent my most common failure mode" |
| Describing a rule | "This rule prevents the AI from committing without my permission" | "I never commit without explicit authorization" |
| Describing a hook | "This hook catches lint errors before I see the AI's output" | "This hook ensures I fix lint errors" |
| Describing an agent | "I dispatch this agent when I need focused code review" | "I review code when the user asks" |

### Key Distinction

- **"I"** = Matt (the developer who configured the system)
- **"The AI"** or **"the agent"** = the AI assistant being configured
- **"The skill/rule/hook"** = configuration that shapes AI behavior

## Prose Style

**Matter-of-fact prose only.** No humanizing the system, no evaluative language.

| Avoid | Use Instead |
| --- | --- |
| "amazing", "inspiring", "incredible" | (just describe what it does) |
| "This elegant solution..." | "This approach..." |
| "The AI brilliantly handles..." | "The AI handles..." |
| "greatly improved", "much better" | Specific measurable claims or nothing |

## Voice and Depth

### Personal Voice vs Generic Explanation

Interactive sessions produce content with the user's specific voice and insights.
Autonomous generation tends toward generic explanations.

**Interactive voice (preferred):**

> "I use the Basic Memory MCP to keep a living knowledge base of my work, as I
> work."
>
> "Have the AI modify its config every time it does something 'wrong'. It will
> get better at doing what you actually want faster than you think."

**Generic voice (avoid in philosophy/overview docs):**

> "The agent should never perform destructive operations without explicit
> permission."
>
> "Basic Memory provides persistent knowledge storage."

### When to Flag for Interactive Enrichment

Mark sections that need dialogue to surface authentic voice:

```markdown
<!-- TODO: Interactive enrichment needed -->
<!-- This section explains the mechanism but lacks the user's specific insights -->
<!-- about why he chose this approach or what he learned from using it -->
```

### Depth Indicators

Full-depth annotations should include these personal elements:

- **"Why I created this"** - The specific problem, not a generic use case
- **Named patterns** - If Matt has a name for it ("The Bootstrap Pattern", "The
  Iron Law"), use it
- **Trade-off rationale** - Why this choice over alternatives, from experience
- **Evolution notes** - How this changed over time based on usage

### Emergent Insights to Capture

These insights only surface through extended dialogue:

- Bootstrap moments:
  "When I first started, I did X.
  Now I do Y because..."
- Named concepts:
  Patterns Matt has named and uses repeatedly
- Cross-cutting learnings:
  Insights that apply across multiple arcs
- Counter-intuitive discoveries:
  Things that worked differently than expected

**If autonomous:** Note that these are missing rather than inventing
placeholders.

## Model Names

Use consistent model identifiers (as they appear in agent frontmatter):

| Correct | Incorrect |
| --- | --- |
| `sonnet4.5` | `claude-3-5-sonnet`, `sonnet-4.5`, `claude-sonnet` |
| `opus4.5` | `opus-4.5`, `claude-opus` |
| `haiku4.5` | `haiku-4.5`, `claude-haiku` |

**Avoid `inherit`** - every agent should explicitly declare its model.
`inherit` creates unpredictable behavior when the user's selected model doesn't
match the agent's capability requirements.

## Design Philosophy

**Experimentation is encouraged.** It's fine to create agents proactively and
see how often they get used (explicitly or auto-selected by Augment).
Low-use agents can be refined, merged, or removed.
Low-cost experimentation beats over-planning.

## Case Study Structure

Each case study folder requires three components:

```text
case-studies/{case-name}/
├── README.md           # Main narrative (100-200 lines)
├── arc.md              # Arc metadata and session timeline
└── sessions/           # Individual session summaries
    ├── 01-{session-name}.md
    ├── 02-{session-name}.md
    └── ...
```

### README.md (Main Narrative)

The primary document.
Include:

- **Overview table**:
  Sessions, total exchanges, date range, pattern, artifacts
- **The Problem**:
  What I was trying to solve
- **Session Timeline**:
  Brief summary of each session with quotes
- **What Made This Work**:
  Patterns that contributed to success
- **Key Takeaways**:
  Bullets summarizing learnings

### arc.md (Arc Metadata)

Structured metadata pulled from Basic Memory arc notes:

```markdown
# Multi-Session Arc: {Name}

{One-line description}

## Arc Metadata

- arc_type: {brainstorm|investigation|implementation|documentation}
- sessions: {count}
- total_exchanges: {total}
- date_range: {YYYY-MM-DD to YYYY-MM-DD}
- outcome: {brief outcome}

## Session Timeline

| # | Session | Exchanges | Date | Focus |
|---|---------|-----------|------|-------|
| 1 | {name} | {count} | {date} | {focus} |

## Arc Pattern

{Pattern description, e.g., "Brainstorm → Build → Document"}

## Notable Characteristics

- {characteristic 1}
- {characteristic 2}

## Key Artifacts

- {artifact 1}
- {artifact 2}
```

### Session Files (Individual Details)

Each session file provides substantive detail beyond what's in the README.
Include:

- **Metadata**:
  session_id, date, exchanges, category
- **Initial Prompt**:
  The actual prompt (or summary if long)
- **What I Was Doing**:
  Context for why this session happened
- **What Happened**:
  Detailed subsections describing the work
- **Key Takeaways**:
  Session-specific learnings

**Session file substance matters.** Include:

- Actual quotes from the conversation (with `> **Me:**` and `> **Agent:**`
  format)
- Structured "What Happened" subsections describing phases of work
- Specific details that add value beyond the README summary

### Single-Session Arcs

Single-session arcs are valid case studies.
Marathon sessions (300+ exchanges) often contain enough material for a complete
case study with iterative refinement within one conversation.

## Markdownlint Patterns

### Consecutive Blockquotes (MD028)

**Wrong** - blank line between blockquotes:

```markdown
> **Me:** first quote

> **Agent:** second quote
```

**Correct** - join with `>` continuation:

```markdown
> **Me:** first quote
>
> **Agent:** second quote
```

### Headers in Blockquotes (MD025)

**Wrong** - markdown header inside blockquote:

```markdown
> # Ralph Wiggum Development Flow
>
> Execute the workflow...
```

**Correct** - describe instead of quoting the header:

```markdown
The Ralph Wiggum system prompt followed by the task:

> Improve logging throughout this project with the following requirements...
```

### Lists in Blockquotes (MD032)

**Wrong** - list directly in blockquote without spacing:

```markdown
> **Log Level Guidelines:**
> - ERROR: Exceptions
> - WARNING: Recoverable errors
```

**Correct** - restructure to prose or separate from quote:

```markdown
Log Level Guidelines: ERROR for exceptions, WARNING for recoverable errors,
INFO for request/response summaries, DEBUG for detailed execution flow.
```

## Content Sourcing

Pull case study content from Basic Memory:

1. **Arc notes**:
   `journal/arcs/multi-session-arc-{name}`
2. **Session notes**:
   `journal/sessions/YYYY/MM/{session-name}`
3. **Learning notes**:
   `learnings/{topic}`

Include actual quotes and specific details from these sources rather than
generic summaries.

## File Types

### Full Depth Annotations (100-200 lines)

For core workflow items.
Include:

- Why I Created This
- How It Works (detailed breakdown)
- Key Design Decisions
- Integration Points
- Example in Action

### Summary Annotations (30-50 lines)

For less critical items.
Include:

- Purpose (1-2 sentences)
- Key Points (3-5 bullets)
- Notable Choices
- Related Items

See `REFERENCE.md` for complete templates and examples.

## Reference Content

See `REFERENCE.md` for detailed patterns:

- Markdownlint patterns and fixes
- Directory structure
- Source link mapping
- Full-depth and summary annotation templates
- Execution modes (autonomous vs interactive)

## Quality Checklist

Before completing any showcase file:

- [ ] Perspective is from the user's POV (not the AI's)
- [ ] "I" refers to Matt, "the AI/agent" refers to the assistant
- [ ] Prose is matter-of-fact (no "amazing", "inspiring", etc.)
- [ ] File passes markdownlint with showcase config
- [ ] Consecutive blockquotes use `>` continuation (not blank lines)
- [ ] No markdown headers inside blockquotes
- [ ] Links to related items are valid
- [ ] Line count is appropriate (full:
  100-200, summary:
  30-60)
- [ ] Session files include actual quotes and substantive detail
- [ ] Planning phase completed before generation (for autonomous mode)
- [ ] Gaps flagged for interactive enrichment (for autonomous mode)
