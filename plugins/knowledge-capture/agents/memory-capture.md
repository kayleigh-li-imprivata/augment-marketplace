# Memory Capture Agent

## Purpose
Capture architectural decisions, patterns, and project-specific knowledge into
the appropriate memory store, then commit and push to the marketplace repo so
memory persists across machines.

## Memory Stores

| Store | Location | When to use |
|---|---|---|
| **Global** (Basic Memory) | `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/memory/global/` | Cross-project patterns, architecture decisions, reusable knowledge |
| **Project-specific** | `~/.augment/plugins/marketplaces/kayleigh-li-imprivata/memory/projects/{project}/` | Project constraints, release process, infra specifics |

## Trigger Phrases

- "add what we discussed to global memory"
- "add what we discussed to {project} memory"
- "add to global memory"
- "add to workstation-clustering memory"
- "capture this to memory"
- "save this to memory"

## Workflow

When triggered, follow these steps IN ORDER:

### Step 1: Determine Target Store

Parse the trigger phrase:
- Contains "global" → write to `memory/global/artifacts/{category}/`
- Contains a project name → write to `memory/projects/{project-name}/`
- Ambiguous → ask the user which store before proceeding

### Step 2: Summarize What to Capture

Before writing anything, present a 3–5 sentence summary of what you're about
to record and ask: "Does this accurately capture what you want to save? (yes/edit)"

Do not proceed until the user confirms.

### Step 3: Write the Memory File

**For Global Memory** — create `{kebab-case-title}.md` with this format:

```markdown
---
title: {Title}
type: note
tags:
  - {tag1}
  - {tag2}
---

# {Title}

## Context
{What problem or situation prompted this pattern}

## Decision
{The chosen approach and rationale}

## Alternatives Considered
{What was ruled out and why}

## Consequences
{Tradeoffs, follow-on requirements}

## Observations
- [constraint] {text} #{tag}
- [decision] {text} #{tag}
- [pattern] {text} #{tag}

## Relations
- relates-to [[{kebab-case-note}]]
```

**CRITICAL**: Filenames and wikilinks MUST use kebab-case (e.g., `argocd-event-driven-promotion.md`, `[[argocd-notifications]]`).

**For Project Memory** — create `{kebab-case-title}.md` and add a one-line entry to `index.md`:

```markdown
- [{Title}]({filename}.md) — {one-line summary}
```

### Step 4: Reindex Global Memory (Global store only)

```bash
uvx basic-memory reindex
```

Verify output shows the new entity was indexed with no errors.

### Step 5: Show Git Diff and Ask for Approval

```bash
cd ~/.augment/plugins/marketplaces/kayleigh-li-imprivata
git status
git diff
```

Present the diff to the user and ask: "Ready to commit and push to marketplace?"

Do NOT proceed without explicit approval.

### Step 6: Commit and Push

Only after approval:

```bash
cd ~/.augment/plugins/marketplaces/kayleigh-li-imprivata
git add memory/
git commit -m "memory: add {kebab-case-title}"
git push
```

### Step 7: Confirm

Report: file path written, reindex result, and commit SHA.

## Rules

- Always ask for content confirmation before writing (Step 2)
- Always ask for git approval before pushing (Step 5)
- Never skip reindex for global memory notes
- Never use CamelCase or snake_case in filenames or wikilinks — kebab-case only
- Never create files outside the marketplace memory directories

