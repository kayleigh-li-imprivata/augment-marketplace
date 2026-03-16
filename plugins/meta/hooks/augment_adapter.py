# ruff: noqa: INP001
"""
Adapter layer to use cchooks with both Augment CLI and Claude Code.

Augment CLI and Claude Code use different JSON schemas for hooks.
This adapter auto-detects the environment and transforms as needed,
allowing the same hook code to work with both tools.

Usage:
    from augment_adapter import create_unified_context

    ctx = create_unified_context()
    if isinstance(ctx, SessionStartContext):
        # Use cchooks API - works with both Augment and Claude Code
        ctx.output.exit_success()
"""

from __future__ import annotations

import json
import sys
from io import StringIO
from typing import TYPE_CHECKING, Any

from cchooks import HookContext, create_context

if TYPE_CHECKING:
    from typing import TextIO

# Placeholder path when Augment doesn't provide equivalent
_PLACEHOLDER_PATH = "/var/tmp/augment-hook"  # noqa: S108


def _is_claude_code_schema(data: dict[str, Any]) -> bool:
    """
    Detect if input is Claude Code format vs Augment.

    Claude Code provides session_id/transcript_path; Augment uses conversation_id.
    """
    return "session_id" in data or "transcript_path" in data


def _get_workspace_path(data: dict[str, Any]) -> str:
    """Extract first workspace root or return placeholder."""
    workspace_roots = data.get("workspace_roots", [])
    if workspace_roots:
        return str(workspace_roots[0])
    return _PLACEHOLDER_PATH


def _transform_session_start(data: dict[str, Any]) -> dict[str, Any]:
    """Transform Augment SessionStart to cchooks format."""
    return {
        "hook_event_name": "SessionStart",
        "session_id": data.get("conversation_id", "augment-session"),
        "transcript_path": _get_workspace_path(data),
        "source": "startup",  # Augment doesn't provide this; default to startup
        # Preserve original data for access via ctx.raw
        **{k: v for k, v in data.items() if k not in ["conversation_id"]},
    }


def _transform_stop(data: dict[str, Any]) -> dict[str, Any]:
    """Transform Augment Stop to cchooks format."""
    return {
        "hook_event_name": "Stop",
        "session_id": data.get("conversation_id", "augment-session"),
        "transcript_path": _get_workspace_path(data),
        "stop_hook_active": False,  # Augment uses agent_stop_cause instead
        # Preserve Augment-specific fields
        "agent_stop_cause": data.get("agent_stop_cause"),
        "conversation": data.get("conversation", {}),
    }


def _transform_post_tool_use(data: dict[str, Any]) -> dict[str, Any]:
    """Transform Augment PostToolUse to cchooks format."""
    # Build tool_response from Augment's fields
    tool_response: dict[str, Any] = {}
    if "tool_output" in data:
        tool_response["output"] = data["tool_output"]
    if "tool_error" in data:
        tool_response["error"] = data["tool_error"]
    if "file_changes" in data:
        tool_response["file_changes"] = data["file_changes"]

    cwd = _get_workspace_path(data)
    return {
        "hook_event_name": "PostToolUse",
        "session_id": data.get("conversation_id", "augment-session"),
        "transcript_path": cwd,
        "tool_name": data.get("tool_name", "unknown"),
        "tool_input": data.get("tool_input", {}),
        "tool_response": tool_response,
        "cwd": cwd,
        # Preserve Augment-specific fields for access via ctx._input_data
        "file_changes": data.get("file_changes", []),
        "workspace_roots": data.get("workspace_roots", []),
    }


def _transform_pre_tool_use(data: dict[str, Any]) -> dict[str, Any]:
    """Transform Augment PreToolUse to cchooks format."""
    cwd = _get_workspace_path(data)
    return {
        "hook_event_name": "PreToolUse",
        "session_id": data.get("conversation_id", "augment-session"),
        "transcript_path": cwd,
        "tool_name": data.get("tool_name", "unknown"),
        "tool_input": data.get("tool_input", {}),
        "cwd": cwd,
        # Preserve Augment-specific fields for access via ctx._input_data
        "workspace_roots": data.get("workspace_roots", []),
    }


TRANSFORMERS = {
    "SessionStart": _transform_session_start,
    "Stop": _transform_stop,
    "PostToolUse": _transform_post_tool_use,
    "PreToolUse": _transform_pre_tool_use,
}


def transform_augment_to_cchooks(data: dict[str, Any]) -> dict[str, Any]:
    """Transform Augment CLI input to cchooks-compatible format."""
    hook_event = data.get("hook_event_name", "")
    transformer = TRANSFORMERS.get(hook_event)
    if transformer:
        return transformer(data)
    # Unknown hook type - pass through with minimal transformation
    return {
        "session_id": data.get("conversation_id", "augment-session"),
        "transcript_path": _get_workspace_path(data),
        **data,
    }


def create_augment_context(stdin: TextIO = sys.stdin) -> HookContext:
    """
    Create cchooks context from Augment CLI input.

    Reads Augment's JSON, transforms to cchooks format, and returns context.
    """
    augment_data = json.load(stdin)
    cchooks_data = transform_augment_to_cchooks(augment_data)
    transformed_stdin = StringIO(json.dumps(cchooks_data))
    return create_context(transformed_stdin)


def create_unified_context(stdin: TextIO = sys.stdin) -> HookContext:
    """
    Create cchooks context from either Augment CLI or Claude Code input.

    Auto-detects the input format and transforms if needed.
    Use this for hooks that should work with both tools.
    """
    raw_input = stdin.read()
    data = json.loads(raw_input)

    if _is_claude_code_schema(data):
        # Already in cchooks format, pass through
        return create_context(StringIO(raw_input))

    # Augment format - transform first
    cchooks_data = transform_augment_to_cchooks(data)
    return create_context(StringIO(json.dumps(cchooks_data)))
