---
type: always_apply
priority: CRITICAL
description: Require all GitHub operations to use GitHub MCP tools or gh CLI, including when given URLs
last_updated: 2026-02-25
---

# GitHub Operations Must Use MCP Server or gh CLI

## CRITICAL: Parse GitHub URLs, Use MCP Tools

**When given a GitHub URL, ALWAYS parse it and use the appropriate GitHub MCP
tool or gh CLI command.
NEVER use `web-fetch` for GitHub URLs.**

GitHub URLs contain structured information that maps directly to MCP tool
parameters:

| URL Pattern | Extract | MCP Tool |
|-------------|---------|----------|
| `github.com/{owner}/{repo}/pull/{number}` | owner, repo, number | `pull_request_read_github` |
| `github.com/{owner}/{repo}/issues/{number}` | owner, repo, number | `issue_read_github` |
| `github.com/{owner}/{repo}/actions/runs/{run_id}` | owner, repo, run_id | `gh run view` (CLI) |
| `github.com/{owner}/{repo}/actions/runs/{run_id}/job/{job_id}` | owner, repo, run_id, job_id | `gh run view --job` (CLI) |
| `github.com/{owner}/{repo}/commit/{sha}` | owner, repo, sha | `get_commit_github` |
| `github.com/{owner}/{repo}/blob/{ref}/{path}` | owner, repo, ref, path | `get_file_contents_github` |
| `github.com/{owner}/{repo}/releases/tag/{tag}` | owner, repo, tag | `get_release_by_tag_github` |

## URL Parsing Examples

```text
URL: https://github.com/imprivata-ai/workstation-clustering/pull/42
  → owner: imprivata-ai
  → repo: workstation-clustering
  → pull_number: 42
  → Tool: pull_request_read_github(owner, repo, pullNumber, method="get")

URL: https://github.com/imprivata-ai/workstation-clustering/actions/runs/22417547293/job/64906950212
  → owner: imprivata-ai
  → repo: workstation-clustering
  → run_id: 22417547293
  → job_id: 64906950212
  → Command: gh run view 22417547293 --repo imprivata-ai/workstation-clustering --job 64906950212
```

## GitHub Actions Workflow Runs

The GitHub MCP server does not have tools for viewing workflow runs or job logs.
**Use the `gh` CLI as a fallback:**

```bash
# View workflow run summary
gh run view {run_id} --repo {owner}/{repo}

# View specific job logs
gh run view {run_id} --repo {owner}/{repo} --job {job_id} --log

# View failed job logs only
gh run view {run_id} --repo {owner}/{repo} --job {job_id} --log-failed
```

## Tool Selection Priority

1. **GitHub MCP tools** (`*_github` suffix) - preferred for structured data
2. **gh CLI** - fallback for operations not covered by MCP (workflow runs, job
   logs)
3. **web-fetch** - NEVER use for GitHub URLs

## Why web-fetch Fails for GitHub

- Returns HTML, not structured data
- Bypasses authentication
- Cannot access private repositories
- Does not provide API-level detail (diffs, logs, comments)

## Cross-Reference

Related rules:

- `core-development-rules.md` - GitHub API Operations section
- `git-mcp-required.md` - Similar pattern for git operations

Related skills:

- `github-workflow` - Detailed tool usage for GitHub operations
