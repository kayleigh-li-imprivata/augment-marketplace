#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["cchooks>=0.1.0"]
# ///
"""
PostToolUse hook: Auto-run formatters and linters on modified files.

Multi-language support matching Neovim config (conform.nvim + efm-langserver).
Works with both Augment CLI and Claude Code via the unified adapter.
"""

from __future__ import annotations

import os
import subprocess
import sys
from collections.abc import Callable

# Self-locate for portable imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))

from augment_adapter import create_unified_context
from cchooks import PostToolUseContext

AST_GREP_CONFIG = Path.home() / ".config/ast-grep/sgconfig.yml"
# Get workspace root from Augment environment variable
WORKSPACE_ROOT = Path(os.environ.get("AUGMENT_PROJECT_DIR", ".")).resolve()
TEAM_LINTER_CONFIGS = Path.home() / "git/imprivata/ai/.github/linters/configs"
BASIC_MEMORY_VAULT = Path.home() / "basic-memory"

# Set AUTO_LINT_DEBUG=1 to see debug output
DEBUG = os.environ.get("AUTO_LINT_DEBUG", "0") == "1"


def debug(msg: str) -> None:
    """Print debug message to stderr if DEBUG is enabled."""
    if DEBUG:
        print(f"[auto_lint] {msg}", file=sys.stderr)


def find_project_root(file_path: str) -> Path | None:
    """Find the nearest parent directory containing pyproject.toml."""
    path = Path(file_path).resolve()
    for parent in path.parents:
        if (parent / "pyproject.toml").exists():
            return parent
    return None


def run_command(
    cmd: list[str], cwd: Path | None = None, timeout: int = 30
) -> tuple[int, str]:
    """Run a command and return exit code and combined output."""
    try:
        debug(f"Running: {' '.join(cmd)} (cwd={cwd})")
        result = subprocess.run(  # noqa: S603
            cmd, capture_output=True, text=True, check=False, cwd=cwd, timeout=timeout
        )
        output = result.stdout + result.stderr
        debug(f"  Exit code: {result.returncode}")
        if result.returncode != 0 and output.strip():
            debug(f"  Output: {output[:200]}")
        return result.returncode, output
    except subprocess.TimeoutExpired:
        debug(f"  Command timed out after {timeout}s: {cmd[0]}")
        return -2, f"Command timed out after {timeout}s: {cmd[0]}"
    except FileNotFoundError:
        debug(f"  Command not found: {cmd[0]}")
        return -1, f"Command not found: {cmd[0]}"


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


# --- Python ---


def format_python(files: list[str]) -> list[str]:
    """Format Python files with ruff (format + organize imports + fix)."""
    for f in files:
        run_command(["ruff", "format", f])
        run_command(["ruff", "check", "--fix", "--select=I", f])  # imports
        run_command(["ruff", "check", "--fix", "--ignore=F401,F841", f])
    return []


def lint_python(files: list[str]) -> list[str]:
    """Lint Python files with ruff, ty, and ast-grep."""
    errors: list[str] = []
    for f in files:
        project_root = find_project_root(f)
        code, out = run_command(
            ["ruff", "check", "--output-format=concise", f], cwd=project_root
        )
        if code != 0 and out.strip():
            errors.append(f"ruff ({f}):\n{out}")
        code, out = run_command(
            ["ty", "check", f],
            cwd=project_root,
        )
        if code != 0 and out.strip():
            errors.append(f"ty ({f}):\n{out}")
        code, out = run_command(
            ["sg", "scan", "--config", str(AST_GREP_CONFIG), f], cwd=project_root
        )
        if code != 0 and out.strip():
            errors.append(f"ast-grep ({f}):\n{out}")
    return errors


# --- Shell (sh/bash) ---

# Directories where .sh files are actually Python scripts (uv shebang)
PYTHON_SCRIPT_DIRS = {
    str(Path.home() / ".augment/hooks"),
}


def is_python_script(filepath: str) -> bool:
    """Check if a .sh file is actually a Python script (uv shebang)."""
    # Check if in a known Python script directory
    file_path = Path(filepath).resolve()
    for dir_path in PYTHON_SCRIPT_DIRS:
        if str(file_path).startswith(dir_path):
            return True
    # Also check shebang as fallback
    try:
        with open(filepath, "r") as f:
            first_line = f.readline()
            return "uv run" in first_line or "python" in first_line.lower()
    except (OSError, UnicodeDecodeError):
        return False


def format_shell(files: list[str]) -> list[str]:
    """Format shell scripts with shfmt."""
    for f in files:
        if is_python_script(f):
            continue
        run_command(["shfmt", "-w", "-i", "2", "-ci", "-bn", f])
    return []


def lint_shell(files: list[str]) -> list[str]:
    """Lint shell scripts with shellcheck."""
    errors: list[str] = []
    for f in files:
        if is_python_script(f):
            continue
        code, out = run_command(["shellcheck", "-f", "gcc", "-x", f])
        if code != 0 and out.strip():
            errors.append(f"shellcheck ({f}):\n{out}")
    return errors


# =============================================================================
# Fish
# =============================================================================


def format_fish(files: list[str]) -> list[str]:
    """Format fish scripts with fish_indent."""
    for f in files:
        run_command(["fish_indent", "-w", f])
    return []


# =============================================================================
# YAML
# =============================================================================


def format_yaml(files: list[str]) -> list[str]:
    """Format YAML files with yamlfmt."""
    for f in files:
        run_command(["yamlfmt", f])
    return []


def lint_yaml(files: list[str]) -> list[str]:
    """Lint YAML files with yamllint."""
    errors: list[str] = []
    config = TEAM_LINTER_CONFIGS / ".yamllint.yml"
    config_args: list[str] = []
    if config.exists():
        config_args = ["-c", str(config)]
    for f in files:
        code, out = run_command(["yamllint", *config_args, "-f", "parsable", f])
        if code != 0 and out.strip():
            errors.append(f"yamllint ({f}):\n{out}")
    return errors


# =============================================================================
# JSON
# =============================================================================


def format_json(files: list[str]) -> list[str]:
    """Format JSON files with jq."""
    for f in files:
        code, out = run_command(["jq", ".", f])
        if code == 0:
            Path(f).write_text(out)
    return []


# =============================================================================
# Markdown
# =============================================================================


CBFMT_CONFIG = Path.home() / ".config/cbfmt.toml"


def format_markdown(files: list[str]) -> list[str]:
    """Format Markdown files with mdslw (line wrapping) and cbfmt (code blocks)."""
    for f in files:
        # First: mdslw for semantic line wrapping of prose
        code, out = run_command(["mdslw", f])
        if code == 0 and out:
            Path(f).write_text(out)
        # Second: cbfmt for formatting code blocks based on language
        if CBFMT_CONFIG.exists():
            run_command(["cbfmt", "--config", str(CBFMT_CONFIG), "-w", f])
    return []


def lint_markdown(files: list[str]) -> list[str]:
    """Lint Markdown files with markdownlint-cli2 and lychee wiki-link checker."""
    errors: list[str] = []
    config = TEAM_LINTER_CONFIGS / ".markdownlint.json"
    config_args: list[str] = []
    if config.exists():
        config_args = ["--config", str(config)]
    for f in files:
        code, out = run_command(["markdownlint-cli2", *config_args, f])
        if code != 0 and out.strip():
            errors.append(f"markdownlint ({f}):\n{out}")

    # Check wiki-links with lychee for files in Basic Memory vault
    # Exclude crawled docs (external references) and _meta directory
    vault_files = [
        f
        for f in files
        if str(BASIC_MEMORY_VAULT) in f and "/docs/" not in f and "/_meta/" not in f
    ]
    if vault_files:
        for f in vault_files:
            code, out = run_command(
                [
                    "lychee",
                    "--include-wikilinks",
                    "--base-url",
                    str(BASIC_MEMORY_VAULT),
                    "--fallback-extensions",
                    "md",
                    "--no-progress",
                    "--offline",
                    f,
                ]
            )
            if code != 0 and out.strip():
                errors.append(f"lychee wiki-links ({f}):\n{out}")
    return errors


# =============================================================================
# Lua
# =============================================================================


def format_lua(files: list[str]) -> list[str]:
    """Format Lua files with stylua."""
    for f in files:
        run_command(["stylua", f])
    return []


# =============================================================================
# Go
# =============================================================================


def format_go(files: list[str]) -> list[str]:
    """Format Go files with gofumpt and goimports."""
    for f in files:
        run_command(["gofumpt", "-w", f])
        run_command(["goimports", "-w", f])
    return []


# =============================================================================
# Terraform
# =============================================================================


def lint_terraform(files: list[str]) -> list[str]:
    """Lint Terraform files with tflint and checkov."""
    errors: list[str] = []
    tflint_config = TEAM_LINTER_CONFIGS / ".tflint.hcl"
    tflint_args: list[str] = []
    if tflint_config.exists():
        tflint_args = ["--config", str(tflint_config)]
    checkov_config = TEAM_LINTER_CONFIGS / ".checkov.yml"
    checkov_args: list[str] = []
    if checkov_config.exists():
        checkov_args = ["--config-file", str(checkov_config)]

    for f in files:
        code, out = run_command(["tflint", *tflint_args, "--format", "compact", f])
        if code != 0 and out.strip():
            errors.append(f"tflint ({f}):\n{out}")
        code, out = run_command(
            ["checkov", *checkov_args, "--file", f, "--compact", "--quiet"]
        )
        if code != 0 and out.strip():
            errors.append(f"checkov ({f}):\n{out}")
    return errors


# =============================================================================
# Dockerfile
# =============================================================================


def lint_dockerfile(files: list[str]) -> list[str]:
    """Lint Dockerfiles with hadolint."""
    errors: list[str] = []
    for f in files:
        code, out = run_command(["hadolint", "--format", "tty", f])
        if code != 0 and out.strip():
            errors.append(f"hadolint ({f}):\n{out}")
    return errors


# =============================================================================
# GitHub Actions
# =============================================================================


def lint_github_actions(files: list[str]) -> list[str]:
    """Lint GitHub Actions workflows with actionlint."""
    errors: list[str] = []
    for f in files:
        code, out = run_command(["actionlint", f])
        if code != 0 and out.strip():
            errors.append(f"actionlint ({f}):\n{out}")
    return errors


# =============================================================================
# Dispatcher
# =============================================================================

# Type alias for linter/formatter functions
LintFunc = Callable[[list[str]], list[str]]

# Map file patterns to formatters and linters
# Order: formatters run first, then linters
FORMATTERS: dict[str, LintFunc] = {
    ".py": format_python,
    ".sh": format_shell,
    ".bash": format_shell,
    ".fish": format_fish,
    ".yaml": format_yaml,
    ".yml": format_yaml,
    ".json": format_json,
    ".md": format_markdown,
    ".lua": format_lua,
    ".go": format_go,
}

LINTERS: dict[str, LintFunc] = {
    ".py": lint_python,
    ".sh": lint_shell,
    ".bash": lint_shell,
    ".yaml": lint_yaml,
    ".yml": lint_yaml,
    ".md": lint_markdown,
    ".tf": lint_terraform,
}

# Special filename patterns (not extensions)
FILENAME_LINTERS: dict[str, LintFunc] = {
    "Dockerfile": lint_dockerfile,
}

GITHUB_ACTIONS_PATTERN = ".github/workflows/"


def get_handlers(
    file_path: str,
) -> tuple[LintFunc | None, LintFunc | None]:
    """Get formatter and linter for a file based on extension or name."""
    path = Path(file_path)
    ext = path.suffix.lower()
    name = path.name

    # Check special filename patterns first
    if name in FILENAME_LINTERS:
        return None, FILENAME_LINTERS[name]

    # Check GitHub Actions workflows
    if GITHUB_ACTIONS_PATTERN in file_path:
        return FORMATTERS.get(ext), lint_github_actions

    return FORMATTERS.get(ext), LINTERS.get(ext)


def main() -> None:
    """Auto-run formatters and linters on modified files."""
    debug("Hook invoked")
    ctx = create_unified_context()
    debug(f"Context type: {type(ctx).__name__}")

    if not isinstance(ctx, PostToolUseContext):
        debug("Not a PostToolUseContext, exiting")
        ctx.output.exit_success()
        return

    file_changes = _get_file_changes(ctx)
    debug(f"File changes: {file_changes}")
    if not file_changes:
        debug("No file changes, exiting")
        ctx.output.exit_success()
        return

    # Collect files that were modified (not deleted) and still exist
    # Resolve paths relative to workspace root (paths from Augment are relative)
    modified_files: list[str] = []
    for change in file_changes:
        if change.get("changeType", "") == "delete":
            continue
        rel_path = change.get("path", "")
        if not rel_path:
            continue
        # Try absolute path first, then resolve relative to workspace
        path = Path(rel_path)
        if not path.is_absolute():
            path = WORKSPACE_ROOT / rel_path
        if path.is_file():
            modified_files.append(str(path))
    debug(f"Modified files: {modified_files}")

    if not modified_files:
        debug("No modified files after filtering, exiting")
        ctx.output.exit_success()
        return

    # Group files by their handlers
    format_groups: dict[LintFunc, list[str]] = {}
    lint_groups: dict[LintFunc, list[str]] = {}

    for f in modified_files:
        formatter, linter = get_handlers(f)
        if formatter:
            format_groups.setdefault(formatter, []).append(f)
        if linter:
            lint_groups.setdefault(linter, []).append(f)

    debug(f"Format groups: {len(format_groups)}, Lint groups: {len(lint_groups)}")

    # Run formatters first (they modify files)
    for formatter, files in format_groups.items():
        debug(f"Running formatter {formatter.__name__} on {files}")
        formatter(files)

    # Run linters and collect errors
    lint_output: list[str] = []
    for linter, files in lint_groups.items():
        debug(f"Running linter {linter.__name__} on {files}")
        lint_output.extend(linter(files))

    debug(f"Lint output count: {len(lint_output)}")
    if lint_output:
        context = (
            "LINT ERRORS detected in modified files. "
            "You MUST fix ALL of these before proceeding.\n\n"
            "IMPORTANT: Pre-existing errors are NOT exempt. "
            "Do NOT skip errors because they were 'already there' or 'out of scope'. "
            "All errors must be fixed unless the user has explicitly said to ignore them.\n\n"
        )
        context += "\n".join(lint_output)
        debug("Adding context with lint errors")
        ctx.output.add_context(context)
    else:
        debug("No lint errors, exiting success")
        ctx.output.exit_success()


if __name__ == "__main__":
    main()
