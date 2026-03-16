---
description: Assess code quality using desloppify (scan, status, review)
argument-hint: [review]
allowed-tools: launch-process, view, codebase-retrieval, sub-agent-code-reviewer, save-file, git_log_git, git_status_git
---

# Deslop

Assess codebase quality using desloppify's mechanical scan and subjective
review.

## IMPORTANT: Use the Desloppify Skill

**Read and follow the skill at:** `~/.augment/skills/desloppify/SKILL.md`

This command invokes the desloppify skill.
The skill contains the full process.

## Quick Reference

| Command | Action |
|---------|--------|
| `/deslop` | Scan + status + suggest review if warranted |
| `/deslop review` | Force full subjective review (dispatches subagent) |

## Your Task

When the user runs `/deslop`:

1. **Read the skill file:** `view ~/.augment/skills/desloppify/SKILL.md`
1. **Check scan recency:** Read `.desloppify/state.json`, compare to `git log
   --format=%cI -1`
1. **Run scan if needed:** `uvx desloppify scan --path .`
1. **Display status** and suggest review if dimensions stale or T3/T4 findings
   open

## When Running Review Mode

1. **Prepare review packet:** `uvx desloppify review --prepare`
1. **Dispatch subagent** with `~/.augment/skills/desloppify/review-prompt.md`
1. **Import findings:** `uvx desloppify review --import findings.json`
1. **Report summary**

## Examples

```text
/deslop
→ Runs scan, shows current score, suggests review if dimensions are stale

/deslop review
→ Dispatches subagent for full holistic review across all 12 dimensions
```

## Error Handling

| Error | Response |
|-------|----------|
| uvx not found | "uvx required. Install: pip install uv" |
| No Python files | Skip scan, inform user |
| No .desloppify dir | First run - scan will create it |

## See Also

- `/brainstorm` - Design before implementing
- `superpowers:verification-before-completion` - Verify work before claiming
  done
- `superpowers:requesting-code-review` - Human code review
