# Summary: Setting Up Helm Chart and Argo Workflows for ML Pipeline

## Overview
This document captures key learnings from implementing a production-ready Helm
chart for a machine learning workstation clustering service with Argo Workflows
integration.

## Architecture: How Everything Links Together

### 1. **The Three Components** The system consists of three interconnected
       pieces:

```
┌─────────────────────────────────────────────────────────────┐
│                    Helm Chart Deployment                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   FastAPI    │  │    Argo      │  │   Workflow       │  │
│  │   Service    │  │  Workflows   │  │   Submission     │  │
│  │              │  │  (subchart)  │  │   Hook Job       │  │
│  │  - REST API  │  │              │  │                  │  │
│  │  - Inference │  │  - Scheduler │  │  - CronWorkflows │  │
│  │  - Model     │  │  - Executor  │  │  - One-time      │  │
│  │    Loading   │  │              │  │    setup         │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│         │                 │                    │             │
│         └─────────────────┴────────────────────┘             │
│                           │                                  │
│                  Shared Resources:                           │
│                  - ServiceAccount (IRSA)                     │
│                  - ConfigMap (clients.yaml)                  │
│                  - Secrets                                   │
└─────────────────────────────────────────────────────────────┘
```

### 2. **Workflow Submission Flow**

```
Helm Install/Upgrade
       │
       ├─> Creates ServiceAccount with IRSA annotation
       │   (eks.amazonaws.com/role-arn: arn:aws:iam::...)
       │
       ├─> Creates ConfigMap from clients.yaml
       │   (Customer configurations: buckets, regions, etc.)
       │
       ├─> Deploys FastAPI service (optional)
       │
       ├─> Deploys/References Argo Workflows
       │   (Can use subchart or existing installation)
       │
       └─> Runs Hook Job (post-install/post-upgrade)
                 │
                 ├─> Sets environment variables:
                 │   - WC_IS_SUBMITTER=true
                 │   - ARGO_SERVER_HOST=http://argo-server...
                 │   - POD_NAMESPACE=<namespace>
                 │   - SERVICE_ACCOUNT_NAME=<sa-name>
                 │
                 └─> Python script reads env vars
                           │
                           ├─> Hera global_config configured
                           │   - image: Docker image to use
                           │   - namespace: Where to run workflows
                           │   - service_account_name: For IRSA
                           │   - host: Argo server URL
                           │
                           └─> Submits CronWorkflows to Argo
                                 - base-update (weekly grid search)
                                 - daily-update (incremental updates)
```

### 3. **Runtime Workflow Execution**

```
CronWorkflow Triggered (by schedule or manually)
       │
       └─> Argo creates Workflow pods
                 │
                 ├─> Pod uses ServiceAccount (IRSA for S3 access)
                 │
                 ├─> Mounts ConfigMap at /etc/dtm/clients.yaml
                 │
                 ├─> Runs Python script with Hera @script decorator
                 │   - Uses global_config.image for container
                 │   - Uses global_config.command: ["uv", "run", "python"]
                 │   - constructor="runner" (runs in same container)
                 │
                 └─> Script execution:
                       - Reads clients.yaml for customer configs
                       - Downloads data from S3 (via IRSA)
                       - Trains/updates BERTopic model
                       - Uploads results back to S3
```

## Key Learnings

### 1. **Minimal vs Production-Ready Helm Chart**

#### Minimal Working Chart
```yaml
# Just enough to deploy
apiVersion: v2
name: workstation-clustering
version: 0.1.0

# Simple deployment
templates/
  deployment.yaml    # Basic pod spec
  service.yaml       # ClusterIP service
  configmap.yaml     # Static config
```

**What's missing:**
- No flexibility (hardcoded values)
- No environment-specific overrides
- No subchart dependencies
- No lifecycle hooks
- No RBAC/ServiceAccount management
- No ingress configuration
- No resource limits/requests
- No health checks

#### Production-Ready Chart
```yaml
# Full-featured chart
apiVersion: v2
name: workstation-clustering
version: 1.0.0
dependencies:
  - name: argo-workflows
    version: "0.45.3"
    repository: https://argoproj.github.io/argo-helm
    condition: argo-workflows.enabled

# Comprehensive templates
templates/
  _helpers.tpl              # Reusable template functions
  deployment.yaml           # With probes, resources, security
  service.yaml              # Configurable type/ports
  serviceaccount.yaml       # IRSA annotations
  configmap.yaml            # From files, templated
  ingress.yaml              # With TLS, auth options
  workflows-hook.yaml       # Lifecycle management
  NOTES.txt                 # Post-install instructions

# Multiple value files
values.yaml               # Production defaults
values.sandbox.yaml       # Dev/test overrides

# Testing
tests/
  *.yaml                  # Helm unittest specs
  README.md               # Test documentation
```

**Key additions:**
- **Flexibility:** Everything configurable via values
- **Environment-specific:** Override files for different envs
- **Dependencies:** Subchart management with conditions
- **Lifecycle hooks:** Post-install/upgrade automation
- **Security:** RBAC, ServiceAccounts, IRSA
- **Observability:** Health checks, resource limits
- **Testing:** Automated template validation

### 2. **Helm Template Helpers (_helpers.tpl)**

**Purpose:** DRY principle for repeated template logic

**Key patterns learned:**

```yaml
{{/* Standard labels - used everywhere */}}
{{- define "workstation-clustering.labels" -}}
helm.sh/chart: {{ include "workstation-clustering.chart" . }}
{{ include "workstation-clustering.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Conditional logic - use subchart or explicit value */}}
{{- define "workstation-clustering.argoServerHost" -}}
{{- if .Values.workflows.argoServerHost }}
  {{- .Values.workflows.argoServerHost }}
{{- else if (index .Values "argo-workflows" "enabled") }}
  {{/* Use subchart templates to prevent config drift */}}
  {{- $argoValues := index .Values "argo-workflows" -}}
  {{- $argoContext := dict "Values" $argoValues "Release" .Release "Chart" (dict "Name" "argo-workflows") -}}
  {{- $serviceName := include "argo-workflows.server.fullname" $argoContext -}}
  {{- $namespace := include "argo-workflows.namespace" $argoContext -}}
  {{- $servicePort := default 2746 $argoValues.server.servicePort -}}
  {{- printf "http://%s.%s.svc.cluster.local:%d" $serviceName $namespace (int $servicePort) }}
{{- else }}
  {{- required "workflows.argoServerHost must be set when argo-workflows.enabled is false" .Values.workflows.argoServerHost }}
{{- end }}
{{- end }}
```

**Lesson:** Using subchart templates (when available) prevents configuration
drift between parent and subchart.

### 3. **Helm Hooks for Workflow Submission**

**Problem:** Need to create Argo CronWorkflows after Helm install/upgrade

**Solution:** Helm hook job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  annotations:
    helm.sh/hook: post-install,post-upgrade
    helm.sh/hook-weight: "5"
    helm.sh/hook-delete-policy: before-hook-creation
spec:
  template:
    spec:
      restartPolicy: OnFailure  # Critical: retry on failure
      serviceAccountName: {{ include "workstation-clustering.serviceAccountName" . }}
      containers:
      - name: create-workflows
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        command: ["uv", "run", "python", "-m", "workstation_clustering.workflows.create_workflows"]
        env:
        - name: WC_IS_SUBMITTER
          value: "true"
        - name: ARGO_SERVER_HOST
          value: {{ include "workstation-clustering.argoServerHost" . | quote }}
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: SERVICE_ACCOUNT_NAME
          value: {{ include "workstation-clustering.serviceAccountName" . | quote }}
```

**Key learnings:**
- **Hook timing:** `post-install,post-upgrade` ensures Argo is ready
- **Hook weight:** Controls order when multiple hooks exist
- **Delete policy:** `before-hook-creation` cleans up old jobs
- **Restart policy:** `OnFailure` (not `Never`) allows retries
- **Environment variables:** Bridge between Helm and Python code

### 4. **Hera Global Configuration**

**Problem:** How to configure workflow pods at runtime?

**Solution:** Environment-driven global_config

```python
# src/workstation_clustering/workflows/__init__.py
from hera.shared import global_config
from hera.workflows import RetryStrategy, Script

# Enable experimental features
global_config.experimental_features.update(
    {"script_pydantic_io": True, "script_annotations": True}
)

# Configure from environment (set by Helm hook)
global_config.host = os.getenv("ARGO_SERVER_HOST", "https://localhost:2746")
global_config.image = os.getenv("IMAGE", "")
global_config.service_account_name = os.getenv("SERVICE_ACCOUNT_NAME", "")
global_config.namespace = os.getenv("POD_NAMESPACE", "")

# Defaults for all @script decorators
global_config.set_class_defaults(
    Script,
    constructor="runner",  # Run in same container (not separate init)
    command=["uv", "run", "python"],  # Use uv for dependency management
    retry_strategy=RetryStrategy(limit=0),  # No auto-retry (fail fast)
)
```

**Key learnings:**
- **Constructor="runner":** Runs script in same container (vs "base" which uses
  init container)
- **Command override:** Necessary because Dockerfile has `ENTRYPOINT
  ["uvicorn"]` for API
- **Environment-driven:** Same code works in different environments (local,
  sandbox, prod)
- **Global defaults:** Set once, applied to all `@script` decorators

### 5. **ConfigMap Management**

**Two approaches:**

#### Without Helm (Manual)
```bash
kubectl create configmap workstation-clustering-clients-config \
  --from-file=clients.yaml=infra/helm/workstation-clustering/config/clients.yaml \
  -n argo-workflows
```

#### With Helm (Automatic)
```yaml
# templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "workstation-clustering.fullname" . }}-clients-config
data:
  clients.yaml: |
{{ .Files.Get "config/clients.yaml" | indent 4 }}
```

**Lesson:** Helm's `.Files.Get` automatically includes files from chart
directory, ensuring ConfigMap stays in sync with code.

### 6. **IRSA (IAM Roles for Service Accounts)**

**Problem:** Workflows need S3 access without hardcoded credentials

**Solution:** EKS IRSA

```yaml
# ServiceAccount with IRSA annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "workstation-clustering.serviceAccountName" . }}
  annotations:
    eks.amazonaws.com/role-arn: {{ .Values.serviceAccount.annotations.eks\.amazonaws\.com/role-arn }}
```

**How it works:**
1. EKS mutates pods using this ServiceAccount
2. Injects AWS credentials as environment variables
3. AWS SDK automatically uses these credentials
4. No secrets needed in code or config

**Lesson:** Different environments need different IAM roles:
- **Production:** `prd-ueba-api-access-base-role`
- **Sandbox:** `sbx-ueba-api-access-base-role`

Use `values.sandbox.yaml` to override for testing.

### 7. **Subchart Management**

**Two deployment modes:**

#### Mode 1: Bundled (Development/Testing)
```yaml
# values.yaml
argo-workflows:
  enabled: true  # Deploy Argo as subchart
  server:
    servicePort: 2746
  # ... other Argo config
```

**Pros:** Self-contained, easy to spin up **Cons:** Duplicate Argo installations
per namespace

#### Mode 2: External (Production)
```yaml
# values.yaml
argo-workflows:
  enabled: false  # Use existing Argo installation

workflows:
  argoServerHost: "http://argo-server.argo-workflows.svc.cluster.local:2746"
```

**Pros:** Single Argo instance, shared across teams **Cons:** Requires
pre-existing Argo installation

**Lesson:** Use `condition:
argo-workflows.enabled` in Chart.yaml to make subchart optional.

### 8. **Helm Unittest**

**Problem:** How to test templates without deploying?

**Solution:** helm-unittest plugin

```yaml
# tests/workflows-hook_test.yaml
suite: test workflows hook
templates:
  - workflows-hook.yaml
set:
  # Override values for testing
  argo-workflows.enabled: false
  workflows.argoServerHost: "http://argo-server.argo-workflows.svc.cluster.local:2746"
tests:
  - it: should create hook job with correct env vars
    asserts:
      - isKind:
          of: Job
      - equal:
          path: spec.template.spec.containers[0].env[0].name
          value: WC_IS_SUBMITTER
```

**Key learnings:**
- **Suite-level settings:** Apply to all tests in file
- **Subchart templates unavailable:** Must disable subchart and provide explicit
  values
- **Automatic values.yaml loading:** No need to specify `values:
  - ../values.yaml`
- **Test isolation:** Each test gets fresh template render

### 9. **Environment Variable Patterns**

**Three layers of configuration:**

```
┌─────────────────────────────────────────────────┐
│ Layer 1: Helm Values (values.yaml)             │
│ - User-configurable                             │
│ - Environment-specific overrides                │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│ Layer 2: Kubernetes Resources                  │
│ - ServiceAccount (IRSA)                         │
│ - ConfigMap (clients.yaml)                      │
│ - Job env vars (from Helm templates)            │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│ Layer 3: Python Code                           │
│ - os.getenv() reads K8s env vars               │
│ - Hera global_config configured                 │
│ - Workflows submitted with correct settings     │
└─────────────────────────────────────────────────┘
```

**Lesson:** Each layer has a specific responsibility.
Don't mix concerns.

### 10. **Testing Strategy**

**Local Development:**
```bash
# 1. Port-forward to Argo
kubectl -n argo-workflows port-forward svc/argo-workflows-server 2746:2746

# 2. Set environment variables
export IMAGE="439323037767.dkr.ecr.us-east-2.amazonaws.com/workstation-clustering:$(git rev-parse --short HEAD)"
export SERVICE_ACCOUNT_NAME="api"
export POD_NAMESPACE="argo-workflows"
export ARGO_SERVER_HOST="https://localhost:2746"
export WC_IS_SUBMITTER="true"

# 3. Submit workflows directly
uv run python -m workstation_clustering.workflows.create_workflows
```

**With Helm (Sandbox):**
```bash
# 1. Create values.sandbox.yaml with environment-specific overrides
# 2. Install/upgrade
helm upgrade --install workstation-clustering ./infra/helm/workstation-clustering \
  -f infra/helm/workstation-clustering/values.sandbox.yaml \
  -n argo-workflows \
  --set image.tag=$(git rev-parse --short HEAD)

# 3. Hook job automatically submits workflows
```

**Lesson:** Local testing requires manual env var setup.
Helm automates this via hook job.

## Common Pitfalls and Solutions

### Pitfall 1: Subchart templates in tests
**Problem:** `helm unittest` can't access subchart templates

**Solution:** Disable subchart in tests, provide explicit values

### Pitfall 2: Hook job fails silently
**Problem:** `restartPolicy:
Never` means no retries

**Solution:** Use `restartPolicy:
OnFailure`

### Pitfall 3: Environment variables not set
**Problem:** Python code reads empty strings from `os.getenv()`

**Solution:** Ensure Helm hook sets all required env vars

### Pitfall 4: ConfigMap not mounted
**Problem:** Workflows can't read clients.yaml

**Solution:** Mount ConfigMap in workflow pod spec (handled by Hera)

### Pitfall 5: IRSA not working
**Problem:** S3 access denied

**Solution:** Verify ServiceAccount annotation matches IAM role ARN

### Pitfall 6: Image pull errors
**Problem:** Workflow pods can't pull Docker image

**Solution:** Ensure ECR authentication, correct image tag

### Pitfall 7: Namespace mismatch
**Problem:** Workflows submitted to wrong namespace

**Solution:** Use `POD_NAMESPACE` from fieldRef, not hardcoded

### Pitfall 8: Global config timing
**Problem:** `global_config` set before environment variables available

**Solution:** Set env vars in conftest.py before importing workflows module

## Best Practices Summary

1. **Use Helm helpers for repeated logic** - DRY principle
2. **Leverage subchart templates when available** - Prevents config drift
3. **Make everything configurable via values** - Environment flexibility
4. **Use IRSA for AWS credentials** - No secrets in code
5. **Test templates with helm-unittest** - Catch errors before deploy
6. **Use lifecycle hooks for automation** - Post-install workflow submission
7. **Environment-driven configuration** - Same code, different envs
8. **Document with NOTES.txt** - Help users after install
9. **Version everything** - Chart version, app version, image tags
10. **Fail fast with good error messages** - Use `required` in templates

## Component Interaction Table

| Component | Purpose | Configuration Source | Runtime Behavior |
|-----------|---------|---------------------|------------------|
| **Helm Chart** | Package & deploy | values.yaml, values.sandbox.yaml | Creates K8s resources |
| **ServiceAccount** | AWS credentials (IRSA) | Helm values → K8s annotation | EKS injects credentials into pods |
| **ConfigMap** | Customer configs | config/clients.yaml → Helm | Mounted at /etc/dtm/clients.yaml |
| **Hook Job** | Workflow submission | Helm hook → Python script | Runs once per install/upgrade |
| **Hera global_config** | Workflow defaults | Environment variables | Applied to all @script decorators |
| **Argo Workflows** | Orchestration engine | Subchart or external | Schedules & executes workflow pods |
| **FastAPI Service** | REST API | Helm deployment | Loads models, serves predictions |
| **Workflow Pods** | ML training/inference | global_config.image | Runs Python scripts with S3 access |

## Configuration Flow Diagram

```
values.yaml (User Input)
    │
    ├─> serviceAccount.annotations.eks.amazonaws.com/role-arn
    │   └─> ServiceAccount → IRSA → S3 Access
    │
    ├─> image.repository + image.tag
    │   └─> Hook Job → IMAGE env var → global_config.image
    │
    ├─> workflows.argoServerHost (or subchart templates)
    │   └─> Hook Job → ARGO_SERVER_HOST env var → global_config.host
    │
    └─> config/clients.yaml
        └─> ConfigMap → Mounted in pods → Python reads customer configs
```

## Key Differences: Development vs Production

| Aspect | Development/Testing | Production |
|--------|-------------------|------------|
| **Argo Deployment** | Subchart (argo-workflows.enabled: true) | External (argo-workflows.enabled: false) |
| **Namespace** | argo-workflows (testing) | workstation-clustering (dedicated) |
| **ServiceAccount** | api (sandbox role) | workstation-clustering (prod role) |
| **IAM Role** | sbx-ueba-api-access-base-role | prd-ueba-api-access-base-role |
| **S3 Buckets** | *-dev-ai-data | *-prd-ai-data |
| **Ingress Auth** | Disabled (forwardAuth.enabled: false) | Enabled (OAuth2 proxy) |
| **Resources** | Reduced (8Gi memory) | Full (32Gi memory) |
| **Replicas** | 1 | 2+ (HA) |
| **ConfigMap** | Manual creation or Helm | Helm-managed |
| **Workflow Submission** | Manual (port-forward + env vars) | Automated (Helm hook) |

## Conclusion

Building a production-ready Helm chart is significantly more complex than a
minimal working version, but the investment pays off in:

- **Flexibility:** Easy to deploy to different environments
- **Maintainability:** Clear separation of concerns
- **Reliability:** Automated testing and validation
- **Security:** IRSA, RBAC, no hardcoded credentials
- **Observability:** Health checks, resource limits, logging

The key insight is that Helm is not just a templating engine—it's a complete
lifecycle management tool that bridges infrastructure (Kubernetes) and
application code (Python/Hera) through a well-designed configuration layer.

### Critical Success Factors

1. **Environment variables as the bridge:** Helm → K8s → Python
2. **Subchart templates prevent drift:** Use when available
3. **Lifecycle hooks enable automation:** Post-install workflow submission
4. **IRSA eliminates credential management:** Secure by default
5. **Testing at every layer:** Helm unittest, pytest, integration tests

### Future Improvements

- **GitOps integration:** ArgoCD for declarative deployments
- **Monitoring:** Prometheus metrics, Grafana dashboards
- **Alerting:** Workflow failure notifications
- **Multi-tenancy:** Namespace isolation per customer
- **Cost optimization:** Karpenter for autoscaling, spot instances
- **Disaster recovery:** Backup/restore procedures for models
