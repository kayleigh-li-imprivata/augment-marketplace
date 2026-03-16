#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
PreToolUse hook: Allow free commits in .worktrees/, defer to toolPermissions elsewhere.

AI can commit freely when working in an isolated worktree (.worktrees/ directory).
In the main checkout, the default toolPermission (ask-user) applies.

This hook only outputs "allow" for worktrees. For all other cases, it exits
silently and lets the toolPermissions default of "ask-user" handle it.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Read event data from stdin
event_data = json.load(sys.stdin)

tool_name = event_data.get("tool_name", "")

# Only handle git_commit_git
if tool_name != "git_commit_git":
    sys.exit(0)

# Get the working directory from conversation state
conversation_id = event_data.get("conversation_id", "unknown")
state_file = Path(f"/tmp/augment-git-state/{conversation_id}.json")

working_dir = None
if state_file.exists():
    try:
        state = json.loads(state_file.read_text())
        working_dir = state.get("working_dir")
    except (json.JSONDecodeError, OSError):
        pass

# If we can't determine the working directory, let toolPermissions handle it (ask-user)
if not working_dir:
    sys.exit(0)

# Check if the working directory is inside a .worktrees/ directory
working_path = Path(working_dir).resolve()

# Look for .worktrees in any parent of the working directory
is_in_worktree = False
for parent in [working_path, *working_path.parents]:
    if parent.name == ".worktrees":
        is_in_worktree = True
        break

if is_in_worktree:
    # In a worktree - explicitly allow commit without asking
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": "Committing in worktree - allowed without confirmation.",
        }
    }
    print(json.dumps(output))
    sys.exit(0)

# For main checkout, deny the commit - requires explicit user approval via Augment prompt
tool_input = event_data.get("tool_input", {})
commit_message = tool_input.get("message", "<no message>")

output = {
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": (
            f"Committing to main checkout (not a worktree).\n"
            f'Message: "{commit_message}"\n\n'
            f"To commit, approve this tool call in Augment."
        ),
    }
}
print(json.dumps(output))
sys.exit(0)

