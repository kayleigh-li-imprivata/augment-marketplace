---
name: helm-kubernetes
description: Use when creating or modifying Helm charts or Kubernetes manifests - chart structure, values, templates, security patterns, and helm tests
---

# Helm & Kubernetes Best Practices

**CRITICAL**:
See `helm-kubernetes-guidelines.md` rule for namespace policy (never manage
namespaces in charts).

## Chart Structure

```text
my-chart/
├── Chart.yaml              # Metadata and dependencies
├── Chart.lock              # Locked dependency versions
├── values.yaml             # Default configuration
├── values.schema.json      # JSON Schema for values validation
├── templates/
│   ├── _helpers.tpl        # Named templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   ├── configmap.yaml
│   ├── hpa.yaml            # Horizontal Pod Autoscaler
│   ├── pdb.yaml            # Pod Disruption Budget
│   └── NOTES.txt           # Post-install notes
└── tests/
    └── test-connection.yaml  # Helm test pods
```

## Chart.yaml (Complete Example)

```yaml
apiVersion: v2
name: myapp
description: A Helm chart for MyApp
type: application
version: 1.0.0           # Chart version (SemVer)
appVersion: "2.3.1"      # Application version
kubeVersion: ">=1.25.0"  # Kubernetes version constraint
keywords:
  - myapp
  - api
home: https://github.com/org/myapp
sources:
  - https://github.com/org/myapp
maintainers:
  - name: Team Name
    email: team@example.com
dependencies:
  - name: postgresql
    version: "13.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
```

## Values Organization

Group related config hierarchically with inline documentation:

```yaml
# values.yaml

# -- Number of replicas for the deployment
replicaCount: 1

image:
  # -- Container image repository
  repository: myapp
  # -- Image pull policy
  pullPolicy: IfNotPresent
  # -- Overrides the image tag (default: Chart.appVersion)
  tag: ""

# -- Image pull secrets for private registries
imagePullSecrets: []

serviceAccount:
  # -- Create a ServiceAccount
  create: true
  # -- Annotations for the ServiceAccount
  annotations: {}
  # -- Name override (default: fullname)
  name: ""

service:
  # -- Service type
  type: ClusterIP
  # -- Service port
  port: 80

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  # -- Enable Horizontal Pod Autoscaler
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

podDisruptionBudget:
  # -- Enable Pod Disruption Budget
  enabled: false
  # -- Minimum available pods (number or percentage)
  minAvailable: 1
```

## Values Schema (values.schema.json)

Validate user-provided values:

```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": [
    "image"
  ],
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1
    },
    "image": {
      "type": "object",
      "required": [
        "repository"
      ],
      "properties": {
        "repository": {
          "type": "string",
          "minLength": 1
        },
        "tag": {
          "type": "string"
        },
        "pullPolicy": {
          "enum": [
            "Always",
            "IfNotPresent",
            "Never"
          ]
        }
      }
    }
  }
}
```

## Template Helpers (_helpers.tpl)

Complete set of reusable templates:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label for helm.sh/chart
*/}}
{{- define "mychart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ include "mychart.chart" . }}
{{ include "mychart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name
*/}}
{{- define "mychart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mychart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

## Complete Template Examples

See `REFERENCE.md` in this directory for complete templates:

- **Deployment Template** - Full deployment with security context, probes,
  resources
- **Helm Tests** - Connection test, API health test, database connectivity test
- **Pod Disruption Budget** - PDB configuration
- **Horizontal Pod Autoscaler** - HPA with CPU/memory metrics
- **ServiceAccount** - With automount disabled
- **NOTES.txt** - Post-install instructions

## Namespace Reference (When Required)

Only use `{{ .Release.Namespace }}` when necessary (ClusterRoleBinding
subjects).
Prefer omitting namespace - Kubernetes defaults to release namespace.

## Template Validation Commands

```bash
# Lint the chart
helm lint ./my-chart

# Lint with strict mode
helm lint ./my-chart --strict

# Template with debug output
helm template my-release ./my-chart --debug

# Dry-run install
helm install my-release ./my-chart --dry-run --debug

# Validate against cluster
helm install my-release ./my-chart --dry-run --debug --validate
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| `namespace` in values | Violates separation | Use `--namespace` flag |
| Hardcoded names | No multi-release | Use `{{ include "fullname" }}` |
| Missing probes | Unhealthy pods stay running | Add liveness/readiness |
| No resource limits | Resource starvation | Always set limits |
| `latest` tag | Non-reproducible | Use `{{ .Chart.AppVersion }}` |
| No PDB | Downtime during upgrades | Enable for production |
| Root user | Security vulnerability | Set `runAsNonRoot: true` |
