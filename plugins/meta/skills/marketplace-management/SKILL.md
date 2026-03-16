# Marketplace Management

Manage the Augment Plugin Marketplace - create, update, and sync plugins from
personal `~/.augment/` configuration.

## Trigger

- "create a plugin", "add to marketplace", "sync plugins"
- "update plugin X", "refresh marketplace"
- "what's not in plugins", "check for missing items"

## Context

- **Marketplace root**:
  Current workspace with `plugins/` directory
- **Source config**:
  `~/.augment/` (skills, rules, hooks, commands, agents)
- **Manifest**:
  `.augment-plugin/marketplace.json`

## Plugin Structure

```text
plugins/{name}/
├── .augment-plugin/
│   └── plugin.json          # Required: name, description, version, author
├── .mcp.json                 # Optional: MCP server configs
├── skills/
│   └── {skill-name}/
│       └── SKILL.md
├── rules/
│   └── {rule}.md
├── hooks/
│   ├── hooks.json            # Required if hooks exist
│   ├── augment_adapter.py    # Required if hooks import it
│   └── {hook}.sh
├── commands/
│   └── {command}.md
└── agents/
    └── {agent}.md
```

## Operations

### 1. Create New Plugin

```bash
# Create structure
mkdir -p plugins/{name}/.augment-plugin plugins/{name}/skills

# Copy items from ~/.augment/
cp -r ~/.augment/skills/{skill} plugins/{name}/skills/
cp ~/.augment/rules/{rule}.md plugins/{name}/rules/
cp ~/.augment/hooks/{hook}.sh plugins/{name}/hooks/
cp ~/.augment/commands/{cmd}.md plugins/{name}/commands/
cp ~/.augment/agents/{agent}.md plugins/{name}/agents/
```

**plugin.json template:**

```json
{
  "name": "{name}",
  "description": "{description}",
  "version": "1.0.0",
  "author": {
    "name": "Matt Niedelman"
  },
  "keywords": [
    "{keyword1}",
    "{keyword2}"
  ]
}
```

**With attribution (for superpowers-derived content):**

```json
{
  "attribution": {
    "basedOn": "obra/superpowers",
    "url": "https://github.com/obra/superpowers",
    "license": "MIT",
    "skills": [
      "{skill1}",
      "{skill2}"
    ],
    "modifications": "{description of changes}"
  }
}
```

### 2. Add MCP Servers

**.mcp.json template:**

```json
{
  "mcpServers": {
    "{name}": {
      "command": "uvx",
      "args": [
        "{package}",
        "mcp"
      ],
      "env": {
        "REQUIRED_VAR": "${REQUIRED_VAR}",
        "OPTIONAL_VAR": "${OPTIONAL_VAR:-default-value}"
      }
    }
  },
  "config": {
    "REQUIRED_VAR": {
      "type": "secret",
      "required": true,
      "description": "What this value is for",
      "setup": "How to obtain this value"
    },
    "OPTIONAL_VAR": {
      "type": "string",
      "required": false,
      "description": "Optional customization",
      "default": "default-value"
    }
  }
}
```

**Config schema fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | `secret` \| `string` \| `url` \| `path` | How the value should be treated |
| `required` | boolean | Plugin fails without this value |
| `description` | string | What this config is for |
| `setup` | string | How to obtain/configure this value |
| `default` | string | Default value (never for secrets) |

**Common MCP servers:**

| Server | Command | Config Required |
|--------|---------|-----------------|
| basic-memory | `uvx basic-memory mcp` | None |
| ast-grep | `uvx --from git+https://github.com/ast-grep/ast-grep-mcp ast-grep-server` | None |
| context7 | `npx -y @upstash/context7-mcp` | None |
| think-strategies | `npx -y @thisnick/think-strategies-mcp` | None |
| git | `npx -y @cyanheads/git-mcp-server` | None |
| github | `npx -y @github/mcp-server` | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| grafana | `npx -y @grafana/mcp-grafana` | `GRAFANA_URL`, `GRAFANA_API_KEY` |
| prometheus | `uvx prometheus-mcp-server` | `PROMETHEUS_URL` (+ proxy for AWS) |

### User Configuration and Overrides

Users can configure plugins via:

1. **Environment variables** - Set values referenced in `.mcp.json` env blocks
2. **Full override in settings.json** - Copy server definition and modify

**Environment variable approach (recommended):**

```bash
# In shell profile (~/.bashrc, ~/.config/fish/config.fish)
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxxx"
export GRAFANA_URL="https://grafana.example.com"
```

**Full override approach (for advanced customization):**

Copy the MCP server definition from the plugin's `.mcp.json` to the user's
`~/.augment/settings.json`.
User settings take precedence over plugin configs.

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@github/mcp-server",
        "--custom-flag"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Document in plugin README:**

- Required config (secrets, URLs)
- Optional config with defaults
- Any external dependencies (proxies, CLI tools)

### 3. Add Hooks

**hooks.json template:**

```json
{
  "hooks": {
    "{Event}": [
      {
        "matcher": "{tool-regex}",
        "hooks": [
          {
            "type": "command",
            "command": "${AUGMENT_PLUGIN_ROOT}/hooks/{hook}.sh"
          }
        ]
      }
    ]
  }
}
```

**Events:** `PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`

### Making Hooks Portable

Hooks from `~/.augment/hooks/` often have hardcoded paths.
Two fixes required:

**1.
Remove hardcoded --directory from shebangs:**

```bash
sed -i 's|--directory [^ ]*||g' plugins/{name}/hooks/*.sh
```

**2.
Add self-locating imports (if hooks import augment_adapter):**

First, copy augment_adapter.py:

```bash
cp plugins/core/hooks/augment_adapter.py plugins/{name}/hooks/
```

Then add this block before the `from augment_adapter import` line in each hook:

```python
# Self-locate for portable imports
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
```

**Why self-locating?** Shell variables like `$HOME` don't expand in shebangs
(kernel processes them directly).
The sys.path pattern is a standard Python idiom that makes each plugin fully
self-contained.

**Automated fix for multiple hooks:**

```bash
for hook in plugins/{name}/hooks/*.sh; do
  if grep -q "from augment_adapter" "$hook"; then
    sed -i '/^from augment_adapter/i\
# Self-locate for portable imports\
import sys\
from pathlib import Path\
sys.path.insert(0, str(Path(__file__).parent))\
' "$hook"
  fi
done
```

### 4. Update Marketplace Manifest

Add to `.augment-plugin/marketplace.json`:

```json
{
  "name": "{name}",
  "description": "{description}",
  "version": "1.0.0",
  "source": "./plugins/{name}",
  "category": "{category}",
  "tags": [
    "{tag1}",
    "{tag2}"
  ]
}
```

**Categories:** `core`, `workflow`, `code-quality`, `productivity`,
`development`, `infrastructure`, `research`, `tooling`, `testing`

## Validation Commands

```bash
# Check what's not in plugins
for item in ~/.augment/{skills,rules,hooks,commands,agents}/*; do
  name=$(basename "$item")
  if ! find plugins -name "$name" | grep -q .; then
    echo "Missing: $item"
  fi
done

# Validate all plugins have plugin.json
for p in plugins/*/; do
  [ -f "$p/.augment-plugin/plugin.json" ] || echo "Missing: $p"
done

# Validate hooks have hooks.json
for p in plugins/*/hooks; do
  [ -d "$p" ] && [ ! -f "$p/hooks.json" ] && echo "Missing hooks.json: $p"
done

# Check for hardcoded paths
grep -r "/home/" plugins/*/hooks/*.sh

# Validate marketplace matches disk
python3 -c "
import json
from pathlib import Path
mp = json.load(open('.augment-plugin/marketplace.json'))
disk = {p.name for p in Path('plugins').iterdir() if p.is_dir()}
manifest = {p['name'] for p in mp['plugins']}
print('On disk only:', disk - manifest)
print('In manifest only:', manifest - disk)
"
```

## Review Checklist

Before committing:

- [ ] All plugins have `plugin.json`
- [ ] All hooks have `hooks.json`
- [ ] hooks.json uses `${AUGMENT_PLUGIN_ROOT}`
- [ ] No hardcoded paths in shebangs (grep for `/home/`)
- [ ] Hooks with augment_adapter have self-locating imports
- [ ] augment_adapter.py copied to plugins that need it
- [ ] Marketplace matches disk
- [ ] Attribution for derived content
- [ ] Personal POV references use "the user's" not specific names

## Content Guidelines

When writing skills, commands, or documentation:

- Use "the user's POV" not a specific person's name
- Mark personal repo paths as examples with a note
- Keep author attribution in plugin.json (that's appropriate)
- Personal workflow references in frontmatter descriptions are fine
