---
description: Update showcase repository reference files from dotfiles submodule changes
argument-hint: [status] [sync] [sessions] [full]
allowed-tools: view, codebase-retrieval, save-file, str-replace-editor, git_status_git, git_log_git, git_diff_git, git_set_working_dir_git, git_branch_git, git_checkout_git, git_fetch_git, git_add_git, git_commit_git, launch-process, search_notes_basic-memory, write_note_basic-memory, build_context_basic-memory, recent_activity_basic-memory
---

# Showcase Update

Detect and synchronize changes from the dotfiles submodule to the showcase
repository reference section.
Also process undocumented sessions and recommend case study candidates.

## IMPORTANT: Use These Skills

- **Submodule sync:** `~/.augment/skills/showcase-generation/SKILL.md`
- **Session processing:** `~/.augment/skills/auglog-documenter/SKILL.md`

## Arguments (can be combined)

| Argument | Description |
|----------|-------------|
| `status` | Show submodule changes AND undocumented sessions |
| `sync` | Create branch, update submodule, generate/update reference files |
| `sessions` | Process undocumented sessions and recommend case studies |
| `full` | Regenerate all reference files (full sync) |

**Combinations:**

- `/showcase` (no args) - same as `status`
- `/showcase sync` - full workflow:
  branch, submodule update, sync references
- `/showcase sync sessions` - sync references AND process sessions
- `/showcase full sessions` - full regenerate AND process all sessions

## Repository Structure

> **Note:** Paths below are examples - customize for your own showcase repo.

```text
~/git/imprivata/matt-niedelman-imprivata/
├── dotfiles/                    # Git submodule → github.com/mattniedelman/dotfiles
│   └── dot_augment/
│       ├── agents/              # Raw agent definitions
│       ├── commands/            # Raw command definitions
│       ├── hooks/               # Raw hook scripts
│       ├── rules/               # Raw rule files
│       └── skills/              # Raw skill folders
└── reference/                   # Annotated versions for the showcase
    ├── agents/*-annotated.md
    ├── commands/*-annotated.md
    ├── hooks/*-annotated.md
    ├── rules/*-annotated.md
    └── skills/*-annotated.md
```

## Mapping Rules

| Submodule Path | Reference Path | Naming |
|----------------|----------------|--------|
| `dot_augment/agents/*.md` | `reference/agents/` | `{name}-annotated.md` |
| `dot_augment/commands/*.md` | `reference/commands/` | `{name}-annotated.md` |
| `dot_augment/hooks/executable_*.sh` | `reference/hooks/` | `{name}-annotated.md` |
| `dot_augment/rules/*.md` | `reference/rules/` | `{name}-annotated.md` |
| `dot_augment/skills/*/SKILL.md` | `reference/skills/` | `{name}-annotated.md` |

## Your Task

### `/showcase status`

1. **Set git working directory:**

   ```python
   git_set_working_dir_git(path="~/git/imprivata/matt-niedelman-imprivata")
   ```

2. **Check submodule for upstream updates:**

   ```python
   # Set working dir to submodule, fetch, and check for updates
   git_set_working_dir_git(path="~/git/imprivata/matt-niedelman-imprivata/dotfiles")
   git_fetch_git(remote="origin")
   git_log_git(sha="origin/dev", maxCount=10)  # See commits ahead of current

   # Switch back to main repo
   git_set_working_dir_git(path="~/git/imprivata/matt-niedelman-imprivata")
   ```

3. **Compare submodule vs reference:**
   - List all files in
     `dotfiles/dot_augment/{agents,commands,hooks,rules,skills}`
   - List all files in `reference/{agents,commands,hooks,rules,skills}`
   - Report:
     new (in submodule, not in reference), modified, deleted

4. **Check for undocumented sessions:**

   ```bash
   auglog list --since 30 --json
   ```

   Compare against Basic Memory session notes to find gaps.

5. **Present status report** showing:
   - Submodule commit and changes detected (new, modified, deleted)
   - Files up to date
   - Undocumented session count and top case study candidates

### `/showcase sync`

**This is the main workflow command.
It handles everything:**

1. **Check current branch:**

   ```python
   git_set_working_dir_git(path="~/git/imprivata/matt-niedelman-imprivata")
   git_branch_git(operation="show-current")
   ```

   - If on `main` or `dev`, create a new branch:

     ```python
     git_checkout_git(target="showcase-update-YYYY-MM-DD", createBranch=true)
     ```

   - If already on a `showcase-update-*` branch, continue on it

2. **Update dotfiles submodule to latest:**

   ```python
   # Switch to submodule directory
   git_set_working_dir_git(path="~/git/imprivata/matt-niedelman-imprivata/dotfiles")
   git_fetch_git(remote="origin")
   git_checkout_git(target="origin/dev")

   # Switch back to main repo
   git_set_working_dir_git(path="~/git/imprivata/matt-niedelman-imprivata")
   ```

3. **Show what changed in submodule:**

   ```python
   git_diff_git(paths=["dotfiles"])
   ```

4. **Run status check** to identify new/modified/deleted files

5. **For each change:**
   - **New:** Generate annotated file using showcase-generation skill
   - **Modified:** Read both versions, update annotation preserving insights
   - **Deleted:** Confirm removal of orphaned annotation

6. **Stage and commit changes:**
   - Stage the updated submodule pointer and any reference file changes
   - Ask user for commit message confirmation
   - Commit with message like:
     `docs:
     update showcase references from dotfiles`

7. **Update README index** if new categories added

**For new files, generate using this template:**

```markdown
# Annotated {Type}: {name}

**Source:** [{filename}](https://github.com/mattniedelman/dotfiles/blob/dev/{path})

{Brief description of purpose from the user's POV - "I use this to..."}

## When I Invoke This {Type}

- {Use case 1}
- {Use case 2}

---

## Key Behaviors

### {Behavior 1}

{Explanation of what this does and why}

### {Behavior 2}

{Explanation}

---

## {Type-specific sections}

{Model selection for agents, trigger patterns for hooks, etc.}

## Related {Types}

| {Type} | Relationship |
| --- | --- |
| `name` | {how they interact} |
```

### `/showcase full`

**Full regeneration - use sparingly.**

1. **Warning:** This regenerates ALL reference files
2. **Confirm with user before proceeding**
3. **Create branch and update submodule** (same as `sync` steps 1-2)
4. **For each source file in submodule:**
   - Generate fresh annotation using showcase-generation skill
   - Preserve any `<!-- TODO:
     Interactive enrichment needed -->` markers
5. **Stage and commit all changes**
6. **Update all README.md index files**

### `/showcase sessions`

Process undocumented sessions and recommend case study candidates.

1. **Find last documented session:**

   ```python
   # Search Basic Memory for most recent session note
   recent_activity_basic-memory(timeframe="30d", type="session")
   ```

2. **List sessions since last documentation:**

   ```bash
   # Get sessions newer than last documented
   auglog list --since 30 --json
   ```

3. **Filter for undocumented sessions:**
   - Compare auglog session IDs against Basic Memory `session_id:` metadata
   - Sessions in auglog but not in Basic Memory are undocumented

4. **Score sessions for case study potential:**

   | Criteria | Points | Description |
   |----------|--------|-------------|
   | Exchange count > 20 | +2 | Substantial interaction |
   | Exchange count > 50 | +3 | Deep collaboration |
   | Multiple repos | +1 | Cross-project work |
   | Uses skills/commands | +2 | Demonstrates configuration value |
   | Multi-session arc | +3 | Shows workflow continuity |
   | Contains pivots | +2 | Course corrections are interesting |
   | Produces artifacts | +2 | Specs, plans, or code created |

5. **Present recommendations:**

   ```text
   ## Session Status

   **Last documented:** 2025-02-20 (session abc123)
   **Undocumented sessions:** 12

   ### Recommended Case Studies (score >= 5)

   1. **def456** (score: 8) - "Debugging helm chart namespace issue"
      - 45 exchanges, 2 repos, produced ADR
      - Arc: investigation → fix → document

   2. **ghi789** (score: 6) - "Implementing rate limiting"
      - 67 exchanges, uses /ralph command
      - Arc: spec → implement → review

   ### Other Undocumented Sessions

   - **jkl012** (score: 3) - "Quick typo fix" - 5 exchanges
   - **mno345** (score: 2) - "Update dependencies" - 8 exchanges

   Document recommended sessions? (all/pick/skip)
   ```

6. **On approval, use auglog-documenter skill** to create case studies

7. **Check for multi-session arcs:**
   - Group sessions by date and topic
   - Look for continuation signals ("continuing from", "as discussed")
   - Recommend arc documentation for related sessions

## Quality Checklist

Before completing any annotation:

- [ ] Perspective is from the user's POV (not the AI's)
- [ ] "I" refers to Matt, "the AI/agent" refers to the assistant
- [ ] Prose is matter-of-fact (no "amazing", "inspiring", etc.)
- [ ] Source link points to correct GitHub URL
- [ ] Related items table is populated
- [ ] Line count is appropriate (full:
  100-200, summary:
  30-60)

## Examples

```text
/showcase
→ Status only: shows submodule changes and undocumented sessions

/showcase sync
→ Full workflow: create branch, update submodule, sync references, commit

/showcase sessions
→ Lists undocumented sessions, scores them, recommends case studies

/showcase sync sessions
→ Full sync workflow AND process undocumented sessions (recommended)

/showcase full
→ Regenerate ALL reference files (use sparingly)
```

## See Also

- `superpowers:showcase-generation` - Full annotation guidelines and templates
- `superpowers:auglog-documenter` - Session documentation workflow
- `specs/showcase-repository.md` - Repository specification
