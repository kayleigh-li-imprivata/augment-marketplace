---
name: argo-workflows-hera
description: Use when orchestrating ML pipelines with Argo Workflows via Hera Python SDK - workflow definition, DAGs, cron scheduling, Pydantic I/O, artifacts, and Kubernetes integration patterns
---

# Argo Workflows with Hera

## Overview

Hera provides Python-native workflow definitions for Argo Workflows, enabling ML
pipeline orchestration with type safety and IDE support.

**Core principle:** Workflows should be reproducible and idempotent.
Design for retry and failure recovery from any step.

## When to Use

- Orchestrating multi-step ML pipelines
- Scheduling recurring ML jobs (CronWorkflows)
- Processing data in parallel
- Triggering workflows via API

## Workflow Types

| Type | Use Case | Trigger |
|------|----------|---------|
| Workflow | One-time execution | API call, manual |
| CronWorkflow | Scheduled recurring | Cron expression |

## Basic Workflow Structure

```python
from hera.workflows import (
 Workflow,
 Steps,
 script,
 Parameter,
)
@script(image="python:3.12-slim")
def process_data(input_path: str) -> str:
 """Process input data and return output path."""
 import pandas as pd

 df = pd.read_parquet(input_path)
 output_path = input_path.replace("input", "output")
 df.to_parquet(output_path)
 return output_path
@script(image="python:3.12-slim")
def train_model(data_path: str) -> str:
 """Train model on processed data."""
 ...
 return model_path
with Workflow(
 generate_name="ml-pipeline-",
 entrypoint="pipeline",
 arguments=[Parameter(name="input_path")],
) as w:
 with Steps(name="pipeline"):
 processed = process_data(
 arguments={"input_path": "{{workflow.parameters.input_path}}"}
 )
 train_model(arguments={"data_path": processed.result})
```

## Script Constructors

| Constructor | Use Case | External Imports | Pydantic I/O |
|-------------|----------|------------------|--------------|
| `inline` (default) | Simple scripts, prototyping | No | No |
| `runner` | Production, complex deps | Yes | Yes |

### When to Use Runner

- External library imports needed (pandas, sklearn, etc.)
- Pydantic I/O for type-safe inputs/outputs
- Complex serialization requirements
- Testing scripts locally before deployment

```python
# Inline (default) - function body dumped to YAML
@script(image="python:3.12-slim")
def simple_task(x: int) -> int:
 return x * 2
# Runner - runs via hera.workflows.runner module
@script(constructor="runner", image="my-image:v1")
def complex_task(data: dict) -> dict:
 import pandas as pd # External imports work

 return processed_data
```

## Global Configuration

```python
from hera.shared import global_config
from hera.workflows import Script

# Connection settings
global_config.host = "https://argo.example.com:2746"
global_config.token = os.environ.get("ARGO_TOKEN")
global_config.verify_ssl = True

# Set defaults for all scripts
global_config.set_class_defaults(Script, constructor="runner")
global_config.set_class_defaults(Script, image="my-registry/ml-base:v1")

# Enable experimental features
global_config.experimental_features["script_pydantic_io"] = True
```

## Advanced Features

See `REFERENCE.md` in this directory for:

- **Pydantic I/O** - Type-safe inputs/outputs with Pydantic models
- **Artifacts** - S3 artifacts, passing between steps
- **CronWorkflows** - Scheduled workflows with concurrency policies
- **DAG Workflows** - Parallel processing with fan-out/fan-in
- **API Integration** - Submitting workflows from FastAPI
- **Kubernetes Integration** - IRSA, resource requests
- **Webhook Callbacks** - Completion notifications
- **Testing** - Unit and integration test patterns

## TTL and Cleanup

### TTL Strategy (Required)

```python
from hera.workflows import TTLStrategy

workflow = Workflow(
 generate_name="ddi-pipeline-",
 ttl_strategy=TTLStrategy(
 seconds_after_completion=172800, # 2 days
 seconds_after_failure=172800,
 seconds_after_success=86400, # 1 day for success
 ),
)
```

### Why TTL Matters

- Argo stores workflow state in etcd
- Without TTL, workflows accumulate indefinitely
- etcd has storage limits that cause cluster issues
- Production standard:
  2 days retention

## Common Gotchas

| Issue | Cause | Solution |
|-------|-------|----------|
| Script can't import modules | Using inline constructor | Use `constructor="runner"` |
| Artifacts not found | Repository not configured | Configure S3/GCS in Argo controller |
| etcd overflow/cluster issues | No TTL strategy | Always set `ttl_strategy` |
| Closure variables not accessible | Script serialization | Pass all data as parameters |
| Container image not found | Cluster can't pull | Check registry access, imagePullSecrets |
| Pydantic I/O not working | Feature not enabled | Set `global_config.experimental_features["script_pydantic_io"] = True` |
| Large parameter fails | Exceeds 256KB limit | Use artifacts instead |
| Workflow stuck pending | Resource constraints | Check namespace quotas, node resources |

## File System Paths (Runner Scripts)

| Type | Path |
|------|------|
| Input artifacts | `/tmp/hera-inputs/artifacts/<name>` |
| Output artifacts | `/tmp/hera-outputs/artifacts/<name>` |
| Output parameters | `/tmp/hera-outputs/parameters/<name>` |

## See Also

- [Hera Documentation](https://hera.readthedocs.io/)
- [Argo Workflows Documentation](https://argo-workflows.readthedocs.io/)
