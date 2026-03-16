#!/usr/bin/env -S uv run --quiet --script 
"""
PostToolUse hook: Track Ralph autonomous loop progress.

Monitors ralph-* subagent calls during /ralph execution:
- Persists state to .ralph/state.json after each task
- Tracks circuit breaker counters
- Writes progress log for external monitoring
- Injects status summary back to agent
"""
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0"]
# ///

from __future__ import annotations

import json
import re
from datetime import datetime, timezone

# Self-locate for portable imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

RALPH_DIR = ".ralph"
STATE_FILE = "state.json"
PROGRESS_LOG = "logs/progress.log"
CB_FILE = "circuit-breaker.json"
CB_NO_PROGRESS_THRESHOLD = 3
CB_SAME_TASK_THRESHOLD = 3


def get_workspace(ctx: PostToolUseContext) -> Path | None:
    """Get workspace path from context."""
    raw = ctx._input_data  # noqa: SLF001
    workspace_roots = raw.get("workspace_roots", [])
    if workspace_roots:
        return Path(workspace_roots[0])
    cwd = raw.get("cwd")
    if cwd:
        return Path(cwd)
    return None


def extract_files_changed(ctx: PostToolUseContext) -> list[str]:
    """Extract files changed from subagent output."""
    raw = ctx._input_data  # noqa: SLF001
    file_changes = raw.get("file_changes", [])
    return [fc.get("path", "") for fc in file_changes if fc.get("path")]


def extract_from_output(output: str, pattern: str) -> str:
    """Extract value from structured output."""
    match = re.search(pattern, output, re.MULTILINE)
    return match.group(1).strip() if match else ""


def parse_subagent_output(ctx: PostToolUseContext) -> dict:
    """Parse structured output from ralph subagents."""
    raw = ctx._input_data  # noqa: SLF001
    output = raw.get("tool_output", "")

    return {
        "task": extract_from_output(output, r"\*\*Task:\*\*\s*(.+)"),
        "verdict": "PASS" if "✅ PASS" in output else "FAIL" if "❌ FAIL" in output else "unknown",
        "files_changed": extract_files_changed(ctx),
    }


def load_json(path: Path, default: dict) -> dict:
    """Load JSON file or return default."""
    if path.exists():
        return json.loads(path.read_text())
    return default.copy()


def save_json(path: Path, data: dict) -> None:
    """Save dict to JSON file, creating parent dirs."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2))


def append_log(path: Path, message: str) -> None:
    """Append timestamped message to log file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%H:%M:%S")
    with path.open("a") as f:
        f.write(f"[{timestamp}] {message}\n")


def update_circuit_breaker(
    cb_path: Path, files_changed: list[str], current_task: str
) -> dict:
    """Update circuit breaker state, return current state."""
    cb = load_json(cb_path, {
        "no_progress_count": 0,
        "same_task_count": 0,
        "last_task": "",
        "tripped": False,
        "trip_reason": None,
    })

    if not files_changed:
        cb["no_progress_count"] = cb.get("no_progress_count", 0) + 1
    else:
        cb["no_progress_count"] = 0

    if current_task and current_task == cb.get("last_task", ""):
        cb["same_task_count"] = cb.get("same_task_count", 0) + 1
    else:
        cb["same_task_count"] = 0
        cb["last_task"] = current_task

    if cb["no_progress_count"] >= CB_NO_PROGRESS_THRESHOLD:
        cb["tripped"] = True
        cb["trip_reason"] = f"No progress for {cb['no_progress_count']} iterations"
    elif cb["same_task_count"] >= CB_SAME_TASK_THRESHOLD:
        cb["tripped"] = True
        cb["trip_reason"] = f"Stuck on same task for {cb['same_task_count']} iterations"

    save_json(cb_path, cb)
    return cb


def update_state(state_path: Path, parsed: dict, tool_name: str) -> dict:
    """Update Ralph state, return current state."""
    state = load_json(state_path, {
        "loop_count": 0,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "phase": "setup",
        "tasks_complete": 0,
        "last_subagent": None,
    })

    state["loop_count"] = state.get("loop_count", 0) + 1
    state["last_updated"] = datetime.now(timezone.utc).isoformat()
    state["last_subagent"] = tool_name
    state["last_task"] = parsed.get("task", "")
    state["last_verdict"] = parsed.get("verdict", "")

    if tool_name == "sub-agent-ralph-quality-review" and parsed.get("verdict") == "PASS":
        state["tasks_complete"] = state.get("tasks_complete", 0) + 1

    save_json(state_path, state)
    return state


def main() -> None:
    """Monitor Ralph loop progress after subagent calls."""
    ctx = create_unified_context()

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    tool_name = ctx.tool_name
    if not tool_name.startswith("sub-agent-ralph-"):
        ctx.output.exit_success()
        return

    workspace = get_workspace(ctx)
    if not workspace:
        ctx.output.exit_success()
        return

    # Initialize .ralph dir if this is first ralph subagent call
    ralph_dir = workspace / RALPH_DIR
    if not ralph_dir.exists():
        ralph_dir.mkdir(parents=True)
        save_json(ralph_dir / STATE_FILE, {
            "started_at": datetime.now(timezone.utc).isoformat(),
            "loop_count": 0,
            "phase": "building",
        })

    parsed = parse_subagent_output(ctx)
    state = update_state(ralph_dir / STATE_FILE, parsed, tool_name)
    cb = update_circuit_breaker(
        ralph_dir / CB_FILE,
        parsed.get("files_changed", []),
        parsed.get("task", ""),
    )

    # Log for external monitoring
    agent_short = tool_name.replace("sub-agent-ralph-", "")
    log_msg = (
        f"{agent_short} | "
        f"Task: {parsed.get('task', 'unknown')[:40]} | "
        f"Verdict: {parsed.get('verdict', '-')} | "
        f"CB: {cb['no_progress_count']}/{CB_NO_PROGRESS_THRESHOLD}"
    )
    append_log(ralph_dir / PROGRESS_LOG, log_msg)

    # Build status for agent
    status = f"📊 Ralph #{state['loop_count']} | {agent_short} | {parsed.get('verdict', '-')}"

    if cb.get("tripped"):
        status += f" | 🔴 CIRCUIT BREAKER: {cb['trip_reason']} - STOP and ask user"

    ctx.output.add_context(status)


if __name__ == "__main__":
    main()

