---
name: desloppify
description: Use when assessing holistic code quality, checking health score, running subjective review, or when working on PRs and CI suggests quality check
---

# Desloppify - Code Quality Assessment

## Overview

Assess codebase quality using desloppify's mechanical scan and subjective
review.
Uses `uvx desloppify` for execution (no project dependency needed).

**Commands:**

- `/deslop` - Scan + status + suggest review if warranted
- `/deslop review` - Force full subjective review (dispatches subagent)

## Quick Reference

```bash
# Mechanical scan (fast, ~30s)
uvx desloppify scan --path .

# Check current status
uvx desloppify status

# Prepare review packet
uvx desloppify review --prepare

# Import findings after review
uvx desloppify review --import findings.json

# Show next priority finding
uvx desloppify next

# Resolve a finding
uvx desloppify resolve fixed 'what changed' \
  --attest 'I have actually [CHANGE] and I am not gaming the score' <id >--note
```

## /deslop Command Flow

```text
1. Check scan recency:
   - Read .desloppify/state.json for last_scan
   - Compare to: git log --format=%cI -1 (latest commit)
   
2. If commits since last scan:
   - Run: uvx desloppify scan --path .
   
3. Parse scan output for:
   - Current scores (overall, strict)
   - Stale subjective dimensions
   - Open T3/T4 findings count
   
4. Suggest review if:
   - Subjective dimensions marked stale
   - Strict score dropped >5% since last scan
   - T3/T4 findings > 5 open

5. Display status summary

6. Automatically proceed (see Post-Scan Behavior)
```

## Post-Scan Behavior

After displaying the status summary, automatically proceed based on findings:

**If findings exist (T3/T4 > 0):**

1. Show findings summary (count by severity/category)
2. Run `uvx desloppify next` to get first finding
3. Start fixing it immediately
4. After fix, ask:
   "Continue to next finding?
   (y/n)"
5. Repeat until all findings addressed or user stops

**If no findings:**

1. Announce "No mechanical findings - starting subjective review"
2. Execute `/deslop review` flow (dispatch subagent)

**Finding loop format:**

```text
┌─────────────────────────────────────────┐
│ Finding 1/N: [title]                    │
│ File: src/foo.py:42                     │
│ Issue: [description]                    │
├─────────────────────────────────────────┤
│ [Implement fix]                         │
├─────────────────────────────────────────┤
│ Fixed. Resolving...                     │
│ uvx desloppify resolve fixed '...' --id │
│                                         │
│ Continue to next finding? (y/n)         │
└─────────────────────────────────────────┘
```

**Exit points:**

- User says "n" or "stop" or "enough" - end loop, show remaining count
- All findings resolved - proceed to subjective review if dimensions stale
- User explicitly asks for something else - honor that request

## /deslop review Command Flow

Dispatches `sub-agent-code-reviewer` with desloppify review instructions.

```text
1. Run: uvx desloppify review --prepare
   → Creates .desloppify/query.json
   
2. Extract from query.json:
   - dimensions[] (canonical definitions)
   - language_guidance (language-specific hints)
   - files to review
   
3. Subagent performs holistic review:
   Phase 1: Structural overview (skim all files)
   Phase 2: Score each dimension with evidence
   
4. Subagent outputs findings.json

5. Run: uvx desloppify review --import findings.json

6. Return summary to main conversation
```

## Subagent Instructions

Use the prompt template at:
`desloppify/review-prompt.md`

Pass to subagent:

- REPO_PATH:
  Current repository path
- QUERY_JSON_PATH:
  Path to .desloppify/query.json

## PR-Aware Trigger

When user mentions working on a PR:

1. Check if branch scanned recently (commits since last_scan)
2. Check CI status if mentioned
3. If unscanned + CI green:
   suggest `/deslop`

Example:

```text
User: "CI is passing now, ready to merge"
Agent: "Branch hasn't had a quality scan since 3 commits ago.
        Run /deslop before merging? (y/n)"
```

## The 12 Subjective Dimensions

| Dimension | Weight | Focus |
|-----------|--------|-------|
| high_elegance | 22.0 | Architecture patterns |
| mid_elegance | 22.0 | Module/class design |
| low_elegance | 12.0 | Function craftsmanship |
| contracts | 12.0 | API clarity |
| type_safety | 12.0 | Type coverage |
| design_coherence | 10.0 | Decision consistency |
| abstraction_fit | 8.0 | Right abstraction level |
| logic_clarity | 6.0 | Readability |
| structure_nav | 5.0 | Navigability |
| error_consistency | 3.0 | Error handling |
| naming_quality | 2.0 | Naming conventions |
| ai_generated_debt | 1.0 | Vibe coding slop |

## Error Handling

| Error | Response |
|-------|----------|
| uvx not found | "uvx required. Install: pip install uv" |
| No .desloppify/state.json | First run - scan will create it |
| Scan fails | Show error, suggest manual debug |
| Import validation fails | Show desloppify error, check schema |

## Integration Points

- relates_to ::
  [[requesting-code-review]] - complementary quality checks
- relates_to ::
  [[finishing-a-development-branch]] - quality gate before merge
- relates_to ::
  [[verification-before-completion]] - evidence-based claims
