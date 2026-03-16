#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
PostToolUse hook: Detect git MCP server session loss and clear state for re-initialization.

When the git MCP server restarts (due to crash, ToolHive restart, etc.), it loses its
session working directory. This hook detects that condition and clears the conversation
state file so the PreToolUse hook will prompt for re-initialization.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Read event data from stdin
event_data = json.load(sys.stdin)

tool_name = event_data.get("tool_name", "")
conversation_id = event_data.get("conversation_id", "unknown")
tool_output = event_data.get("tool_output", "")

# Only handle git MCP tools (except git_set_working_dir_git which sets state)
if not tool_name.endswith("_git") or tool_name == "git_set_working_dir_git":
    sys.exit(0)

# Check if the output indicates session loss
SESSION_LOST_INDICATORS = [
    "No session working directory set",
    "Please specify a 'path' or use 'git_set_working_dir' first",
]

session_lost = any(indicator in str(tool_output) for indicator in SESSION_LOST_INDICATORS)

if session_lost:
    # Clear the state file so PreToolUse hook will block next git call
    state_dir = Path("/tmp/augment-git-state")
    state_file = state_dir / f"{conversation_id}.json"
    
    if state_file.exists():
        state_file.unlink()
    
    # Output a message to inform the agent
    output = {
        "hookSpecificOutput": {
            "message": (
                "Git MCP server session was lost (server restarted). "
                "State cleared - next git operation will prompt for re-initialization."
            )
        }
    }
    print(json.dumps(output))

sys.exit(0)

