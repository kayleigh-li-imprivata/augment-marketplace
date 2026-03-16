---
name: github-workflow
description: Use when interacting with GitHub - PRs, issues, CI status, releases, search, and write operations via the GitHub MCP server
---

# GitHub Workflow

Use the GitHub MCP server tools (`*_github` suffix) for all GitHub operations.
Never use `web-fetch` for GitHub resources.

**Configuration:** Server has read-write capabilities.
Read operations are auto-approved; write operations prompt for user approval.

## When to Use

Use this skill when:

- Listing or viewing pull requests
- Reading GitHub issues
- Checking CI/CD status
- Viewing releases
- Searching GitHub (code, issues, PRs, commits, users, repos)

## Tool Selection

| Operation | Tool | Notes |
|-----------|------|-------|
| GitHub read operations | `*_github` MCP tools | Auto-approved |
| GitHub write operations | `*_github` MCP tools | Requires user approval |
| Local git operations | `git_*` MCP tools | See git-workflow rules |
| `web-fetch` on GitHub | Never | Bypasses auth, returns HTML |

## Available Read Operations

### Pull Requests

| Tool | Purpose |
|------|---------|
| `list_pull_requests_github` | List PRs with filters (state, base, head) |
| `pull_request_read_github` | Get PR details, diff, files, reviews, comments |
| `search_pull_requests_github` | Search PRs with query syntax |

### Issues

| Tool | Purpose |
|------|---------|
| `list_issues_github` | List issues with filters |
| `issue_read_github` | Get issue details, comments, labels, sub-issues |
| `search_issues_github` | Search issues with query syntax |

### Repository

| Tool | Purpose |
|------|---------|
| `get_file_contents_github` | Get file or directory contents |
| `list_branches_github` | List branches |
| `list_commits_github` | List commits with filters |
| `get_commit_github` | Get commit details with diff |
| `search_code_github` | Search code across repos |
| `search_repositories_github` | Find repositories |

### Releases and Tags

| Tool | Purpose |
|------|---------|
| `list_releases_github` | List releases |
| `get_latest_release_github` | Get latest release |
| `get_release_by_tag_github` | Get release by tag |
| `list_tags_github` | List tags |
| `get_tag_github` | Get tag details |

### Users and Teams

| Tool | Purpose |
|------|---------|
| `get_me_github` | Get authenticated user info |
| `search_users_github` | Search users |
| `get_teams_github` | Get user's teams |
| `get_team_members_github` | Get team members |

## Write Operations (Approval Required)

The following require user approval when invoked:

- Creating/merging PRs (`create_pull_request_github`,
  `merge_pull_request_github`)
- Filing/updating issues (`issue_write_github`)
- Adding comments (`add_issue_comment_github`)
- Creating releases
- Pushing files (`push_files_github`, `create_or_update_file_github`)

When ready to perform a write operation, the tool permission system will prompt
for approval automatically.
