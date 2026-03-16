# Kayleigh's Augment CLI Marketplace

This is my personal Augment CLI marketplace with custom agents and configurations.
Based on Matt Niedelman's showcase, customized for my workflow.

## Install My Plugins

This repo is an Augment CLI marketplace.
Install plugins directly:

```bash
# Add this marketplace (one-time)
auggie plugin marketplace add kayleigh-li-imprivata/augment-marketplace

# Install plugins you want
auggie plugin install core@kayleigh-li-imprivata              # Foundation (install first)
auggie plugin install ralph-workflow@kayleigh-li-imprivata    # Autonomous development
auggie plugin install knowledge-capture@kayleigh-li-imprivata # Basic Memory integration

# Browse all available plugins interactively
/plugins
```

| Plugin | Category | Description |
|--------|----------|-------------|
| `core` | core | Foundation - response style, security, session hooks, MCP integrations |
| `meta` | tooling | Augment config management, ToolHive, skill authoring, ast-grep |
| `ralph-workflow` | workflow | Autonomous specs-based development with subagents |
| `knowledge-capture` | productivity | Basic Memory integration for persistent notes |
| `research` | research | STORM methodology, deep dives, brainstorming, structured thinking |
| `git-workflow` | workflow | Git conventions, MCP enforcement, commit policies |
| `tdd-workflow` | testing | Test-driven development with systematic debugging |
| `code-quality` | code-quality | Linting (ast-grep/ruff/ty), code review, health scoring |
| `python-dev` | development | Python patterns, FastAPI, observability |
| `kubernetes-dev` | infrastructure | Helm charts, Argo Workflows, Kubernetes patterns |
| `observability` | infrastructure | Grafana and Prometheus MCP integrations |

See [plugins/](plugins/) for full details on each plugin.

## Customizing Plugins

Plugins can be configured via environment variables or full overrides:

**Environment variables (recommended):**

```bash
# In shell profile (~/.bashrc, ~/.config/fish/config.fish)
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxxx"
export GRAFANA_URL="https://grafana.example.com"
```

**Full override in settings.json:**

Copy the MCP server definition from the plugin's `.mcp.json` to your
`~/.augment/settings.json`.
User settings take precedence over plugin configs.

```json
{
  "mcpServers": {
    "grafana": {
      "command": "npx",
      "args": [
        "-y",
        "@grafana/mcp-grafana"
      ],
      "env": {
        "GRAFANA_URL": "https://your-grafana-instance.com",
        "GRAFANA_API_KEY": "${GRAFANA_API_KEY}"
      }
    }
  }
}
```

## My Setup

I use the Augment CLI (`auggie`) with a layered configuration system:

- **Rules** - Non-negotiable constraints (no nested functions, no mocks, git
  commit authorization, semantic tools for code search, etc.)
- **Skills** - On-demand guidance for specific situations
  (test-driven-development, systematic-debugging, spec-driven-development,
  knowledge-capture, etc.)
- **Agents** - Subagent definitions for autonomous loops (explore, plan,
  code-reviewer, test-gen, validation, etc.)
- **Hooks** - Event-driven automation (auto_lint.sh runs ruff/ast-grep/others on
  save, ascii_fixer.sh normalizes unicode characters, etc.)

Everything is backed by Basic Memory - a knowledge graph that stores decisions,
specs, and context as markdown files with wiki-link relations.
This gives the AI persistent memory across sessions.

## Navigation

| Depth | Time | Content |
| ------- | ------ | --------- |
| [This README](#my-setup) | 5 min | Overview |
| [Philosophy](docs/philosophy.md) | 15 min | Design principles and patterns |
| [Architecture](docs/architecture.md) | 15 min | Layered configuration explained |
| [Case Studies](case-studies/) | 30 min each | Real-world examples with annotations |
| [Reference](reference/) | As needed | Annotated config examples |

## Case Studies

Real multi-session arcs from my work, showing how AI assistance evolves across
conversations.

| Case Study | Sessions | Exchanges | Pattern |
|------------|----------|-----------|---------|
| [Data Fabric Architecture](case-studies/data-fabric-architecture/) | 6 | 1573 | Brainstorm, Explore, ADR, Refine |
| [Ralph Command Development](case-studies/ralph-command-development/) | 12 | 1293 | Iterative workflow development |
| [GitHub Actions Release](case-studies/github-actions-release-workflow/) | 2 | 426 | Plan, Create, Refine |
| [Workstation Clustering Logging](case-studies/workstation-clustering-logging/) | 1 | 343 | Ralph workflow iteration |
| [Ingress ADR](case-studies/ingress-adr/) | 2 | 146 | ADR creation and refinement |
| [API Versioning ADR](case-studies/api-versioning-adr/) | 3 | 127 | Plan, Create, Refine |

Each case study includes the main narrative, arc metadata, and individual
session summaries with actual quotes from the conversations.

## Raw Configurations

The complete, unedited dotfiles are available at
[github.com/mattniedelman/dotfiles](https://github.com/mattniedelman/dotfiles)
(included as a submodule in this repo).

This showcase contains curated, heavily annotated excerpts in
[reference/](reference/) - not a mirror of the raw configs.

## Getting Started

See [docs/getting-started.md](docs/getting-started.md) for how to adapt these
patterns for your own workflow.
