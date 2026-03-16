---
name: storm
description: Use when deep research is needed from multiple expert perspectives - comprehensive analysis, architectural decisions, exploring complex topics, or synthesizing information with citations
---

# STORM Research

This skill implements the STORM pattern (Synthesis of Topic Outlines through
Retrieval and Multi-perspective Question Asking) from Stanford for deep,
comprehensive research.

## When to Use

Use this skill when:

- User asks to research, investigate, or explore a topic in depth
- User wants comprehensive analysis from multiple viewpoints
- User needs context before making architectural or design decisions
- Complex topics requiring expert perspectives (security, performance, UX, etc.)
- Phrases like "research this", "deep dive into", "explore options for"

## Output Storage

**CRITICAL:** All STORM research output MUST be saved to Basic Memory using
`write_note_basic-memory`.
NEVER use `save-file` or write files to the local filesystem.

## Related Skills

**Use `deep-dive` first if:** You need to understand existing code or systems
before researching external options.
STORM assumes you know what you have; deep-dive builds that understanding.

**Use `deep-dive` after if:** STORM research concludes you need deeper
understanding of a specific component before deciding.

## STORM Process Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: Perspective Discovery │
│ → Survey similar topics to identify relevant expert viewpoints │
├─────────────────────────────────────────────────────────────────┤
│ PHASE 2: Multi-Perspective Research (PARALLEL) │
│ → Spawn subagents per perspective for simulated conversations │
├─────────────────────────────────────────────────────────────────┤
│ PHASE 3: Outline Synthesis │
│ → Merge insights into hierarchical outline by theme │
├─────────────────────────────────────────────────────────────────┤
│ PHASE 4: Report Generation │
│ → Generate report with citations, save to Basic Memory │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 1: Perspective Discovery

### Goal

Identify 3-5 expert perspectives relevant to the topic by surveying existing
knowledge.

### Process

1. **Check Basic Memory** for existing context:

```python
search_notes_basic-memory(query="topic keywords")
build_context_basic-memory(url="memory://related-topic", depth=2)
```

1. **Survey similar topics** via web search:

```python
web-search(query="[topic] best practices expert perspectives")
web-search(query="[topic] considerations trade-offs")
```

1. **Extract perspectives** from search results.
   Look for different professional roles discussing the topic, recurring
   concerns or focus areas, and conflicting viewpoints or trade-offs.

1. **Define perspectives** based on what you discovered.
   These are NOT hard-coded - they emerge from the topic research.
   Document them:

```markdown
## Discovered Perspectives

For topic: "[TOPIC]"

| Perspective | Focus Areas | Key Questions |
|-------------|-------------|---------------|
| [Role found in sources] | [Their concerns] | [Questions they'd ask] |
| [Another role] | [Their concerns] | [Questions they'd ask] |
| ... | ... | ... |
```

**Example for "Kubernetes service mesh":**

| Perspective | Focus Areas | Key Questions |
|-------------|-------------|---------------|
| Security Engineer | mTLS, network policies, zero-trust | How is traffic encrypted? |
| Platform Engineer | installation, upgrades, resource overhead | How do I operate this? |
| Application Developer | service discovery, retries, observability | How do I use this in my code? |
| SRE | debugging, latency impact, failure modes | How do I troubleshoot issues? |

**Example for "Authentication strategy for API":**

| Perspective | Focus Areas | Key Questions |
|-------------|-------------|---------------|
| Security Architect | attack vectors, token security, compliance | What are the vulnerabilities? |
| Backend Developer | library support, implementation complexity | How do I implement this? |
| Mobile Developer | token storage, refresh flows, offline | How does this work on mobile? |
| Product Manager | user friction, onboarding, conversion | What's the UX impact? |

## Phase 2: Multi-Perspective Research (Parallel)

For each perspective, conduct a simulated conversation between a "writer" and
"topic expert" to generate deep, grounded insights.

**Spawn parallel subagents** - one per perspective:

```python
# Security perspective
sub-agent-explore(
 name="storm-security",
 instruction="""
 Research "[TOPIC]" from a Security Engineer perspective.

 SIMULATED CONVERSATION PROCESS:
 1. As a Security Engineer, generate 3 initial questions about [TOPIC]
 2. Search for answers using web-search and codebase-retrieval
 3. Based on findings, generate 2 follow-up questions that dig deeper
 4. Search for those answers
 5. Generate 1 final clarifying question if needed

 OUTPUT FORMAT:
 ## Security Engineer Perspective

 ### Questions Asked
 1. [Question] → [Answer with citation]
 2. [Follow-up] → [Answer with citation]
 ...

 ### Key Findings
 - [Finding 1 with source]
 - [Finding 2 with source]

 ### Perspective-Specific Concerns
 - [Concern 1]
 - [Concern 2]

 ### Recommendations
 - [Recommendation from this perspective]
 """
)

# Developer perspective (runs in parallel)
sub-agent-explore(name="storm-developer", instruction="...")

# Platform perspective (runs in parallel)
sub-agent-explore(name="storm-platform", instruction="...")
```

### Conversation Depth

Each perspective should have 2-3 "turns":

```text
Turn 1: Initial questions → Search → Answers
Turn 2: Follow-up questions based on Turn 1 → Search → Answers
Turn 3: Clarifying questions if gaps remain → Search → Answers
```

This mimics STORM's simulated conversation where the expert's answers inform the
next round of questions.

## Phase 3: Outline Synthesis

After all perspective subagents complete, synthesize their findings into a
unified outline organized by **theme** (not by perspective).

**Use think-strategies for outline generation:**

```python
think-strategies_think-strategies(
 strategy="tree_of_thoughts",
 thought="""
 I have research findings from 4 perspectives on [TOPIC]:
 - Security: [key points]
 - Developer: [key points]
 - Platform: [key points]
 - Product: [key points]

 Generate a hierarchical outline that organizes these by THEME:
 - Where do perspectives agree? (high confidence)
 - Where do they conflict? (trade-offs)
 - What unique insights did each reveal?
 """,
 thoughtNumber=1,
 totalThoughts=3,
 nextThoughtNeeded=True
)
```

**Outline structure should be thematic:**

```markdown
## Outline: [TOPIC]

### 1. Core Concepts
- Definition and scope (all perspectives agree)
- Key terminology

### 2. Implementation Approaches
- Option A: [Developer perspective primary]
- Option B: [Platform perspective primary]
- Trade-offs between approaches

### 3. Security Considerations
- Threat model (Security perspective)
- Mitigation strategies
- Compliance requirements

### 4. Operational Concerns
- Deployment (Platform perspective)
- Monitoring and observability
- Scaling considerations

### 5. User Impact
- Experience implications (Product perspective)
- Adoption considerations
```

## Phase 4: Report Generation

Generate the final report by populating the outline with collected information.

**CRITICAL:
Use Basic Memory Only**

MUST use `write_note_basic-memory` to save the report - NEVER use `save-file` or
write to the local filesystem.
The `directory` parameter is a Basic Memory path, not a filesystem path.

**Report Template:**

```markdown
---
title: "[Topic]"
type: research
tags:
 - research
 - storm
 - [topic-tags]
---

# [Topic]

## Summary

[2-3 sentence executive summary synthesizing key findings across perspectives]

## Research Question

[What we set out to understand]

## Perspectives Consulted

| Perspective | Focus | Key Insight |
|-------------|-------|-------------|
| [Role 1] | [Focus area] | [One-line insight] |
| [Role 2] | [Focus area] | [One-line insight] |

## Key Findings

### Finding 1: [Theme]

**Consensus:** [What perspectives agree on]

**Evidence:**
- [Source 1]: [Quote or summary]
- [Source 2]: [Quote or summary]

**Trade-offs:** [Where perspectives differ, if applicable]

### Finding 2: [Theme]
[Same structure]

## Analysis

[Synthesis across findings - patterns, implications, recommendations]

## Open Questions

- [Questions that emerged but weren't fully answered]
- [Areas needing deeper investigation]

## Sources

- [URL 1] - [Description]
- [URL 2] - [Description]
- [[Related Note]] - [How it relates]

## Observations

- [finding] Key insight from multi-perspective analysis #research #storm
- [tradeoff] Trade-off identified between perspectives
- [recommendation] Action suggested based on synthesis

## Relations

- researches [[Topic]]
- informs [[Decision or Implementation]]
- relates-to [[Related Concepts]]
```

**Save to Basic Memory:**

```python
write_note_basic-memory(
 title="[Topic]",
 content="[Full report]",
 directory="knowledge/research",
 tags=["research", "storm", "topic-tags"]
)
```

## Quick vs Deep Research

Adjust the STORM depth based on the request:

### Quick Research (15-20 min)

- 2-3 perspectives
- 1-2 conversation turns per perspective
- Shorter report focused on key findings

### Deep Research (30-45 min)

- 4-5 perspectives
- 2-3 conversation turns per perspective
- Comprehensive report with full analysis

## Best Practices

1. **Perspectives should be genuinely different** - avoid overlapping viewpoints
1. **Each perspective must ground answers in sources** - no speculation
1. **Follow-up questions should dig deeper** - not just rephrase
1. **Outline by theme, not perspective** - synthesize, don't just concatenate
1. **Cite everything** - every claim needs a source
1. **Note conflicts explicitly** - trade-offs are valuable findings
1. **Save incrementally** - perspective summaries can be saved as sub-notes

## Example Invocation

**User:** `/storm Kubernetes service mesh options`

**Agent Process:**

1. **Phase 1:** Discover perspectives (Security Engineer, Platform Engineer,
   Developer, SRE)

1. **Phase 2:** Spawn 4 parallel subagents, each researches from their
   perspective with 2-3 conversation turns

1. **Phase 3:** Synthesize outline (Core concepts, Implementation options,
   Security, Operations, Trade-offs)

1. **Phase 4:** Generate report and save to Basic Memory via
   `write_note_basic-memory(directory="knowledge/research")`

## Completion Format

Always end with:

```markdown
## STORM Research Complete

**Saved to Basic Memory:** `memory://knowledge/research/[topic]`

**Perspectives Consulted:**
- [Perspective 1]: [Key insight]
- [Perspective 2]: [Key insight]
- [Perspective 3]: [Key insight]

**Key Findings:**
1. [Most important cross-perspective finding]
2. [Second finding]
3. [Third finding]

**Trade-offs Identified:**
- [Trade-off 1]
- [Trade-off 2]

**Recommendation:** [If applicable]

Would you like me to:
- Dive deeper into any perspective?
- Research a related topic?
- Draft implementation based on findings?
```

## References

- [Stanford STORM](https://github.com/stanford-oval/storm) - Original
  implementation
- [STORM Paper (NAACL 2024)](https://aclanthology.org/2024.naacl-long.347/) -
  Academic paper
- [[Research:
  Agentic AI Patterns]] - Pattern evaluation
