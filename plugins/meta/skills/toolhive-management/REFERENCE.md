# ToolHive Reference

## Complete Command Reference

### thv run Options

```bash
thv run [flags] SERVER_OR_IMAGE_OR_PROTOCOL [-- ARGS...]

# Common flags
--name <name>              # Custom server name
--transport <type>         # stdio, sse, or streamable-http
--proxy-port <port>        # Fixed proxy port (default: random)
--secret <name>,target=<ENV_VAR>  # Pass secret as env var
-e, --env <KEY=VALUE>      # Pass env var directly
-v, --volume <host:container[:ro]>  # Mount volume
--group <name>             # Run in specific group
--tools <tool1> --tools <tool2>  # Filter exposed tools
--tools-override <file.json>     # Override tool names/descriptions
--from-config <file>       # Run from exported config
--isolate-network          # Enable network isolation
--permission-profile <path>  # Custom permissions JSON

# Protocol-specific
--target-port <port>       # Container port to expose (SSE/HTTP)
--ca-cert <path>           # Custom CA cert for builds
```

### thv proxy Options

```bash
# stdio proxy for client integration
thv proxy stdio <workload-name>

# HTTP proxy to remote MCP
thv proxy <name> --target-uri <url> [flags]

# Common flags
--host <ip>                      # Proxy listen host (default: 127.0.0.1)
--port <port>                    # Proxy listen port
--remote-auth                    # Enable OAuth to remote server
--remote-auth-issuer <url>       # OIDC issuer URL
--remote-auth-client-id <id>     # OAuth client ID
--remote-auth-client-secret <secret>  # OAuth secret
--remote-forward-headers <Name=Value>  # Inject headers
```

## Registry Server Details

### Environment Variables by Server

**GitHub (`github`):**

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | Yes | GitHub PAT |
| `GITHUB_HOST` | No | GitHub Enterprise hostname |
| `GITHUB_TOOLSETS` | No | Comma-separated toolsets |
| `GITHUB_DYNAMIC_TOOLSETS` | No | Set to '1' for dynamic discovery |
| `GITHUB_READ_ONLY` | No | Set to '1' for read-only mode |

**Common Servers:**

| Server | Key Env Var | Notes |
|--------|-------------|-------|
| `fetch` | None | Fetches web content |
| `filesystem` | None | File system access (needs volumes) |
| `github` | `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub API |
| `gitlab` | `GITLAB_PERSONAL_ACCESS_TOKEN` | GitLab API |
| `slack` | `SLACK_BOT_TOKEN`, `SLACK_TEAM_ID` | Slack integration |

## Export Config Format

The exported JSON contains:

```json
{
  "schema_version": "v0.1.0",
  "image": "ghcr.io/github/github-mcp-server:v0.30.3",
  "name": "github",
  "transport": "stdio",
  "host": "127.0.0.1",
  "port": 17864,
  "permission_profile": {
    "network": {
      "outbound": {
        "allow_host": [".github.com", ".githubusercontent.com"],
        "allow_port": [443]
      }
    }
  },
  "env_vars": {
    "GITHUB_READ_ONLY": "1",
    "MCP_TRANSPORT": "stdio"
  },
  "secrets": [
    "github,target=GITHUB_PERSONAL_ACCESS_TOKEN"
  ],
  "proxy_mode": "streamable-http",
  "group": "default"
}
```

**Key fields to modify:**

- `env_vars` - Environment variables (remove/add as needed)
- `secrets` - Secret references (name,target=ENV_VAR format)
- `permission_profile` - Network and filesystem permissions

## Client Configuration

### Supported Clients

```bash
thv client register <client>

# Available clients:
claude-code      # Claude Code CLI
cursor           # Cursor IDE
roo-code         # Roo Code (VS Code extension)
cline            # Cline (VS Code extension)
vscode           # Visual Studio Code (GitHub Copilot)
vscode-insider   # VS Code Insiders
```

### Manual Client Config

For unsupported clients, get server URLs:

```bash
# Human readable
thv list

# JSON format (standard MCP config)
thv list --format mcpservers
```

## Network Considerations

### Container to Host Communication

When MCP servers need to reach services on your host:

| Platform | Host Address |
|----------|-------------|
| Docker Desktop (macOS/Windows) | `host.docker.internal` |
| Podman Desktop | `host.containers.internal` |
| Docker Engine (Linux) | `172.17.0.1` |

### Permission Profiles

Create custom network permissions:

```json
{
  "network": {
    "outbound": {
      "allow_host": ["api.example.com", ".github.com"],
      "allow_port": [443, 8080]
    }
  },
  "filesystem": {
    "read": ["/path/to/read"],
    "write": ["/path/to/write"]
  }
}
```

Use with:
`thv run --permission-profile perms.json --isolate-network server`

## Logs and Debugging

```bash
# View logs
thv logs github

# Follow logs
thv logs -f github

# Debug mode
thv --debug run github

# Log files location
ls ~/.local/share/toolhive/logs/
```
