# Sandbox Testing Execution Guide

This guide walks through testing the recent fixes in the sandbox environment:
1. **Overwrite mode artifact wiping fix** (prevents wiping existing artifacts
   when no DTOs found)
2. **Scenario 1 fix** (handles `effective_date=''` with `lookback_days > 0`
   gracefully)
3. **Rename workflow idempotency** (prevents concurrent rename operations per
   client)

## Prerequisites

### 1. VPN/Network Access
Connect to the cluster using one of these methods:

**Option A:
VPN (Recommended)**
```bash
# Connect to US Eng Full Tunnel VPN in GlobalProtect
```

**Option B:
SSH Tunnel via Jumpbox**
```bash
# 1. Start SSH tunnel (keep running in a terminal)
sshuttle -r ai-jumpbox-proxy 10.0.0.0/8
# Success message: "c : Connected to server."

# 2. Verify kubectl access
kubectl get nodes
```

### 2. AWS CLI Access
```bash
# Login to ECR
aws ecr get-login-password --region us-east-2 \
  | docker login --username AWS --password-stdin 439323037767.dkr.ecr.us-east-2.amazonaws.com

# Verify S3 access to OU Medicine bucket
aws s3 ls s3://ou-medicine-15887-dev-ai-data/
```

### 3. Argo Workflows UI Access
```bash
# Port forward to Argo UI
kubectl port-forward -n argo-workflows svc/argo-workflows-server 2746:2746

# Open in browser: http://localhost:2746
```

## Test Execution

### Step 0: Clean Slate (Optional - Start Fresh)
```bash
# WARNING: This deletes all existing models and DTOs!
# Only do this if you want to test from scratch

# Delete base model
aws s3 rm s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/base/ --recursive

# Delete all model DTOs
aws s3 rm s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models/ --recursive
```

### Step 1: Check Available Data
```bash
# Check what data dates are currently available
aws s3 ls s3://ou-medicine-15887-dev-ai-data/raw/sda/inbox/ --recursive | grep "\.parquet" | head -20

# Note the date range - you'll need this for testing
```

### Step 2: Build and Push Image
```bash
# Build and push the image with your changes
skaffold build --push

# Note the TAG from the output (e.g., 439323037767.dkr.ecr.us-east-2.amazonaws.com/workstation-clustering:abc123)
TAG=<tag-from-output>
```

### Step 3: First Update Run - Bootstrap on Existing Data
This tests **Scenario 1 fix** - when `effective_date=''` (all data) with default
`lookback_days=0`.

```bash
# Deploy with update mode (will bootstrap if no base model exists)
helm upgrade workstation-clustering ./infra/helm/workstation-clustering \
  -f infra/helm/workstation-clustering/values.sandbox.yaml \
  -n argo-workflows \
  --set image.tag=$TAG \
  --set workflows.workflowMode=update \
  --set workflows.runCron=false \
  --install

# Watch the workflow in Argo UI
# http://localhost:2746
```

### Step 4: Verify Bootstrap Results
```bash
# Check base model was created
aws s3 ls s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/base/models/

# Check first DTO was created
aws s3 ls s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models/
```

### Step 5: CRITICAL - Verify Lookback Days Fix for Base Training Naming
This verifies that when training on "all data" (`effective_date=''`), the naming
step also uses "all data" (not just the last day).

```bash
# Get the latest workflow
WORKFLOW_NAME=$(kubectl get workflows -n argo-workflows --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')

# Check the workflow logs for the naming step
kubectl logs -n argo-workflows $WORKFLOW_NAME -c main | grep -A 10 "CLUSTER NAMING"

# Expected output should show:
# "CLUSTER NAMING (INCREMENTAL): effective_date=<resolved-date>, lookback_days=None"
# This confirms naming queried all data through the resolved date (matching training data)
```

**Verify cluster names are representative of all training data:**
```bash
# Get the resolved effective date from the workflow
EFFECTIVE_DATE=$(kubectl logs -n argo-workflows $WORKFLOW_NAME -c main | grep "Resolved effective_date" | tail -1 | awk '{print $NF}')

# Download and inspect cluster_info.json
aws s3 cp s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models/$EFFECTIVE_DATE/cluster_info.json - | jq '.[] | {id, display_name, description}'

# Verify the names make sense for the full dataset (not just one day)
```

### Step 6: Test Rename Workflow Idempotency
This tests the **rename workflow idempotency fix** - ensures only one rename
workflow can run per client at a time.

```bash
# Run rename workflow
helm upgrade workstation-clustering ./infra/helm/workstation-clustering \
  -f infra/helm/workstation-clustering/values.sandbox.yaml \
  -n argo-workflows \
  --set image.tag=$TAG \
  --set workflows.workflowMode=rename \
  --install

# Immediately try to run it again (should fail with AlreadyExists)
helm upgrade workstation-clustering ./infra/helm/workstation-clustering \
  -f infra/helm/workstation-clustering/values.sandbox.yaml \
  -n argo-workflows \
  --set image.tag=$TAG \
  --set workflows.workflowMode=rename \
  --install

# Check the logs - should see "Rename workflow for 15887 already exists; skipping"
kubectl logs -n argo-workflows -l app.kubernetes.io/name=workstation-clustering,app.kubernetes.io/component=workflows-hook --tail=50
```

### Step 7: Verify Rename Results
```bash
# Get the latest effective date
LATEST_DATE=$(aws s3 ls s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models/ | grep PRE | tail -1 | awk '{print $2}' | tr -d '/')

# Download and inspect the renamed clusters
aws s3 cp s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models/$LATEST_DATE/clusters_dto.json - | jq '.'

# Verify:
# - Display names are updated
# - All cluster members are present
```

### Step 8: Test Overwrite Mode Empty DTO Protection
This tests the **overwrite mode artifact wiping fix** - ensures we don't wipe
existing artifacts when no DTOs are found.

**Setup:
Temporarily break the data to simulate no DTOs found**
```bash
# Rename the models folder to simulate no DTOs
aws s3 mv s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models/ \
  s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models_backup/ --recursive

# Run rename workflow (should exit gracefully without wiping base model)
helm upgrade workstation-clustering ./infra/helm/workstation-clustering \
  -f infra/helm/workstation-clustering/values.sandbox.yaml \
  -n argo-workflows \
  --set image.tag=$TAG \
  --set workflows.workflowMode=rename \
  --install

# Check logs - should see "No cluster DTOs found in overwrite mode - nothing to rename. Exiting without saving."
WORKFLOW_NAME=$(kubectl get workflows -n argo-workflows --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
kubectl logs -n argo-workflows $WORKFLOW_NAME -c main | grep -A 5 "No cluster DTOs found"

# Verify base model is still intact (not wiped)
aws s3 ls s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/base/models/

# Restore the models folder
aws s3 mv s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models_backup/ \
  s3://ou-medicine-15887-dev-ai-data/data-layer/machine-learning/workstation_clustering/models/ --recursive
```

## Success Criteria

### ✅ Scenario 1 Fix (effective_date='' with lookback_days)
- [ ] Bootstrap workflow completes successfully
- [ ] Naming step logs show `lookback_days=None` (not `lookback_days=0`)
- [ ] Cluster names are representative of all training data

### ✅ Rename Workflow Idempotency
- [ ] First rename workflow starts successfully
- [ ] Second concurrent rename attempt is rejected with "already exists" message
- [ ] Workflow name is `wc-rename-clusters-15887` (not
  `wc-rename-clusters-15887-<random>`)

### ✅ Overwrite Mode Protection
- [ ] When no DTOs found, workflow exits gracefully
- [ ] Log message:
  "No cluster DTOs found in overwrite mode - nothing to rename.
  Exiting without saving."
- [ ] Base model and existing artifacts remain intact (not wiped)

## Troubleshooting

### Workflow Fails to Start
```bash
# Check the workflows-hook job logs
kubectl logs -n argo-workflows -l app.kubernetes.io/name=workstation-clustering,app.kubernetes.io/component=workflows-hook --tail=100

# Check if service account has correct permissions
kubectl get sa api -n argo-workflows -o yaml
```

### Cannot Access S3 Bucket
```bash
# Verify IAM role is attached to service account
kubectl get sa api -n argo-workflows -o yaml | grep role-arn

# Expected: arn:aws:iam::439323037767:role/sbx-ueba-api-access-base-role
```

### Argo UI Not Accessible
```bash
# Check if port-forward is running
lsof -i :2746

# Restart port-forward if needed
kubectl port-forward -n argo-workflows svc/argo-workflows-server 2746:2746
```
