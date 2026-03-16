#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
PreToolUse hook: Ensure git_set_working_dir_git is called before other git MCP tools.

Tracks working dir state in a conversation-scoped temp file.
When a git tool is called without initialization, blocks and tells agent to initialize first.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Read event data from stdin
event_data = json.load(sys.stdin)

tool_name = event_data.get("tool_name", "")
conversation_id = event_data.get("conversation_id", "unknown")
workspace_roots = event_data.get("workspace_roots", [])

# Only handle git MCP tools
if not tool_name.endswith("_git"):
    sys.exit(0)

# State file tracks if working dir has been set for this conversation
state_dir = Path("/tmp/augment-git-state")
state_dir.mkdir(exist_ok=True)
state_file = state_dir / f"{conversation_id}.json"


def load_state() -> dict:
    """Load conversation state."""
    if state_file.exists():
        try:
            return json.loads(state_file.read_text())
        except (json.JSONDecodeError, OSError):
            pass
    return {"working_dir_set": False, "working_dir": None}


def save_state(state: dict) -> None:
    """Save conversation state."""
    state_file.write_text(json.dumps(state))


state = load_state()

# If this is git_set_working_dir_git, mark as initialized
if tool_name == "git_set_working_dir_git":
    tool_input = event_data.get("tool_input", {})
    working_dir = tool_input.get("path", "")
    state["working_dir_set"] = True
    state["working_dir"] = working_dir
    save_state(state)
    sys.exit(0)

# For other git tools, check if working dir is set
if not state["working_dir_set"]:
    # Determine workspace path for suggestion
    workspace = workspace_roots[0] if workspace_roots else "the repository path"

    # Block the tool and tell agent to initialize first
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"Git MCP working directory not initialized. "
                f"Call git_set_working_dir_git with path '{workspace}' first, "
                f"then retry {tool_name}."
            ),
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# Working dir is set, allow the tool
sys.exit(0)

