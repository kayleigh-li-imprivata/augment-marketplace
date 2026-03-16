# Plugins

Production-tested Augment CLI plugins for autonomous development, code quality,
knowledge capture, and workflow automation.

## Installation

```bash
# Add this marketplace (from repo root)
auggie plugin marketplace add kayleigh-li-imprivata/augment-marketplace

# Browse available plugins
/plugins

# Install a specific plugin
auggie plugin install ralph-workflow@kayleigh-li-imprivata
```

## Available Plugins

| Plugin | Category | Description |
|--------|----------|-------------|
| [core](#core) | core | Foundation - response style, security, session hooks, MCP integrations |
| [meta](#meta) | tooling | Augment config management, ToolHive, skill authoring, ast-grep |
| [ralph-workflow](#ralph-workflow) | workflow | Autonomous specs-based development with subagents |
| [knowledge-capture](#knowledge-capture) | productivity | Basic Memory integration for persistent notes |
| [research](#research) | research | STORM methodology, deep dives, brainstorming, structured thinking |
| [git-workflow](#git-workflow) | workflow | Git conventions, MCP enforcement, commit policies |
| [tdd-workflow](#tdd-workflow) | testing | Test-driven development with systematic debugging |
| [code-quality](#code-quality) | code-quality | Linting (ast-grep/ruff/ty), code review, health scoring |
| [python-dev](#python-dev) | development | Python patterns, FastAPI, observability |
| [kubernetes-dev](#kubernetes-dev) | infrastructure | Helm charts, Argo Workflows, Kubernetes patterns |
| [observability](#observability) | infrastructure | Grafana and Prometheus MCP integrations |

## Plugin Details

### core

Foundation plugin that bootstraps everything else.
Install this first.

**Components:**

- Session start hook that loads available skills and agents
- `using-superpowers` skill that teaches AI to discover and invoke skills
- `dispatching-parallel-agents` skill for concurrent task execution
- Core rules for response style, security, and authorization
- MCP integrations (basic-memory, think-strategies, context7)

**Dependencies:** None (this is the foundation)

### meta

Tools for managing Augment CLI configuration itself.

**Components:**

- `augment-config-management` skill for modifying rules, hooks, and skills
- `toolhive-management` skill for managing MCP servers
- `writing-skills` skill for creating new skills
- `ast-grep` skill for writing structural code rules
- `showcase-generation` skill for generating annotated examples

**Dependencies:** core plugin

### ralph-workflow

Autonomous specs-based development workflow inspired by the "Ralph Wiggum"
philosophy:
"Don't assume not implemented."

**Components:**

- 7 skills (brainstorming, writing-plans, executing-plans,
  spec-driven-development, etc.)
- 6 subagents (ralph-explore, ralph-plan, ralph-implement, ralph-spec-review,
  ralph-quality-review, architect)
- `/ralph` command
- Circuit breaker hook for stuck detection

**Dependencies:** basic-memory MCP, git MCP, knowledge-capture plugin

### knowledge-capture

Persistent knowledge capture to Basic Memory for decisions, patterns, and
learnings that survive across sessions.

**Components:**

- 3 skills (knowledge-capture, knowledge-organize, people-notes-manager)
- `continue-conversation` skill for resuming prior work
- Session hooks for knowledge lifecycle
- `/note` and `/organize` commands

**Dependencies:** basic-memory MCP (included in core plugin)

### research

Research and investigation skills including STORM methodology, deep dives,
brainstorming, and structured thinking strategies.

**Components:**

- `storm` skill for multi-perspective research with expert synthesis
- `deep-dive` skill for intensive topic exploration
- `brainstorming` skill for collaborative ideation
- `structured-thinking` skill with 9 reasoning strategies
- `/storm`, `/dive`, `/brainstorm` commands

**Dependencies:** think-strategies MCP (included in core plugin), basic-memory
MCP

### git-workflow

Comprehensive git workflow enforcement including conventional commits, branch
naming, MCP-only git operations, and commit authorization policies.

**Components:**

- 2 skills (git-workflow, github-workflow)
- `using-git-worktrees` skill for isolated feature development
- 4 rules (git-workflow, git-mcp-required, github-mcp-required,
  authorization-policies)
- 4 hooks (commit policy, working dir check, session recovery, worktree guard)

**Dependencies:** git MCP

### tdd-workflow

Test-driven development patterns with systematic debugging techniques.

**Components:**

- `test-driven-development` skill
- `systematic-debugging` skill
- `verification-before-completion` skill

**Dependencies:** code-quality plugin, pytest

### code-quality

Automatic linting and code review patterns with health scoring.

**Components:**

- `lint-workflow` skill and auto_lint hook
- `desloppify` skill for health scoring
- `requesting-code-review` and `receiving-code-review` skills
- `code-reviewer` and `refactor` agents
- `/deslop` command

**Dependencies:** ast-grep, ruff, ty CLI tools

### python-dev

Python development patterns for modern Python with FastAPI, observability, and
API design best practices.

**Components:**

- 4 skills (python-development, fastapi, api-design, observability)
- python-development rule

**Dependencies:** uv or poetry

### kubernetes-dev

Kubernetes development including Helm chart authoring (with critical namespace
rules) and Argo Workflows via Hera SDK.

**Components:**

- 3 skills (helm-kubernetes, argo-workflows-hera, eam-integration)
- helm-kubernetes-guidelines rule

**Dependencies:** helm, kubectl

### observability

Observability patterns with Grafana and Prometheus MCP integrations.

**Components:**

- `observability` skill for metrics, traces, and dashboards
- Grafana MCP integration for dashboard queries
- Prometheus MCP integration for metrics queries

**Dependencies:** Grafana and Prometheus MCP servers

## Claude Code Compatibility

These plugins use the `.augment-plugin` format which is backwards compatible
with Claude Code's `.claude-plugin` format.

## License

MIT
