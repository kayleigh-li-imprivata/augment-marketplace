#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pydantic>=2.0",
#     "pydantic-settings>=2.0",
#     "plyvel>=1.5.0",
# ]
# ///
"""
Auglog - Session loading and formatting for Augment CLI sessions.

This script uses PEP 723 inline dependencies for portability.

CLI usage:
    uv run auglog.py list              # List recent sessions
    uv run auglog.py list --json       # Output as JSON
    uv run auglog.py show <session_id> # Show formatted session

Python import:
    from auglog import Session, load, load_all, list_all
"""

from __future__ import annotations

import json
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, cast

import plyvel
from pydantic import BaseModel, ConfigDict, Field, field_validator
from pydantic_settings import CliApp, CliSubCommand

# =============================================================================
# Pydantic Models (Session Data)
# =============================================================================


class ToolUse(BaseModel):
    """A tool invocation by the agent."""

    tool_use_id: str
    tool_name: str
    input_json: str
    is_partial: bool = False


class ToolResult(BaseModel):
    """Result from a tool invocation."""

    tool_use_id: str
    content: str
    is_error: bool = False


class RequestNode(BaseModel):
    """A node in the request (user message, IDE state, or tool result)."""

    id: int
    type: int
    text_node: dict[str, Any] | None = None
    ide_state_node: dict[str, Any] | None = None
    tool_result_node: ToolResult | None = None


class ThinkingContent(BaseModel):
    """Extended thinking content with summary and optional encrypted content."""

    summary: str = ""
    content: str | None = None
    encrypted_content: str | None = None
    openai_responses_api_item_id: str | None = None


class ResponseNode(BaseModel):
    """A node in the response (text content or tool use)."""

    id: int
    type: int
    content: str = ""
    tool_use: ToolUse | None = None
    thinking: str | ThinkingContent | None = None


class ExchangeData(BaseModel):
    """The inner exchange data with request/response details."""

    request_message: str
    response_text: str
    request_id: str
    request_nodes: list[RequestNode] = Field(default_factory=list)
    response_nodes: list[ResponseNode] = Field(default_factory=list)


class Exchange(BaseModel):
    """A single exchange (turn) in the conversation."""

    model_config = ConfigDict(populate_by_name=True)

    exchange: ExchangeData
    completed: bool = True
    sequence_id: float = Field(alias="sequenceId")
    finished_at: datetime | None = Field(default=None, alias="finishedAt")
    changed_files: list[str] = Field(default_factory=list, alias="changedFiles")

    @field_validator("changed_files", mode="before")
    @classmethod
    def normalize_changed_files(cls, v: Any) -> list[str]:
        """Handle both string lists and object lists for changedFiles."""
        if not v:
            return []
        result: list[str] = []
        for item in v:
            if isinstance(item, str):
                result.append(item)
            elif isinstance(item, dict):
                item_dict = cast("dict[str, Any]", item)
                raw_path = (
                    item_dict.get("old_path")
                    or item_dict.get("path")
                    or item_dict.get("new_path")
                )
                if isinstance(raw_path, str):
                    result.append(raw_path)
        return result

    def format(self, index: int, *, max_response_length: int = 2000) -> str:
        """
        Format this exchange as markdown.

        Args:
            index: Exchange number (1-based)
            max_response_length: Truncate responses longer than this

        Returns:
            Markdown formatted exchange

        """
        lines: list[str] = []
        lines.append(f"### Exchange {index}")
        lines.append("")

        # User message
        user_msg = self.exchange.request_message.strip()
        if user_msg:
            lines.append(f"**Me:** {user_msg}")
        else:
            lines.append("**Me:** *(no message)*")
        lines.append("")

        # Agent response (truncate very long responses)
        response = self.exchange.response_text.strip()
        if len(response) > max_response_length:
            response = response[:max_response_length] + "\n\n*[response truncated]*"
        lines.append(f"**Agent:** {response}")
        lines.append("")

        # Tools used
        tools = [
            node.tool_use.tool_name
            for node in self.exchange.response_nodes
            if node.tool_use
        ]
        if tools:
            lines.append(f"*Tools used: {', '.join(tools)}*")
            lines.append("")

        # Files changed
        if self.changed_files:
            lines.append(f"*Files changed: {', '.join(self.changed_files)}*")
            lines.append("")

        return "\n".join(lines)


class AgentState(BaseModel):
    """Agent state stored in the session."""

    model_config = ConfigDict(populate_by_name=True)

    user_guidelines: str = Field(default="", alias="userGuidelines")
    workspace_guidelines: str = Field(default="", alias="workspaceGuidelines")
    agent_memories: str = Field(default="", alias="agentMemories")
    model_id: str = Field(default="", alias="modelId")


class Session(BaseModel):
    """A complete Augment CLI session."""

    model_config = ConfigDict(populate_by_name=True)

    session_id: str = Field(alias="sessionId")
    created: datetime
    modified: datetime
    chat_history: list[Exchange] = Field(default_factory=list, alias="chatHistory")
    agent_state: AgentState | None = Field(default=None, alias="agentState")
    root_task_uuid: str | None = Field(default=None, alias="rootTaskUuid")

    @property
    def title(self) -> str:
        """Get first user message as title (truncated to 100 chars)."""
        for ex in self.chat_history:
            msg = ex.exchange.request_message.strip()
            # Skip empty or trivially short messages
            if msg:
                first_line = msg.split("\n")[0].strip()
                if first_line:
                    return first_line[:100]
        return "(no title)"

    @property
    def exchange_count(self) -> int:
        """Number of exchanges in this session."""
        return len(self.chat_history)

    @property
    def duration_minutes(self) -> float | None:
        """Duration of session in minutes, if determinable."""
        if not self.chat_history:
            return None
        first_finished = self.chat_history[0].finished_at
        last_finished = self.chat_history[-1].finished_at
        if first_finished and last_finished:
            delta = last_finished - first_finished
            return delta.total_seconds() / 60
        return None

    @property
    def repos(self) -> set[str]:
        """Extract unique repository paths from workspace folders."""
        repos: set[str] = set()
        for ex in self.chat_history:
            for node in ex.exchange.request_nodes:
                if node.ide_state_node:
                    folders = node.ide_state_node.get("workspace_folders", [])
                    for folder in folders:
                        if repo := folder.get("repository_root"):
                            repos.add(repo)
        return repos

    @property
    def tools_used(self) -> set[str]:
        """Extract unique tool names used in this session."""
        tools: set[str] = set()
        for ex in self.chat_history:
            for node in ex.exchange.response_nodes:
                if node.tool_use:
                    tools.add(node.tool_use.tool_name)
        return tools

    @property
    def files_changed(self) -> set[str]:
        """
        Collect all files changed across all exchanges.

        Combines explicit changedFiles data with inference from file-modifying
        tool usage (save-file, str-replace-editor, etc.)
        """
        files: set[str] = set()
        file_modifying_tools = {
            "save-file",
            "str-replace-editor",
            "write_file_filesystem",
            "edit_file_filesystem",
            "remove-files",
        }

        for ex in self.chat_history:
            files.update(ex.changed_files)
            for node in ex.exchange.response_nodes:
                if node.tool_use and node.tool_use.tool_name in file_modifying_tools:
                    try:
                        input_data = json.loads(node.tool_use.input_json)
                        path = input_data.get("path")
                        if path:
                            files.add(path)
                        for fp in input_data.get("file_paths", []):
                            files.add(fp)
                    except (json.JSONDecodeError, TypeError):
                        pass  # Invalid JSON in tool input, skip file inference
        return files

    def format_log(self) -> str:
        """Format all exchanges as a markdown session log."""
        lines: list[str] = []
        lines.append("## Session Log")
        lines.append("")

        for i, exchange in enumerate(self.chat_history, 1):
            lines.append(exchange.format(i))

        return "\n".join(lines)


# =============================================================================
# Session Loading Functions
# =============================================================================


SESSIONS_DIR = Path.home() / ".augment" / "sessions"


def list_all(sessions_dir: Path | None = None) -> list[str]:
    """
    List all session IDs in the sessions directory.

    Args:
        sessions_dir: Path to sessions directory. Defaults to ~/.augment/sessions/

    Returns:
        List of session IDs (UUIDs without .json extension)

    """
    directory = sessions_dir if sessions_dir is not None else SESSIONS_DIR
    if not directory.exists():
        return []

    return sorted(path.stem for path in directory.glob("*.json"))


def load(session_id: str, sessions_dir: Path | None = None) -> Session:
    """
    Load a session by ID.

    Args:
        session_id: The session UUID
        sessions_dir: Path to sessions directory. Defaults to ~/.augment/sessions/

    Returns:
        Parsed Session object

    Raises:
        FileNotFoundError: If session file doesn't exist
        ValueError: If session JSON is invalid

    """
    directory = sessions_dir if sessions_dir is not None else SESSIONS_DIR
    session_path = directory / f"{session_id}.json"

    if not session_path.exists():
        msg = f"Session not found: {session_id}"
        raise FileNotFoundError(msg)

    with session_path.open() as f:
        data = json.load(f)

    return Session.model_validate(data)


def _try_load(session_id: str, sessions_dir: Path | None) -> Session | None:
    """Attempt to load a session, returning None if invalid."""
    try:
        return load(session_id, sessions_dir)
    except (ValueError, json.JSONDecodeError):
        return None  # Skip invalid sessions, they may be corrupted


def load_all(sessions_dir: Path | None = None) -> list[Session]:
    """
    Load all sessions from the sessions directory.

    Args:
        sessions_dir: Path to sessions directory. Defaults to ~/.augment/sessions/

    Returns:
        List of parsed Session objects (skips invalid sessions)

    """
    return [
        s
        for session_id in list_all(sessions_dir)
        if (s := _try_load(session_id, sessions_dir)) is not None
    ]


# =============================================================================
# VSCode Session Loading Functions
# =============================================================================


VSCODE_STORAGE_DIR = Path.home() / ".config" / "Code" / "User" / "workspaceStorage"


class VSCodeWorkspace(BaseModel):
    """A VSCode workspace with Augment extension data."""

    hash: str
    path: str
    db_path: Path

    model_config = ConfigDict(arbitrary_types_allowed=True)


def _get_workspace_path(ws_dir: Path) -> str:
    """Extract workspace path from workspace.json, returning '(unknown)' on failure."""
    ws_json = ws_dir / "workspace.json"
    if not ws_json.exists():
        return "(unknown)"
    try:
        data = json.loads(ws_json.read_text())
        raw_path = data.get("folder") or data.get("configuration") or "(unknown)"
        return raw_path.removeprefix("file://")
    except json.JSONDecodeError:
        return "(unknown)"


def _try_build_workspace(ws_dir: Path) -> VSCodeWorkspace | None:
    """Build a VSCodeWorkspace from a directory, returning None if invalid."""
    if not ws_dir.is_dir():
        return None
    db_path = ws_dir / "Augment.vscode-augment" / "augment-kv-store"
    if not db_path.exists():
        return None
    ws_path = _get_workspace_path(ws_dir)
    return VSCodeWorkspace(hash=ws_dir.name, path=ws_path, db_path=db_path)


def list_vscode_workspaces() -> list[VSCodeWorkspace]:
    """
    List all VSCode workspaces that have Augment extension data.

    Returns:
        List of VSCodeWorkspace objects with hash, path, and db_path

    """
    if not VSCODE_STORAGE_DIR.exists():
        return []

    return [
        ws
        for ws_dir in VSCODE_STORAGE_DIR.iterdir()
        if (ws := _try_build_workspace(ws_dir)) is not None
    ]


class VSCodeConversationMeta(BaseModel):
    """Metadata for a VSCode Augment conversation."""

    conversation_id: str = Field(alias="conversationId")
    last_updated: int = Field(alias="lastUpdated")
    # Support both old format (itemCount) and new format (totalExchanges)
    item_count: int = Field(default=0, alias="itemCount")
    total_exchanges: int = Field(default=0, alias="totalExchanges")
    has_exchanges: bool = Field(default=True, alias="hasExchanges")
    workspace_hash: str = ""
    workspace_path: str = ""
    # Track which storage format this conversation uses
    storage_format: str = "legacy"  # "legacy" or "exchange"

    model_config = ConfigDict(populate_by_name=True)

    @property
    def exchange_count(self) -> int:
        """Get exchange count from either format."""
        return self.total_exchanges or self.item_count

    @property
    def last_updated_dt(self) -> datetime:
        """Convert millisecond timestamp to datetime."""
        return datetime.fromtimestamp(self.last_updated / 1000, tz=UTC)


def _detect_storage_format(key_str: str) -> str | None:
    """Detect the storage format from a LevelDB key string."""
    if key_str.startswith("history-metadata:"):
        return "legacy"
    if key_str.startswith("metadata:"):
        return "exchange"
    return None


def _try_parse_conversation_meta(
    key: bytes, value: bytes, ws: VSCodeWorkspace
) -> VSCodeConversationMeta | None:
    """Parse a conversation metadata entry, returning None if invalid."""
    key_str = key.decode("utf-8", errors="replace")
    storage_format = _detect_storage_format(key_str)
    if not storage_format:
        return None
    try:
        meta = VSCodeConversationMeta.model_validate_json(value)
    except (json.JSONDecodeError, ValueError):
        return None
    meta.workspace_hash = ws.hash
    meta.workspace_path = ws.path
    meta.storage_format = storage_format
    return meta


def _list_conversations_from_workspace(
    ws: VSCodeWorkspace,
) -> list[VSCodeConversationMeta]:
    """List all conversations from a single workspace."""
    try:
        db = plyvel.DB(str(ws.db_path), create_if_missing=False)
    except (OSError, plyvel.Error):
        return []

    conversations: list[VSCodeConversationMeta] = []
    try:
        for key, value in db:
            meta = _try_parse_conversation_meta(key, value, ws)
            if meta:
                conversations.append(meta)
    finally:
        db.close()
    return conversations


def list_vscode_conversations(
    workspace_hash: str | None = None,
) -> list[VSCodeConversationMeta]:
    """
    List all conversations in VSCode workspaces.

    Handles both legacy format (history-metadata:) and new format (metadata:).

    Args:
        workspace_hash: Optional filter by specific workspace hash

    Returns:
        List of conversation metadata objects

    """
    workspaces = list_vscode_workspaces()
    if workspace_hash:
        workspaces = [w for w in workspaces if w.hash == workspace_hash]

    conversations: list[VSCodeConversationMeta] = []
    for ws in workspaces:
        conversations.extend(_list_conversations_from_workspace(ws))
    return conversations


def _convert_vscode_nodes_to_response_nodes(
    structured_nodes: list[dict[str, Any]],
) -> list[ResponseNode]:
    """Convert VSCode structured_output_nodes to CLI ResponseNode format."""
    result: list[ResponseNode] = []
    for node in structured_nodes:
        tool_use = None
        if node.get("tool_use"):
            tu = node["tool_use"]
            tool_use = ToolUse(
                tool_use_id=tu.get("tool_use_id", ""),
                tool_name=tu.get("tool_name", ""),
                input_json=tu.get("input_json", "{}"),
                is_partial=tu.get("is_partial", False),
            )

        thinking = None
        if node.get("thinking"):
            th = node["thinking"]
            if isinstance(th, str):
                thinking = th
            elif isinstance(th, dict):
                thinking = ThinkingContent(
                    summary=th.get("summary", ""),
                    content=th.get("content"),
                    encrypted_content=th.get("encrypted_content"),
                )

        result.append(
            ResponseNode(
                id=node.get("id", 0),
                type=node.get("type", 0),
                content=node.get("content", ""),
                tool_use=tool_use,
                thinking=thinking,
            )
        )
    return result


def _parse_timestamp(ts_raw: Any) -> datetime | None:
    """Parse a timestamp that may be int (ms) or ISO string."""
    if not ts_raw:
        return None
    if isinstance(ts_raw, str):
        # ISO format string (e.g., "2025-10-14T16:50:18.475Z")
        # Replace Z with +00:00 for fromisoformat compatibility
        iso_str = ts_raw
        if iso_str.endswith("Z"):
            iso_str = iso_str[:-1] + "+00:00"
        return datetime.fromisoformat(iso_str)
    # Millisecond timestamp (int or float)
    return datetime.fromtimestamp(ts_raw / 1000, tz=UTC)


def _build_exchange_from_vscode_item(
    item: dict[str, Any],
    sequence: int,
    request_nodes_key: str = "request_nodes",
    response_nodes_key: str = "response_nodes",
) -> Exchange | None:
    """
    Build an Exchange from a VSCode item (works for both legacy and exchange formats).

    Args:
        item: The raw item dict from LevelDB
        sequence: Sequence number for ordering
        request_nodes_key: Key for request nodes (differs between formats)
        response_nodes_key: Key for response nodes (differs between formats)

    Returns:
        Exchange object or None if item should be skipped

    """
    # Skip non-exchange items (checkpoints, etc.)
    if item.get("chatItemType") == "agentic-checkpoint-delimiter":
        return None

    # Build request nodes
    request_nodes: list[RequestNode] = [
        RequestNode(
            id=node.get("id", 0),
            type=node.get("type", 0),
            text_node=node.get("text_node"),
            ide_state_node=node.get("ide_state_node"),
            tool_result_node=node.get("tool_result_node"),
        )
        for node in item.get(request_nodes_key, [])
    ]

    response_nodes = _convert_vscode_nodes_to_response_nodes(
        item.get(response_nodes_key, [])
    )

    exchange_data = ExchangeData(
        request_message=item.get("request_message", ""),
        response_text=item.get("response_text", "") or "",
        request_id=item.get("request_id", item.get("uuid", "")),
        request_nodes=request_nodes,
        response_nodes=response_nodes,
    )

    finished_at = _parse_timestamp(item.get("timestamp"))

    return Exchange(
        exchange=exchange_data,
        completed=item.get("status") == "success",
        sequenceId=float(sequence),
        finishedAt=finished_at,
        changedFiles=[],
    )


def _convert_vscode_item_to_exchange(
    item: dict[str, Any], sequence: int
) -> Exchange | None:
    """Convert a VSCode legacy chat history item to CLI Exchange format."""
    return _build_exchange_from_vscode_item(
        item,
        sequence,
        request_nodes_key="structured_request_nodes",
        response_nodes_key="structured_output_nodes",
    )


def _load_vscode_session_legacy(
    db: Any, conversation_id: str
) -> tuple[list[Exchange], datetime]:
    """Load session using legacy format (history: keys with chatHistoryJson)."""
    key = f"history:{conversation_id}".encode()
    value = db.get(key)
    if not value:
        msg = f"Conversation not found: {conversation_id}"
        raise FileNotFoundError(msg)

    data = json.loads(value.decode())
    chat_history_raw = json.loads(data.get("chatHistoryJson", "[]"))

    # Get metadata for timestamps
    meta_key = f"history-metadata:{conversation_id}".encode()
    meta_value = db.get(meta_key)
    last_updated = datetime.now(tz=UTC)
    if meta_value:
        meta = json.loads(meta_value.decode())
        ts_ms = meta.get("lastUpdated", 0) / 1000
        last_updated = datetime.fromtimestamp(ts_ms, tz=UTC)

    # Convert items to exchanges
    exchanges: list[Exchange] = []
    seq = 0
    for item in chat_history_raw:
        exchange = _convert_vscode_item_to_exchange(item, seq)
        if exchange:
            exchanges.append(exchange)
            seq += 1

    return exchanges, last_updated


def _load_vscode_session_exchange(
    db: Any, conversation_id: str
) -> tuple[list[Exchange], datetime]:
    """Load session using new format (exchange: keys, one per exchange)."""
    # Get metadata first
    meta_key = f"metadata:{conversation_id}".encode()
    meta_value = db.get(meta_key)
    last_updated = datetime.now(tz=UTC)
    if meta_value:
        meta = json.loads(meta_value.decode())
        ts_ms = meta.get("lastUpdated", 0) / 1000
        last_updated = datetime.fromtimestamp(ts_ms, tz=UTC)

    # Collect all exchange keys for this conversation
    prefix = f"exchange:{conversation_id}:".encode()
    exchange_items: list[dict[str, Any]] = []

    for key, value in db.iterator(prefix=prefix):
        key_str = key.decode()
        # Skip temp exchanges (in-progress frontend state)
        is_temp = "temp-fe" in key_str
        if not is_temp:
            try:
                item = json.loads(value.decode())
                exchange_items.append(item)
            except json.JSONDecodeError:
                pass  # Skip invalid entries

    # Sort by timestamp (ISO string format works with string sorting)
    exchange_items.sort(key=lambda x: x.get("timestamp", "") or "")

    # Convert to Exchange objects
    exchanges: list[Exchange] = []
    for seq, item in enumerate(exchange_items):
        exchange = _convert_vscode_exchange_item(item, seq)
        if exchange:
            exchanges.append(exchange)

    return exchanges, last_updated


def _convert_vscode_exchange_item(
    item: dict[str, Any], sequence: int
) -> Exchange | None:
    """Convert a VSCode exchange-format item to CLI Exchange format."""
    return _build_exchange_from_vscode_item(
        item,
        sequence,
        request_nodes_key="request_nodes",
        response_nodes_key="response_nodes",
    )


def load_vscode_session(workspace_hash: str, conversation_id: str) -> Session:
    """
    Load a VSCode conversation and convert to Session format.

    Handles both legacy (history:) and new (exchange:) formats.

    Args:
        workspace_hash: The workspace hash (directory name in workspaceStorage)
        conversation_id: The conversation UUID

    Returns:
        Session object compatible with CLI sessions

    Raises:
        FileNotFoundError: If workspace or conversation not found
        ValueError: If conversation data is invalid

    """
    db_path = (
        VSCODE_STORAGE_DIR
        / workspace_hash
        / "Augment.vscode-augment"
        / "augment-kv-store"
    )
    if not db_path.exists():
        msg = f"Workspace not found: {workspace_hash}"
        raise FileNotFoundError(msg)

    db = plyvel.DB(str(db_path), create_if_missing=False)
    try:
        # Try legacy format first (history: key)
        legacy_key = f"history:{conversation_id}".encode()
        if db.get(legacy_key):
            exchanges, last_updated = _load_vscode_session_legacy(db, conversation_id)
        else:
            # Try new exchange format (metadata: + exchange: keys)
            meta_key = f"metadata:{conversation_id}".encode()
            if db.get(meta_key):
                exchanges, last_updated = _load_vscode_session_exchange(
                    db, conversation_id
                )
            else:
                msg = f"Conversation not found: {conversation_id}"
                raise FileNotFoundError(msg)

        # Determine created time from first exchange
        created = last_updated
        if exchanges and exchanges[0].finished_at:
            created = exchanges[0].finished_at

        return Session(
            sessionId=conversation_id,
            created=created,
            modified=last_updated,
            chatHistory=exchanges,
            agentState=None,
            rootTaskUuid=None,
        )

    finally:
        db.close()


def _try_load_vscode_session(
    conv: VSCodeConversationMeta,
) -> Session | None:
    """Attempt to load a VSCode session, returning None on failure."""
    try:
        return load_vscode_session(conv.workspace_hash, conv.conversation_id)
    except (FileNotFoundError, ValueError, json.JSONDecodeError):
        return None


def load_all_vscode_sessions(workspace_hash: str | None = None) -> list[Session]:
    """
    Load all VSCode sessions, optionally filtered by workspace.

    Args:
        workspace_hash: Optional workspace hash to filter by

    Returns:
        List of Session objects

    """
    conversations = list_vscode_conversations(workspace_hash)
    return [
        session
        for conv in conversations
        if (session := _try_load_vscode_session(conv)) is not None
    ]


# =============================================================================
# CLI Models
# =============================================================================


class ListCmd(BaseModel):
    """List recent sessions."""

    json_output: bool = Field(default=False, alias="json", description="Output as JSON")
    since: int = Field(default=30, description="Days to look back")
    source: str = Field(
        default="cli",
        description="Source: 'cli', 'vscode', or 'all'",
    )
    workspace: str | None = Field(
        default=None,
        description="VSCode workspace hash (for source=vscode)",
    )

    model_config = ConfigDict(populate_by_name=True)


class ShowCmd(BaseModel):
    """Show formatted session log."""

    session_id: str = Field(description="Session ID to display")
    workspace: str | None = Field(
        default=None,
        description="VSCode workspace hash (required for VSCode sessions)",
    )


class WorkspacesCmd(BaseModel):
    """List VSCode workspaces with Augment data."""

    json_output: bool = Field(default=False, alias="json", description="Output as JSON")

    model_config = ConfigDict(populate_by_name=True)


class AuglogCLI(BaseModel):
    """Auglog - Session loading and formatting for Augment CLI sessions."""

    list: CliSubCommand[ListCmd]
    show: CliSubCommand[ShowCmd]
    workspaces: CliSubCommand[WorkspacesCmd]


# =============================================================================
# CLI Implementation
# =============================================================================


def _run_list(cmd: ListCmd) -> int:
    """Execute list command."""
    sessions: list[Session] = []

    # Collect sessions from requested sources
    if cmd.source in ("cli", "all"):
        sessions.extend(load_all())

    if cmd.source in ("vscode", "all"):
        sessions.extend(load_all_vscode_sessions(cmd.workspace))

    # Filter by date using local timezone for consistency
    cutoff = datetime.now(tz=datetime.now().astimezone().tzinfo).timestamp() - (
        cmd.since * 86400
    )
    recent = [s for s in sessions if s.created.timestamp() > cutoff]
    # Sort by date descending
    recent.sort(key=lambda s: s.created, reverse=True)

    if cmd.json_output:
        output = [
            {
                "id": s.session_id,
                "created": s.created.isoformat(),
                "title": s.title,
                "exchanges": s.exchange_count,
            }
            for s in recent
        ]
        # CLI output is intentional
        print(json.dumps(output, indent=2))  # noqa: T201
    else:
        for s in recent:
            date_str = s.created.strftime("%Y-%m-%d %H:%M")
            # CLI output is intentional
            print(f"{s.session_id[:8]}  {date_str}  {s.title[:60]}")  # noqa: T201

    return 0


def _run_show(cmd: ShowCmd) -> int:
    """Execute show command."""
    session_id = cmd.session_id

    # If workspace is specified, load from VSCode
    if cmd.workspace:
        try:
            session = load_vscode_session(cmd.workspace, session_id)
        except FileNotFoundError:
            # CLI error output is intentional
            msg = f"Session not found: {session_id} in workspace {cmd.workspace}"
            print(msg, file=sys.stderr)  # noqa: T201
            return 1
        else:
            # CLI output is intentional
            print(session.format_log())  # noqa: T201
            return 0

    # Otherwise, try CLI sessions with partial ID matching
    matches = [sid for sid in list_all() if sid.startswith(session_id)]

    if not matches:
        # CLI error output is intentional
        print(f"Session not found: {session_id}", file=sys.stderr)  # noqa: T201
        return 1
    if len(matches) > 1:
        # CLI error output is intentional
        print(f"Ambiguous session ID: {session_id}", file=sys.stderr)  # noqa: T201
        for match in matches[:5]:
            print(f"  {match}", file=sys.stderr)  # noqa: T201
        return 1

    try:
        session = load(matches[0])
    except FileNotFoundError:
        # CLI error output is intentional
        print(f"Session not found: {session_id}", file=sys.stderr)  # noqa: T201
        return 1

    # CLI output is intentional
    print(session.format_log())  # noqa: T201
    return 0


def _run_workspaces(cmd: WorkspacesCmd) -> int:
    """Execute workspaces command."""
    workspaces = list_vscode_workspaces()

    if cmd.json_output:
        output = [
            {
                "hash": ws.hash,
                "path": ws.path,
            }
            for ws in workspaces
        ]
        # CLI output is intentional
        print(json.dumps(output, indent=2))  # noqa: T201
    else:
        for ws in workspaces:
            # CLI output is intentional
            print(f"{ws.hash[:12]}  {ws.path}")  # noqa: T201

    return 0


def main() -> int:
    """CLI entry point."""
    cli = CliApp.run(AuglogCLI)
    if cli.list:
        return _run_list(cli.list)
    if cli.show:
        return _run_show(cli.show)
    if cli.workspaces:
        return _run_workspaces(cli.workspaces)
    return 0


if __name__ == "__main__":
    sys.exit(main())
