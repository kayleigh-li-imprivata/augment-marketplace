#!/usr/bin/env -S uv run --quiet --script 
# shellcheck disable=all
"""
PostToolUse hook: Validate skills when SKILL.md files are modified.

Runs skills-ref validator from agentskills/agentskills repository
to ensure skills comply with the agentskills.io specification.
"""
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0"]
# ///

from __future__ import annotations

import os
import re
import subprocess
import sys

from cchooks import PostToolUseContext

# Self-locate for portable imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from augment_adapter import create_unified_context

WORKSPACE_ROOT = Path(os.environ.get("AUGMENT_PROJECT_DIR", ".")).resolve()
DEBUG = os.environ.get("VALIDATE_SKILL_DEBUG", "0") == "1"

# Pattern to match SKILL.md files inside skills directories
SKILL_MD_PATTERN = re.compile(r"^(.*/skills/[^/]+|skills/[^/]+)/SKILL\.md$")


def debug(msg: str) -> None:
    """Print debug message to stderr if DEBUG is enabled."""
    if DEBUG:
        sys.stderr.write(f"[validate_skill] {msg}\n")


def _get_file_changes(ctx: PostToolUseContext) -> list[dict]:
    """Get file changes from either tool's format."""
    raw = ctx._input_data  # noqa: SLF001

    file_changes = raw.get("file_changes", [])
    if file_changes:
        return file_changes

    tool_response = ctx.tool_response
    if "content" in tool_response:
        return [tool_response]

    return []


def run_validator(skill_dir: Path) -> tuple[bool, str]:
    """Run skills-ref validate on a skill directory."""
    cmd = [
        "uvx",
        "--from",
        "git+https://github.com/agentskills/agentskills#subdirectory=skills-ref",
        "skills-ref",
        "validate",
        str(skill_dir),
    ]
    debug(f"Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(  # noqa: S603
            cmd, capture_output=True, text=True, check=False, timeout=60
        )
        output = result.stdout + result.stderr
        debug(f"Exit code: {result.returncode}, Output: {output[:200]}")
        return result.returncode == 0, output.strip()
    except subprocess.TimeoutExpired:
        return False, "Validation timed out after 60s"
    except FileNotFoundError:
        return False, "uvx not found - cannot run skills-ref validator"


def extract_skill_dirs(file_changes: list[dict], workspace_root: Path) -> set[Path]:
    """Extract unique skill directories from file changes."""
    skill_dirs: set[Path] = set()

    for change in file_changes:
        path = change.get("path", "")
        if path:
            match = SKILL_MD_PATTERN.match(path)
            if match:
                skill_dir_str = match.group(1)
                skill_path = Path(skill_dir_str)
                if not skill_path.is_absolute():
                    skill_path = workspace_root / skill_dir_str
                if skill_path.is_dir():
                    skill_dirs.add(skill_path)
                    debug(f"Found skill dir: {skill_path}")

    return skill_dirs


def _get_workspace_root(ctx: PostToolUseContext) -> Path:
    """Get workspace root from input data or environment."""
    raw = ctx._input_data  # noqa: SLF001
    workspace_roots = raw.get("workspace_roots", [])
    if workspace_roots:
        return Path(workspace_roots[0]).resolve()
    return WORKSPACE_ROOT


def main() -> None:
    """Validate skills when SKILL.md files are modified."""
    debug("Hook invoked")
    ctx = create_unified_context()

    if not isinstance(ctx, PostToolUseContext):
        debug("Not a PostToolUseContext, exiting")
        sys.exit(0)

    file_changes = _get_file_changes(ctx)
    debug(f"File changes: {file_changes}")

    workspace_root = _get_workspace_root(ctx)
    debug(f"Workspace root: {workspace_root}")

    skill_dirs = extract_skill_dirs(file_changes, workspace_root)
    if not skill_dirs:
        debug("No skill files modified, exiting")
        ctx.output.exit_success()  # type: ignore[union-attr]

    errors: list[str] = []
    validated: list[str] = []

    for skill_dir in skill_dirs:
        success, output = run_validator(skill_dir)
        if success:
            validated.append(skill_dir.name)
        else:
            errors.append(f"{skill_dir.name}: {output}")

    if errors:
        context = (
            "Skill validation FAILED. Fix the SKILL.md file(s) to comply with "
            "the agentskills.io specification:\n\n" + "\n".join(errors)
        )
        debug(f"Validation failed: {errors}")
        ctx.output.add_context(context)
    else:
        sys.stderr.write(f"Skill validation passed for: {', '.join(validated)}\n")
        ctx.output.exit_success()


if __name__ == "__main__":
    main()

