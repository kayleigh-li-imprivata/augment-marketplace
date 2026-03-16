#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0"]
# ///
"""
Stop hook: Remind about notes if files were modified.

Works with both Augment CLI and Claude Code via the unified adapter.
For Augment: requires includeConversationData: true in hook config.
"""

from __future__ import annotations

# Self-locate for portable imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from augment_adapter import create_unified_context
from cchooks import StopContext


def _get_file_change_count(ctx: StopContext) -> int:
    """Get file change count from either tool's format."""
    raw = ctx._input_data  # noqa: SLF001

    # Augment format: conversation.agentCodeResponse
    conversation = raw.get("conversation", {})
    agent_code_response = conversation.get("agentCodeResponse", [])
    if agent_code_response:
        return len(agent_code_response)

    # Claude Code: would need to check transcript, but Stop hook
    # doesn't have easy access to file changes - return 0 for now
    # Users can customize this for Claude Code if needed
    return 0


def main() -> None:
    """Remind about notes when session ends with file changes."""
    ctx = create_unified_context()

    if not isinstance(ctx, StopContext):
        ctx.output.exit_success()
        return

    # Don't re-prompt if already continuing from a stop hook
    if ctx.stop_hook_active:
        ctx.output.allow()
        return

    file_changes = _get_file_change_count(ctx)

    if file_changes > 0:
        reminder = f"""Session involved {file_changes} file operations.

Before ending, consider:
- Should any decisions or learnings be captured in basic-memory?
- Were there insights worth documenting for future sessions?
- Did the work relate to any existing specs that should be updated?

Use knowledge-capture skill or write_note if notes are warranted."""

        # Use cchooks API to prevent stopping and prompt for notes
        ctx.output.prevent(reminder)
    else:
        ctx.output.allow()


if __name__ == "__main__":
    main()
