---
name: toolhive-management
description: Use when managing MCP servers via ToolHive (thv) - running servers, secrets management, Augment integration, and troubleshooting
---

# ToolHive Management

ToolHive (`thv`) is an MCP server manager that runs servers in isolated
containers with secrets management and client auto-configuration.

**Note**:
If `thv` is not found, ensure `~/.toolhive/bin` is in your PATH.

## Quick Reference

### Server Lifecycle

| Task | Command |
|------|---------|
| Run from registry | `thv run github` |
| Run with secret | `thv run --secret github,target=GITHUB_PERSONAL_ACCESS_TOKEN github` |
| List running | `thv list` |
| View status | `thv status <server>` |
| View logs | `thv logs <server>` |
| Stop server | `thv stop <server>` |
| Remove server | `thv rm <server>` |
| Export config | `thv export <server> /tmp/config.json` |
| Run from config | `thv run --from-config /tmp/config.json` |

### Running Servers

**From Registry (Pre-configured):**

```bash
thv run github
thv run fetch
thv run filesystem
```

**With Environment Variables:**

```bash
# Via secrets (preferred for sensitive data)
thv run --secret github,target=GITHUB_PERSONAL_ACCESS_TOKEN github

# Direct env vars
thv run -e SOME_VAR=value server-name
```

**From Docker Image:**

```bash
thv run ghcr.io/org/mcp-server:tag
thv run --name my-server --transport stdio image:tag -- --arg1 value
```

**From Package Managers:**

```bash
thv run uvx://package@latest     # Python (uv)
thv run npx://package@latest     # Node.js (npm)
thv run go://module/path@latest  # Go
```

### Secrets Management

```bash
thv secret setup                   # Configure provider (encrypted/1password)
thv secret set github              # Create secret (prompts for value)
thv secret list                    # List secrets
thv secret get github              # View secret value
thv secret delete github           # Remove secret

# Pipe value to secret
gh auth token | thv secret set github
```

### Registry Operations

```bash
thv search <term>                  # Search for MCP servers
thv registry list                  # List all available servers
thv registry info <server>         # View server details (env vars, tools, etc.)
thv registry info github --format json | jq '.env_vars'  # JSON output
```

## Augment Integration

Augment uses `thv proxy stdio <workload>` to connect to ToolHive-managed
servers.

**settings.json configuration:**

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "thv proxy stdio github",
      "args": []
    }
  }
}
```

### Modifying Running Server Config

To change environment variables on a running server:

```bash
# 1. Export current config
thv export github /tmp/github-config.json

# 2. Edit the config (modify env_vars section)
# 3. Remove and restart
thv rm github
thv run --from-config /tmp/github-config.json

# OR restart fresh from registry (resets to defaults)
thv rm github
thv run github
```

## Common Patterns

### GitHub Server Setup

```bash
# Set secret
thv secret set github
# (paste your GitHub PAT when prompted)

# Run with read-write access (no GITHUB_READ_ONLY)
thv run --secret github,target=GITHUB_PERSONAL_ACCESS_TOKEN github

# Run in read-only mode
thv run --secret github,target=GITHUB_PERSONAL_ACCESS_TOKEN -e GITHUB_READ_ONLY=1 github
```

### Viewing Server Tools

```bash
thv registry info github | grep -A 50 "Tools:"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `command not found: thv` | Use `fish -c "thv ..."` |
| Server won't start | Check `thv logs <server>`, verify Docker running |
| Secret not available | Verify with `thv secret get <name>` |
| Wrong env vars | Export config, check `env_vars`, restart from config |
| Port conflict | Use `--proxy-port <port>` for fixed port |

## Key Paths

| Location | Purpose |
|----------|---------|
| `~/.local/share/toolhive/logs/` | Server log files |
| `~/.config/toolhive/secrets_encrypted` | Encrypted secrets store |
