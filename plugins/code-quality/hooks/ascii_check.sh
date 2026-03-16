#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0"]
# ///
"""
PostToolUse hook: Auto-fix Unicode lookalike characters in file changes.

Works with both Augment CLI and Claude Code via the unified adapter.
Directly modifies files to replace problematic Unicode with ASCII equivalents.
"""

from __future__ import annotations

import os

# Self-locate for portable imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext, PreToolUseContext

# Get workspace root from Augment environment variable
WORKSPACE_ROOT = Path(os.environ.get("AUGMENT_PROJECT_DIR", ".")).resolve()

# Unicode characters: (name, ascii_replacement)
UNICODE_REPLACEMENTS: dict[str, tuple[str, str]] = {
    # Dashes
    "\u2014": ("em dash", " -- "),  # Spaces added; duplicates cleaned up later
    "\u2013": ("en dash", "-"),
    "\u2212": ("minus sign", "-"),
    # Quotes
    "\u201c": ("left curly quote", '"'),
    "\u201d": ("right curly quote", '"'),
    "\u2018": ("left single quote", "'"),
    "\u2019": ("right single quote", "'"),
    # Ellipsis
    "\u2026": ("ellipsis", "..."),
    # Non-breaking spaces (all variants)
    "\u00a0": ("non-breaking space", " "),
    "\u202f": ("narrow no-break space", " "),
    "\u2007": ("figure space", " "),
    "\u2060": ("word joiner", ""),
    "\ufeff": ("zero-width no-break space/BOM", ""),
}


def fix_content(content: str) -> tuple[str, list[str]]:
    """
    Replace Unicode lookalikes with ASCII equivalents.

    Returns the fixed content and a list of replacements made.
    """
    fixed = content
    replacements_made = []

    for unicode_char, (name, ascii_replacement) in UNICODE_REPLACEMENTS.items():
        if unicode_char in fixed:
            count = fixed.count(unicode_char)
            fixed = fixed.replace(unicode_char, ascii_replacement)
            replacements_made.append(f"{count}x {name}")

    # Clean up extra spaces around em-dash replacement only
    # Em-dash is replaced with " -- ", which can create "  -- " adjacent to existing spaces
    # e.g., "word  -- more" becomes "word -- more"
    # Do NOT use blanket double-space replacement - it destroys YAML/Python indentation!
    fixed = fixed.replace("  -- ", " -- ")  # double space before --
    fixed = fixed.replace(" --  ", " -- ")  # double space after --

    return fixed, replacements_made


def _get_file_changes(ctx: PostToolUseContext) -> list[dict]:
    """Get file changes from either tool's format."""
    raw = ctx._input_data  # noqa: SLF001

    # Augment format: file_changes array (preserved by adapter)
    file_changes = raw.get("file_changes", [])
    if file_changes:
        return file_changes

    # Claude Code format: tool_response may contain file info
    tool_response = ctx.tool_response
    if "content" in tool_response:
        return [tool_response]

    return []


def _get_target_file_from_tool_input(ctx: PreToolUseContext) -> Path | None:
    """Extract the target file path from tool input for PreToolUse."""
    tool_input = ctx.tool_input
    # str-replace-editor and save-file use 'path'
    file_path = tool_input.get("path", "")
    if not file_path:
        return None
    path = Path(file_path)
    if not path.is_absolute():
        # Try workspace_roots from context first, then fall back to env var
        raw_data = ctx._input_data  # noqa: SLF001
        workspace_roots = raw_data.get("workspace_roots", [])
        if workspace_roots:
            workspace = Path(workspace_roots[0])
        else:
            workspace = WORKSPACE_ROOT
        path = workspace / file_path
    if path.is_file():
        return path
    return None


def main() -> None:
    """Auto-fix Unicode lookalike characters in modified files."""
    ctx = create_unified_context()

    # Handle PreToolUse - fix files BEFORE str-replace-editor reads them
    if isinstance(ctx, PreToolUseContext):
        target_file = _get_target_file_from_tool_input(ctx)
        if target_file:
            try:
                content = target_file.read_text(encoding="utf-8")
                fixed_content, replacements = fix_content(content)
                if replacements:
                    target_file.write_text(fixed_content, encoding="utf-8")
                    ctx.output.exit_success()
                    return
            except (OSError, UnicodeDecodeError):
                pass
        ctx.output.exit_success()
        return

    if not isinstance(ctx, PostToolUseContext):
        ctx.output.exit_success()
        return

    file_changes = _get_file_changes(ctx)

    if not file_changes:
        ctx.output.exit_success()
        return

    fixes_applied: list[str] = []

    for change in file_changes:
        file_path = change.get("path", "")
        change_type = change.get("changeType", "")

        # Skip deletions
        if change_type == "delete":
            continue

        # Check if file exists and read current content
        # Resolve paths relative to workspace root (paths from Augment are relative)
        path = Path(file_path)
        if not path.is_absolute():
            path = WORKSPACE_ROOT / file_path
        if not path.is_file():
            continue

        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue

        fixed_content, replacements = fix_content(content)

        if replacements:
            path.write_text(fixed_content, encoding="utf-8")
            fixes_applied.append(f"{path}: replaced {', '.join(replacements)}")

    if fixes_applied:
        notice = "ASCII auto-fix applied:\n" + "\n".join(fixes_applied)
        ctx.output.add_context(notice)
    else:
        ctx.output.exit_success()


if __name__ == "__main__":
    main()
