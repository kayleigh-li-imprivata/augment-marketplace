---
type: always_apply
priority: HIGH
description: Helm chart and Kubernetes manifest guidelines with namespace policy enforcement
last_updated: 2025-01-27
---

# Helm and Kubernetes Guidelines

## ⚠️ CRITICAL: Helm Chart Namespace Management Rule ⚠️

**ABSOLUTE RULE**:
Helm charts in this project must NEVER manage namespaces directly.

### Prohibited Actions

1. **DO NOT create Namespace resources** within Helm charts
   - No `kind:
     Namespace` manifests in any chart template
   - Namespaces are infrastructure concerns, not application concerns

2. **DO NOT include `namespace` as a configurable value**
   - No `namespace` field in `values.yaml`
   - No namespace configuration options exposed to users

3. **DO NOT hardcode namespace values**
   - No hardcoded namespace strings in chart templates
   - Avoid any static namespace references

4. **DO NOT allow users to specify namespace through chart values**
   - Namespace selection is a deployment-time decision
   - Not a chart configuration concern

### Required Approach

**Namespace MUST be specified at installation time:**

```bash
# Correct approach - namespace specified at install/upgrade time
helm install my-release ./my-chart --namespace my-namespace --create-namespace
helm upgrade my-release ./my-chart --namespace my-namespace
```

**The namespace is managed externally to the chart, not by the chart itself.**

### When Namespace Reference is Necessary

In rare cases where you must reference the namespace (e.g., in RoleBinding
subjects, ClusterRoleBinding, or cross-namespace references):

**✅ CORRECT - Use the built-in Helm template variable:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "mychart.fullname" . }}
subjects:
- kind: ServiceAccount
  name: {{ include "mychart.serviceAccountName" . }}
  namespace: {{ .Release.Namespace }}
```

**❌ INCORRECT - Hardcoded or values-based namespace:**

```yaml
# DON'T DO THIS
subjects:
- kind: ServiceAccount
  name: my-service-account
  namespace: my-hardcoded-namespace  # ❌ Hardcoded

# DON'T DO THIS EITHER
subjects:
- kind: ServiceAccount
  name: my-service-account
  namespace: {{ .Values.namespace }}  # ❌ From values
```

**However, prefer omitting explicit namespace references entirely when
possible**, as Kubernetes will default to the release namespace for namespaced
resources.

### Rationale

1. **Separation of Concerns**:
   Namespace lifecycle should be managed independently from application
   deployment
2. **Prevents Conflicts**:
   Avoids namespace ownership conflicts and allows multiple releases in
   different namespaces
3. **Multi-tenancy Support**:
   Enables better isolation and reusability across environments
4. **Helm Best Practices**:
   Follows official Helm recommendations for chart portability
5. **Flexibility**:
   Allows the same chart to be deployed to any namespace without modification

### Enforcement

- **Code Review**:
  All Helm chart changes must be reviewed for namespace management violations
- **Testing**:
  Chart installation tests must verify namespace is not managed by the chart
- **CI/CD**:
  Automated checks should flag any `kind:
  Namespace` resources in charts

## Best Practices

For chart structure, values organization, template helpers, resource
configuration, and security context patterns, see the `helm-kubernetes` skill.
