#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""
Script-policy for git_commit_git: Allow commits in worktrees, prompt for main checkout.

This script is used as a toolPermissions script-policy (not a hook).
- Exit 0: Allow the tool execution
- Exit non-zero: Deny the tool execution
- stdout: Message shown to user

Payload format from Augment:
{
  "tool-name": "mcp:git_commit_git",
  "event-type": "tool-call",
  "details": { ... tool-specific data ... },
  "timestamp": "2025-01-01T02:41:40.580Z"
}
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Read payload from stdin
payload = json.load(sys.stdin)

# Get conversation ID from environment or use a default lookup
# The script-policy doesn't pass conversation_id, so we need to check all state files
# and find one that matches a recent timestamp or the current working directory

state_dir = Path("/tmp/augment-git-state")
working_dir = None

# Try to find the most recent state file
if state_dir.exists():
    state_files = sorted(state_dir.glob("*.json"), key=lambda f: f.stat().st_mtime, reverse=True)
    for state_file in state_files:
        try:
            state = json.loads(state_file.read_text())
            wd = state.get("working_dir")
            if wd:
                working_dir = wd
                break
        except (json.JSONDecodeError, OSError):
            pass

# If we can't determine the working directory, deny (safe default)
if not working_dir:
    print("Cannot determine git working directory. Please set working directory with git_set_working_dir_git first.")
    sys.exit(1)

# Check if the working directory is inside a .worktrees/ directory
working_path = Path(working_dir).resolve()

is_in_worktree = False
for parent in [working_path, *working_path.parents]:
    if parent.name == ".worktrees":
        is_in_worktree = True
        break

if is_in_worktree:
    # In a worktree - allow commit
    sys.exit(0)
else:
    # In main checkout - deny with message
    details = payload.get("details", {})
    message = details.get("message", "<no message>")
    print(f"Committing to main checkout (not a worktree).")
    print(f'Message: "{message}"')
    print()
    print("To commit in main checkout, use the terminal directly.")
    sys.exit(1)

