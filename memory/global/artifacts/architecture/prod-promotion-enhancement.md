---
title: Prod Promotion Enhancement — Event-Driven ArgoCD Pattern
type: note
tags:
- argocd
- gitops
- github-actions
- deployment-automation
- architecture
permalink: main/artifacts/architecture/prod-promotion-enhancement
---

# Prod Promotion Enhancement — Event-Driven ArgoCD Pattern

## Context

When automating production promotion gating, the instinct is to use GitHub
Actions CI to query the cluster for QA health before allowing prod deployment.
This is blocked by a common infrastructure constraint: the EKS cluster sits in
a private AWS VPC with no public ArgoCD endpoint and no OIDC federation between
GitHub and AWS. GitHub-hosted runners cannot reach the cluster.

The solution is to invert the direction: instead of GitHub pulling status from
the cluster, ArgoCD (which runs inside the cluster) pushes status out to GitHub.

## Decision

Use ArgoCD Notifications with the `github.deployment` notifier to bridge the
private cluster and GitHub Actions via the GitHub Deployment API.

**Optimal flow:**

```
release published
  → deploy-qa.yml creates QA PR in gitops-apps (unchanged)
  → QA PR merged → ArgoCD syncs QA
  → ArgoCD Notifications posts github.deployment (environment: qa, state: success)
  → gitops-apps workflow triggers on: deployment_status (env=qa, state=success)
  → workflow creates prod PR in gitops-apps
  → human reviews and approves → prod PR merged → ArgoCD deploys to prod
```

All new automation lives in `gitops-apps`. The project repo's
`promote-to-prod.yml` is unchanged and becomes the manual/hotfix override path.

## Implementation Prerequisites

ArgoCD's `service.github` notifier requires a GitHub App (not a PAT):
- `appID`, `installationID`, RSA `privateKey`
- Permissions: Deployments write on the target repo
- Existing Slack bots (e.g. `teamaialerts`) cannot be reused — they are Slack
  OAuth apps, not GitHub Apps

Steps to enable:
1. Create GitHub App in org with `deployments: write`
2. Install on `gitops-apps`
3. Store private key in `argocd-notifications-secret` (alongside `slack-token`)
4. Add `service.github` to `argocd-values.yaml`
5. Add `github.deployment` template + trigger to `argocd-values.yaml`
6. Add subscription annotation to the ArgoCD Application manifest

## Alternatives Considered

**❌ `github.checkRun` / `github.status`** — Both target a specific commit SHA.
The QA merge commit SHA ≠ the prod PR head SHA. The health signal cannot
natively gate the prod PR without a relay job that re-posts to the prod SHA.

**❌ Simultaneous QA + prod PRs** — Same SHA mismatch problem: ArgoCD posts its
health check against the QA merge commit, which is a different commit than the
prod PR branch head. Adds complexity for no benefit over sequential flow.

**❌ GitHub Actions querying the cluster directly** — Impossible without either
self-hosted runners inside the VPC or a public ArgoCD endpoint + OIDC trust
relationship. Neither exists in this setup.

**❌ workstation-clustering CI gating prod PR** — Requires AWS OIDC + kubeconfig
in the project repo workflow, violates the principle that cluster-facing checks
belong in the gitops repo, and adds credential surface area.

## Consequences

- `gitops-apps` must gain a GitHub Actions workflow for the first time
- One new GitHub App needed per org (not per project — reusable across projects)
- Prod PR creation becomes automatic; human gate is only the final merge approval
- ArgoCD Notifications must be re-deployed after config changes (not self-managed)
- Training workflow validation (Argo Workflows) is out of scope — those run
  entirely in-cluster with no native GitHub status reporting

## Observations

- [constraint] EKS private VPC blocks all inbound access from GitHub runners — cluster must initiate outbound calls to GitHub #aws #networking
- [decision] github.deployment API used as async bridge between private cluster and GitHub — avoids SHA mismatch of checkRun/status #argocd #gitops
- [decision] Sequential PR flow (QA first, prod after deployment_status success) eliminates need for redundant QA re-check in prod PR CI #automation
- [pattern] Invert the pull model: ArgoCD pushes status to GitHub rather than GitHub pulling from cluster #event-driven
- [constraint] ArgoCD service.github requires GitHub App (appID + RSA key), not OAuth token — existing Slack bots are not reusable #github-app
- [tradeoff] All prod-promotion automation moved to gitops-apps; project repo promote-to-prod.yml becomes manual override only #separation-of-concerns

## Relations

- relates-to [[argocd-notifications]]
- relates-to [[gitops-private-cluster]]
- implements [[prod-promotion-automation]]