#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0", "pyyaml>=6.0"]
# ///
"""
SessionStart hook: Inject project context and remind to check basic-memory.

Works with both Augment CLI and Claude Code via the unified adapter.
"""

from __future__ import annotations

import re

import yaml

# Self-locate for portable imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from augment_adapter import create_unified_context
from cchooks import SessionStartContext

AGENTS_DIR = Path.home() / ".augment" / "agents"
MARKETPLACE_DIR = Path.home() / ".augment" / "plugins" / "marketplaces" / "kayleigh-li-imprivata"
MEMORY_PROJECTS_DIR = MARKETPLACE_DIR / "memory" / "projects"
AUGMENT_MEMORY_DIR = Path.home() / ".augment" / "memory"


def setup_memory_symlinks() -> None:
    """Create symlinks from ~/.augment/memory/{project}/ to marketplace memory projects.

    Ensures project-specific memory is recoverable from the marketplace repo on new machines.
    Idempotent — safe to call on every session start.
    """
    if not MEMORY_PROJECTS_DIR.exists():
        return

    AUGMENT_MEMORY_DIR.mkdir(parents=True, exist_ok=True)

    for project_dir in MEMORY_PROJECTS_DIR.iterdir():
        if not project_dir.is_dir():
            continue
        link = AUGMENT_MEMORY_DIR / project_dir.name
        if link.is_symlink() and link.resolve() == project_dir.resolve():
            continue  # Already correct
        if link.exists() or link.is_symlink():
            link.unlink()
        link.symlink_to(project_dir)


def discover_agents() -> list[dict[str, str]]:
    """Scan agents directory and extract name/description from frontmatter."""
    agents = []
    if not AGENTS_DIR.exists():
        return agents

    for agent_file in sorted(AGENTS_DIR.glob("*.md")):
        content = agent_file.read_text()
        # Extract YAML frontmatter between --- markers
        match = re.match(r"^---\s*\n(.+?)\n---", content, re.DOTALL)
        if not match:
            continue
        try:
            frontmatter = yaml.safe_load(match.group(1))
            if frontmatter and "name" in frontmatter:
                agents.append({
                    "name": frontmatter["name"],
                    "description": frontmatter.get("description", "").strip(),
                })
        except yaml.YAMLError:
            continue

    return agents


def format_agents_section(agents: list[dict[str, str]]) -> str:
    """Format agents list for context injection."""
    if not agents:
        return ""

    lines = ["\n**Available Subagents** - delegate to these for focused work:"]
    for agent in agents:
        desc = agent["description"]
        # Truncate long descriptions
        if len(desc) > 120:
            desc = desc[:117] + "..."
        lines.append(f"- `{agent['name']}`: {desc}")
    lines.append("\nSubagents run in parallel with independent context. Use proactively.")
    return "\n".join(lines)


def main() -> None:
    """Inject project context at session start."""
    setup_memory_symlinks()
    ctx = create_unified_context()

    if not isinstance(ctx, SessionStartContext):
        ctx.output.exit_success()
        return

    # Get workspace from Claude Code's project dir or Augment's workspace_roots
    workspace = ctx.claude_project_dir
    if not workspace:
        # Fall back to Augment's workspace_roots (preserved in transformed data)
        workspace_roots = ctx._input_data.get("workspace_roots", [])  # noqa: SLF001
        if workspace_roots:
            workspace = workspace_roots[0]
        else:
            workspace = ""

    if not workspace:
        ctx.output.exit_success()
        return

    project = Path(workspace).name
    agents = discover_agents()
    agents_section = format_agents_section(agents)

    context_message = f"""Project: {project}

IMPORTANT: Review available_skills list and invoke any relevant skills before responding.
{agents_section}

Check basic-memory for prior context on this project:
- Use build_context or recent_activity to see what's been worked on
- Search for related notes before starting new work
- Continue from previous decisions and learnings"""

    # Use cchooks API - works for both tools
    ctx.output.add_context(context_message)


if __name__ == "__main__":
    main()
