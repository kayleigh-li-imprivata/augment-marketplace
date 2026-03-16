#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0"]
# ///
"""
PreToolUse hook: Intercept pip install commands and rewrite them to use uv add.

Catches patterns like:
- pip install package -> uv add package
- pip install pkg1 pkg2 -> uv add pkg1 pkg2
- pip install -r requirements.txt -> uv pip install -r requirements.txt (fallback)
- pip install -e . -> uv pip install -e . (fallback)

Uses `uv add` for simple package installs (updates lock files).
Falls back to `uv pip install` for -r, -e, and other special flags.
"""

from __future__ import annotations

import json
import re
import sys

# Self-locate for portable imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from augment_adapter import create_unified_context
from cchooks import PreToolUseContext

# Flags that require uv pip install fallback (don't work with uv add)
FALLBACK_FLAGS = re.compile(r"\s-[re]\s|\s--requirement\s|\s--editable\s")


def rewrite_pip_to_uv(command: str) -> tuple[str, str | None]:
    """
    Rewrite pip install commands to use uv add (or uv pip install for special cases).

    Returns (new_command, message) where message is None if no rewrite occurred.
    """
    if "pip install" not in command and "pip3 install" not in command:
        return command, None

    # Extract the pip install portion and its arguments
    # Pattern matches: [python -m] pip[3] install <args>
    match = re.search(
        r"(python3?\s+-m\s+)?pip3?\s+install\s+(.+?)(?:\s*(?:&&|;|\|).*)?$",
        command,
    )
    if not match:
        return command, None

    args = match.group(2).strip()

    # Check if we need to fall back to uv pip install
    if FALLBACK_FLAGS.search(f" {args} "):
        # Use uv pip install for -r, -e flags
        replacement = f"uv pip install {args}"
        msg = f"Rewrote to uv pip install (special flags): {replacement}"
    else:
        # Use uv add for simple package installs
        replacement = f"uv add {args}"
        msg = f"Rewrote pip install to uv add: {replacement}"

    # Replace the matched portion in the original command
    new_command = re.sub(
        r"(python3?\s+-m\s+)?pip3?\s+install\s+.+?(?=\s*(?:&&|;|\|)|$)",
        replacement,
        command,
        count=1,
    )

    return new_command, msg


def main() -> None:
    """Intercept pip install and rewrite to uv add."""
    ctx = create_unified_context()

    if not isinstance(ctx, PreToolUseContext):
        ctx.output.exit_success()
        return

    # Only handle launch-process tool
    if ctx.tool_name != "launch-process":
        ctx.output.exit_success()
        return

    command = ctx.tool_input.get("command", "")
    if not command:
        ctx.output.exit_success()
        return

    new_command, message = rewrite_pip_to_uv(command)

    if message:
        # Output JSON with updatedInput to rewrite the command
        # Augment CLI format for PreToolUse hook output
        updated_input = dict(ctx.tool_input)
        updated_input["command"] = new_command
        output = {
            "systemMessage": message,
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "updatedInput": updated_input,
            },
        }
        print(json.dumps(output))
        sys.exit(0)
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()

