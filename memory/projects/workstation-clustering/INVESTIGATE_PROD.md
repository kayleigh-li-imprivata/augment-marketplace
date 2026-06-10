# Investigate Prod -- Workstation Clustering

Step-by-step checklist for diagnosing the workstation-clustering pipeline in
prod.
Triggered by phrases like "investigate prod", "check prod", "diagnose prod
pipeline", "is prod running" (see `plugins/core/rules/agent-triggers.md`).

## Phase 1 -- Preflight

Run the standard preflight from
`memory/global/artifacts/tooling/ai-env-access.md` targeting **prod**:

- `aws sts get-caller-identity` → expect `439323037767` / `AI-Developer`
- `kubectl config current-context` → expect
  `arn:aws:eks:us-east-2:439323037767:cluster/ai-prod`
- sshuttle running against **`ai-prod-jumpbox-proxy`** (NOT `ai-jumpbox-proxy`
  -- that one is non-prod)
- `timeout 8 kubectl get ns workstation-clustering` returns quickly

If any step fails, fix it via `ai-env-access.md` before continuing.

## Phase 2 -- Tenant Inventory

Source of truth:
`infra/helm/workstation-clustering/values.prod.yaml`.

Known prod tenants → `client_id`:

| Tenant | client_id | S3 bucket prefix |
|--------|-----------|------------------|
| El Camino | `181568` | `rq65tlstn75qg-prd` |
| Imprivata Inc | `10566` | (verify in values.prod.yaml) |
| (third tenant) | (in values.prod.yaml) | `lzfrakl35co3y-prd` |
| (fourth tenant) | (in values.prod.yaml) | `yhj3m33p2bgpw-prd` |

Always enumerate ALL tenants before drawing conclusions -- don't assume the
tenant the user asked about is the one with the problem.

## Phase 3 -- Pipeline State Queries

```bash
# All CronWorkflows: schedule, suspended flag, last scheduled time
kubectl get cronworkflow -n workstation-clustering \
  -o custom-columns='NAME:.metadata.name,SCHEDULE:.spec.schedule,SUSPEND:.spec.suspend,LAST-SCHED:.status.lastScheduledTime,ACTIVE:.status.active'

# Recent workflows across all tenants, sorted by time
kubectl get workflow -n workstation-clustering \
  --sort-by=.metadata.creationTimestamp | tail -30

# Per-tenant workflow history
kubectl get workflow -n workstation-clustering \
  --sort-by=.metadata.creationTimestamp | grep <client_id>

# Failed-workflow detail
kubectl get wf <name> -n workstation-clustering -o yaml | yq '.status.message, .status.nodes'
```

Workflow name patterns:

- `wc-daily-update-cron-{client_id}-*` -- daily update (cron at `0 5 * * *` UTC
  = 01:00 EDT)
- `wc-base-train-{client_id}-*` -- initial training (one-off; produces original
  cluster names)
- `wc-rename-clusters-{client_id}-*` -- one-off rename (manual; needed to apply
  new naming logic to existing clusters)

## Phase 4 -- Deployed Image / Version

```bash
# Currently deployed image per workload
kubectl get deploy,sts -n workstation-clustering \
  -o custom-columns='KIND:.kind,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,CREATED:.metadata.creationTimestamp'

# Image transitions (when each version rolled out)
kubectl get rs -n workstation-clustering \
  -o custom-columns='NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,CREATED:.metadata.creationTimestamp,DESIRED:.spec.replicas' \
  --sort-by=.metadata.creationTimestamp
```

**Release lives under ArgoCD, not direct helm.** `helm list -A` will not find
it.
Use:

```bash
kubectl get applications.argoproj.io -A | grep workstation
kubectl describe application.argoproj.io <name> -n argocd
```

ECR registry for image tags:
`439323037767.dkr.ecr.us-east-2.amazonaws.com/workstation-clustering`.

## Phase 5 -- S3 Model Artifact Verification

Profile:
`icp-datalayer-prod` (account `582974859345`, region `us-east-1`).

Path pattern:
`s3://<tenant-bucket>/data-layer/machine-learning/workstation_clustering/models/<YYYY-MM-DD>/`

```bash
# Recent model dates
aws --profile icp-datalayer-prod s3 ls \
  s3://<bucket>/data-layer/machine-learning/workstation_clustering/models/ | tail -10

# Files for a given date
aws --profile icp-datalayer-prod s3 ls \
  s3://<bucket>/data-layer/machine-learning/workstation_clustering/models/<date>/

# Inspect a JSON artifact (download first; piping large files via `cp -` can timeout)
aws --profile icp-datalayer-prod s3 cp \
  s3://<bucket>/.../users_dto.json /tmp/users_dto.json
jq '.[0] // (to_entries | .[0])' /tmp/users_dto.json
```

Key files in each dated model dir:
`cluster_names.json`, `clusters_dto.json`, `users_dto.json`.

## Phase 6 -- Common Wrong Inferences

- **Cluster-name FORMAT does not prove new naming LOGIC is active.** Both old
  (event-based) and new (distinct-user-based) logic produce names of the form
  `"DEPT NAME @LOC_N"`.
  Only the selection rule differs.
  To confirm new logic ran for a tenant, look for a
  `wc-rename-clusters-{client_id}-*` workflow whose start time is **after** the
  image carrying the new logic was deployed.
- **Daily updates do NOT rename clusters.** They update affinities only.
  Existing `display_name`s persist from whatever workflow named them (usually
  the base-train).
- **DS cron timing is not downstream API timing.** Cron runs at 05:00 UTC.
  API hits at other times = downstream consumer polling, not the pipeline
  itself.
- **Tenant ID is NOT in the consumer API access log.** A report of "I see 1
  client hitting the API daily" without tenant correlation cannot be
  attributed to a specific tenant -- cross-reference S3 artifact landings +
  cron statuses to figure out which tenants are healthy end-to-end.
- **Healthy CronWorkflow for tenant X does not mean all tenants are healthy.**
  Always enumerate all four.
- **`helm list` not finding the release does not mean it is not deployed.**
  ArgoCD owns it.

## Phase 7 -- Where is the Problem?

| Symptom | Likely cause | Next step |
|---------|--------------|-----------|
| CronWorkflow suspended or missing | infra/gitops | Check `applications.argoproj.io` and Helm values |
| Cron present, recent runs `Failed` | pipeline-internal | `kubectl get wf <name> -o yaml` → `.status.message`, failing node |
| Cron `Succeeded` but no fresh S3 date | empty Iceberg source, or skipped step | Check workflow logs for "no data" / skip messages |
| S3 fresh but downstream stale | consumer issue, NOT pipeline | Hand off to consumer team |
| Names look wrong but pipeline healthy | missing `wc-rename-clusters-{client_id}` run | Manually trigger the rename workflow |

## Pinned Reference

- Prod EKS:
  account `439323037767` (`ai-prod`), region `us-east-2`
- Prod tenant data lake:
  account `582974859345` (`icp-datalayer-prod`), region `us-east-1`
- ECR registry:
  `439323037767.dkr.ecr.us-east-2.amazonaws.com/workstation-clustering`
- Namespace:
  `workstation-clustering`
- Prod jumpbox:
  `ai-prod-jumpbox-proxy` (`~/.ssh/config`)
- DS cron schedule:
  `0 5 * * *` UTC (01:00 EDT)
- Values file with tenant mapping:
  `infra/helm/workstation-clustering/values.prod.yaml`
