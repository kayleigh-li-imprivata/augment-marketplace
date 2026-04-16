---
title: Grafana MCP Setup — AWS Managed Grafana
type: note
tags:
- grafana
- mcp
- observability
- aws
- sshuttle
permalink: main/artifacts/tooling/grafana-mcp-setup
---

# Grafana MCP Setup — AWS Managed Grafana

## Context

The team uses AWS Managed Grafana (`ai-prod-amg`, workspace ID `g-d364abe43b`)
in `us-east-2`. The workspace is in a private VPC and only allows AWS SSO for
browser login. Programmatic access via the `observability` plugin requires
specific setup.

## What Works

- **Token type:** Grafana service account token (`glsa_*`) created inside
  Grafana under Administration → Service Accounts (`kayleigh-sa`, ID 25)
- **MCP package:** `uvx mcp-grafana` (Go binary) — NOT `npx @grafana/mcp-grafana`
- **Env var:** `GRAFANA_SERVICE_ACCOUNT_TOKEN` — NOT the deprecated `GRAFANA_API_KEY`
- **Network:** `sshuttle` tunnel via `ai-jumpbox-proxy` must be running
- **Token expiry:** Tokens expire — regenerate monthly at Grafana → Administration → Service Accounts

## Required Setup Per Session

1. Start sshuttle tunnel (keep running in a separate terminal):
   ```bash
   sshuttle -r ai-jumpbox-proxy 10.0.0.0/8
   ```

2. Ensure env vars are set in ~/.bashrc:
   ```bash
   export GRAFANA_URL="https://g-d364abe43b.grafana-workspace.us-east-2.amazonaws.com"
   export GRAFANA_SERVICE_ACCOUNT_TOKEN="glsa_..."
   ```

3. Start auggie in a new terminal (so it picks up the env vars):
   ```bash
   source ~/.bashrc
   auggie
   ```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Bad Request: Not allowed from curl | Expected — curl does not work directly; auggie MCP client does | Use auggie, not curl |
| Grafana MCP not initializing | auggie started before env vars were sourced | Restart auggie in a fresh terminal after source ~/.bashrc |
| Token rejected | Token expired | Regenerate at Grafana > Administration > Service Accounts |
| No dashboards returned | sshuttle not running | Start sshuttle -r ai-jumpbox-proxy 10.0.0.0/8 |

## Token Renewal

Current token expires ~2026-05-16. To renew:
1. Go to https://g-d364abe43b.grafana-workspace.us-east-2.amazonaws.com
2. Administration > Service Accounts > kayleigh-sa > Add token
3. Set expiry to 30 days
4. Update GRAFANA_SERVICE_ACCOUNT_TOKEN in ~/.bashrc

## Workspace Details

- Workspace name: ai-prod-amg
- Workspace ID: g-d364abe43b
- Region: us-east-2
- Auth: AWS SSO only (browser login)
- Service account: kayleigh-sa (ID: 25, Admin role)
- Dashboards: 51 across 11 folders (verified working)
