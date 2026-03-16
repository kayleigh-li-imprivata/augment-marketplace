---
name: augment-config-management
description: Use when reviewing, updating, or auditing Augment CLI configuration including rules, hooks, skills, settings.json, or understanding cross-dependencies between config components and external tools like ast-grep, ruff, or linters
---

# Augment Config Management

Guide for managing the Augment CLI configuration workspace (`~/.augment`).

## CLI Command Name

**IMPORTANT:** The Augment CLI command is `auggie`, NOT `augment`.

- ✅ Correct:
  `auggie`, `auggie --help`, `auggie chat`
- ❌ Incorrect:
  `augment`, `augment --help`

## When to Use

Use this skill when:

- User asks to review their Augment configuration
- User wants to update or add rules/hooks/skills
- User needs to understand how components interact
- User asks about external dependencies (ast-grep, linters, etc.)
- User wants to audit configuration for completeness
- User mentions hooks, rules, skills, or settings.json

## Configuration Structure

```text
~/.augment/
├── settings.json         # Main config: permissions, hooks, MCP servers
├── rules/               # Agent behavior rules (priority-based)
│   └── README.md        # Rule index with priority matrix
├── hooks/               # Shell scripts for lifecycle events
│   └── augment_adapter.py  # Cross-compatibility with Claude Code
└── skills/              # Agent skills (SKILL.md + supporting files)
```

## External Dependencies

Track these external configs referenced by Augment components:

| Component | External Dependency | Path |
|-----------|---------------------|------|
| `auto_lint.sh` | ast-grep config | `~/.config/ast-grep/sgconfig.yml` |
| `auto_lint.sh` | ruff config | `~/.config/ruff/ruff.toml` |
| Various rules | team linter configs | `~/git/imprivata/ai/.github/linters/configs` |

## Key Capabilities

### 1. Audit Configuration

Review all components for consistency:

```python
# List all rules
list_directory("~/.augment/rules/")

# List all skills
list_directory("~/.augment/skills/")

# Review hooks
list_directory("~/.augment/hooks/")

# Read settings
view("~/.augment/settings.json")
```

**Audit checklist:**

- [ ] All rules have proper frontmatter (type, priority, description,
  last_updated)
- [ ] Skills have frontmatter (name, description starting with "Use when...")
- [ ] Hooks are executable and have correct shebang
- [ ] settings.json hook paths exist and are correct
- [ ] External dependencies exist

### 2. Update Components

**Rules frontmatter schema:**

```yaml
---
type: always_apply | agent_requested
priority: CRITICAL | HIGH | STANDARD
description: Brief description
last_updated: YYYY-MM-DD
---
```

**Skills frontmatter schema:**

```yaml
---
name: skill-name  # letters, numbers, hyphens only
description: Use when... (max 1024 chars)
---
```

### 3. Validate Cross-References

Check that:

- Rules reference valid files in authorization matrix
- Hooks use correct matchers in settings.json
- Skills reference valid templates or supporting files
- MCP server commands and args are correct

### 4. Identify Hook Dependencies

Hooks have specific event types and capabilities:

| Event | When | Can Inject Context | Can Block |
|-------|------|-------------------|-----------|
| SessionStart | Conversation begins | Yes | No |
| Stop | Agent finishes | Yes | Yes (exit 2) |
| PreToolUse | Before tool execution | Yes | Yes (exit 2) |
| PostToolUse | After tool execution | Yes | No |

## Documentation Reference

**ALWAYS fetch documentation before modifying components:**

| Task | Documentation URL |
|------|-------------------|
| Creating/modifying hooks | <https://docs.augmentcode.com/cli/hooks.md> |
| Creating/modifying rules | <https://docs.augmentcode.com/cli/rules.md> |
| Creating/modifying skills | <https://docs.augmentcode.com/cli/skills.md> |
| Configuring MCP servers | <https://docs.augmentcode.com/cli/integrations.md> |
| Full docs index | <https://docs.augmentcode.com/llms.txt> |

## Common Audit Issues

### Rules Issues

- Missing frontmatter fields
- Inconsistent priority levels
- Outdated `last_updated` dates
- Conflicting rules without resolution guidance

### Hook Issues

- Hook file not executable
- Path in settings.json doesn't match actual file
- Missing augment_adapter.py integration for cross-tool compatibility
- External tool dependencies not installed

### Skill Issues

- Description doesn't start with "Use when..."
- Name contains invalid characters
- Missing SKILL.md in directory
- Supporting files referenced but missing

## Workflow: Full Configuration Audit

1. **List all components**:
   `rules/`, `hooks/`, `skills/`, `settings.json`
2. **Validate frontmatter** for rules and skills
3. **Check hook registration** in settings.json matches files in hooks/
4. **Verify external dependencies** exist at expected paths
5. **Check MCP server configs** - commands exist and args valid
6. **Review rules/README.md** - priorities match individual files
7. **Document findings** in basic-memory for tracking

## Basic Memory Integration

Track configuration decisions and changes:

```python
# Record audit findings
mcp__basic_memory__write_note(
    title="Augment Config Audit 2024-01",
    folder="augment-config",
    content="Audit results and recommendations..."
)

# Check previous decisions
mcp__basic_memory__search_notes(
    query="augment configuration"
)
```
