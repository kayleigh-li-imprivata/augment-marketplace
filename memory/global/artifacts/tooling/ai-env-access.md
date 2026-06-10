---
title: AI Environment Access -- SSO, Jumpbox, Kubeconfig
type: note
tags:
- aws
- eks
- sso
- sshuttle
- jumpbox
- access
permalink: main/artifacts/tooling/ai-env-access
---

# AI Environment Access

One-stop reference for authenticating to and reaching any `ai-*` EKS cluster and
its associated AWS accounts (dev, qa, sandbox, prod).

## Account & Cluster Matrix

All EKS clusters live in app account `439323037767`, region `us-east-2`.

| Env | EKS context | Jumpbox | Tenant data lake account |
|-----|-------------|---------|--------------------------|
| dev | `arn:aws:eks:us-east-2:439323037767:cluster/ai-dev` | `ai-jumpbox-proxy` (3.14.63.94) | `702767219569` (non-prod) |
| qa | `arn:aws:eks:us-east-2:439323037767:cluster/ai-qa` | `ai-jumpbox-proxy` (3.14.63.94) | `702767219569` (non-prod) |
| sandbox | `arn:aws:eks:us-east-2:439323037767:cluster/ai-sandbox` | `ai-jumpbox-proxy` (3.14.63.94) | `702767219569` (non-prod) |
| prod | `arn:aws:eks:us-east-2:439323037767:cluster/ai-prod` | `ai-prod-jumpbox-proxy` (3.22.35.100) | `582974859345` (prod) -- profile `icp-datalayer-prod` |

**Key fact:** dev/qa/sandbox share `ai-jumpbox-proxy`; **prod uses a separate
jumpbox** (`ai-prod-jumpbox-proxy`).
One sshuttle session reaches one jumpbox -- to switch envs you must kill and
restart it.

The non-prod data account (`702767219569`) is referenced in
`infra/helm/workstation-clustering/values.{dev,qa}.yaml` as `role_arn:
arn:aws:iam::702767219569:role/{dev,integration}-workstation-clustering-icp-access-role`.
Prod equivalent in `values.prod.yaml`:
`arn:aws:iam::582974859345:role/prod-workstation-clustering-icp-access-role`.

## AWS SSO

- Session name:
  `imprivata`
- Default profile → account `439323037767`, role `AI-Developer`, region
  `us-east-2` (the EKS clusters)
- Profile `icp-datalayer-prod` → account `582974859345`, role
  `DataPlatform-Developer-Prod`, region `us-east-1` (prod tenant data lake)
- Profile `bedrock-dev` → account `787222310730`, role `AdministratorAccess`
- Login:
  `aws sso login` (refreshes every profile bound to the `imprivata` session)
- Verify default:
  `aws sts get-caller-identity` → expect `439323037767` / `AI-Developer`
- Verify data-lake:
  `aws --profile icp-datalayer-prod sts get-caller-identity`

## Network Path to Private API Server

EKS API servers are private; `kubectl` hangs without a tunnel.

**Option A -- VPN (preferred for routine work):** GlobalProtect → US Eng Full
Tunnel VPN.
Reaches all envs.

**Option B -- sshuttle (per env):**

```bash
# Non-prod (dev / qa / sandbox)
sshuttle -r ai-jumpbox-proxy 10.0.0.0/8

# Prod
sshuttle -r ai-prod-jumpbox-proxy 10.0.0.0/8
```

Leave terminal open.
Only one at a time.

One-time SSH config (already in `~/.ssh/config`):

```
Host ai-jumpbox-proxy        # HostName 3.14.63.94  -- non-prod
Host ai-prod-jumpbox-proxy   # HostName 3.22.35.100 -- prod
```

Jumpbox SG must allow your current public IP (Console → EC2 → Security
Groups → `ai-nonprod-ec2-jumpbox-sg` for non-prod; the prod equivalent for
prod).

## Kubeconfig

Contexts already exist for all four clusters.
To add a missing one:

```bash
aws eks update-kubeconfig --region us-east-2 --name ai-<env>
```

Switch context:

```bash
kubectl config use-context arn:aws:eks:us-east-2:439323037767:cluster/ai-<env>
```

## Standard Preflight (before any env work)

```bash
# 1. SSO valid?
aws sts get-caller-identity                  # expect 439323037767 / AI-Developer

# 2. Right context?
kubectl config current-context               # expect ai-<env>

# 3. Tunnel up + correct jumpbox for this env?
timeout 8 kubectl get ns                     # expect quick response, not exit=124
```

If all three pass, proceed.

## Failure-Mode Decision Tree

| Symptom | Cause | Fix |
|---------|-------|-----|
| `kubectl` hangs ≥8s | No network path | Bring up VPN, or sshuttle to the correct jumpbox for that env |
| `kubectl` works for dev but hangs for prod | sshuttle pointed at non-prod jumpbox | Kill, restart with `ai-prod-jumpbox-proxy` |
| `error: You must be logged in to the server (Unauthorized)` | SSO expired | `aws sso login` |
| `aws sts get-caller-identity` fails | SSO expired | `aws sso login` |
| `AccessDenied` on S3 against tenant bucket | Wrong profile | Add `--profile icp-datalayer-prod` for prod, or the non-prod equivalent for dev/qa |
| ECR image pull fails locally | ECR login expired | Re-run the ECR `get-login-password` / `docker login` sequence (see ECR section) |

## ECR Registry

`439323037767.dkr.ecr.us-east-2.amazonaws.com` (same account as EKS).

Login command:

```bash
aws ecr get-login-password --region us-east-2 \
  | docker login --username AWS --password-stdin 439323037767.dkr.ecr.us-east-2.amazonaws.com
```
