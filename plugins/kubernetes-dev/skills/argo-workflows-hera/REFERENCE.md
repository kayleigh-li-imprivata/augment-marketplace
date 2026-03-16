# Argo Workflows Hera Reference

Advanced patterns and complete examples for Hera workflows.

## Pydantic I/O (Experimental)

Type-safe workflow inputs and outputs using Pydantic models.

### Enable Pydantic I/O

```python
from hera.shared import global_config
from hera.workflows import Script

global_config.experimental_features["script_pydantic_io"] = True
global_config.set_class_defaults(Script, constructor="runner")
```

### Typed Input/Output Classes

```python
from hera.workflows.io import Input, Output
from hera.workflows import Artifact, Parameter, ArtifactLoader
from typing import Annotated
from pathlib import Path
class TrainInput(Input):
    data_path: Annotated[str, Parameter(name="data-path")]
    config: Annotated[dict, Artifact(name="config", loader=ArtifactLoader.json)]
    learning_rate: Annotated[float, Parameter(name="lr")] = 0.001
class TrainOutput(Output):
    model_path: Annotated[str, Parameter(name="model-path")]
    metrics: Annotated[dict, Artifact(name="metrics")]
@script(constructor="runner")
def train(input: TrainInput) -> TrainOutput:
    # input.data_path, input.config, input.learning_rate available
    return TrainOutput(
        model_path="/models/trained.pkl",
        metrics={"accuracy": 0.95},
    )
```

### Simple Annotated Types

```python
@script(constructor="runner")
def process(
    data: Annotated[dict, Artifact(name="input", loader=ArtifactLoader.json)],
) -> Annotated[str, Artifact(name="output")]:
    return json.dumps(processed)
```

## Artifacts

### When to Use Artifacts vs Parameters

| Data Type | Size | Choice |
|-----------|------|--------|
| Strings, numbers | < 256KB | Parameters |
| JSON blobs | Any | Artifacts |
| Model weights | Large | Artifacts |
| DataFrames | Any | Artifacts |

### Artifact Configuration

```python
from hera.workflows import Artifact, ArtifactLoader

# Input artifact with automatic deserialization
data: Annotated[
    dict,
    Artifact(
        name="input-data",
        path="/tmp/data.json",
        loader=ArtifactLoader.json,  # Auto-parse JSON
    ),
]
# Output artifact
@script(constructor="runner")
def produce_artifact() -> Annotated[Path, Artifact(name="output")]:
    output_path = Path("/tmp/hera-outputs/artifacts/output")
    output_path.write_text("data")
    return output_path
```

### Artifact Repository (Default S3)

```python
# Configured in Argo controller, not in Python
# Check workflow-controller-configmap for artifact repository settings
```

### Artifact Passing Between Steps

```python
with Steps(name="pipeline"):
    producer_step = produce_data()
    consumer_step = consume_data(
        arguments={"input": producer_step.get_artifact("output")}
    )
```

## CronWorkflows

### Daily ML Update Pattern

```python
from hera.workflows import CronWorkflow

cw = CronWorkflow(
    name="daily-model-update",
    schedule="0 6 * * *",  # 6 AM daily
    timezone="UTC",
    concurrency_policy="Forbid",  # Skip if still running
    starting_deadline_seconds=60,  # Grace period to start
)
```

### Concurrency Policies

| Policy | Behavior |
|--------|----------|
| Allow | Run concurrent instances |
| Forbid | Skip if previous running |
| Replace | Cancel previous, start new |

## API Integration

### Submitting Workflows

```python
from hera.workflows import Workflow
from hera.shared import global_config

# Configure Hera to connect to Argo server
global_config.host = "https://argo-workflows.argo.svc.cluster.local:2746"
global_config.verify_ssl = False
def submit_workflow(client_id: str, dates: list[str]) -> str:
    """Submit workflow and return workflow name."""
    workflow = create_detection_workflow(client_id, dates)
    submitted = workflow.create()
    return submitted.metadata.name
```

### FastAPI Endpoint Pattern

```python
from fastapi import HTTPException
@app.post("/job/{client_id}")
async def submit_job(
    client_id: str,
    request: JobRequest,
) -> JobResponse:
    try:
        workflow_name = submit_workflow(client_id, request.dates)
        return JobResponse(
            workflow_name=workflow_name,
            status="submitted",
        )
    except Exception as e:
        logger.error("workflow_submission_failed", error=str(e))
        raise HTTPException(500, f"Failed to submit workflow: {e}")
@app.get("/job/{client_id}/{workflow_name}")
async def get_job_status(
    client_id: str,
    workflow_name: str,
) -> JobStatusResponse:
    status = get_workflow_status(workflow_name)
    return JobStatusResponse(
        workflow_name=workflow_name,
        phase=status.phase,
        started_at=status.started_at,
        finished_at=status.finished_at,
    )
```

## Kubernetes Integration

### Service Account and IRSA

```python
from hera.workflows import Workflow

workflow = Workflow(
    generate_name="ml-pipeline-",
    service_account_name="ml-workflow-sa",  # Has IRSA for S3 access
    namespace="ml-workflows",
)
```

### Resource Requests

```python
from hera.workflows import Resources, script
@script(
    image="ghcr.io/org/ml-image:latest",
    resources=Resources(
        cpu_request="500m",
        memory_request="1Gi",
        cpu_limit="2",
        memory_limit="4Gi",
    ),
)
def train_model(data_path: str): ...
```

## Webhook Callbacks

### Notify on Completion

```python
@script()
def send_webhook(result_path: str, webhook_url: str):
    """Send completion notification."""
    import httpx

    response = httpx.post(
        webhook_url,
        json={
            "status": "completed",
            "result_path": result_path,
            "timestamp": datetime.now().isoformat(),
        },
    )
    response.raise_for_status()
with Workflow(generate_name="pipeline-") as w:
    with Steps(name="pipeline"):
        result = run_pipeline()
        send_webhook(
            arguments={
                "result_path": result.result,
                "webhook_url": "{{workflow.parameters.webhook_url}}",
            }
        )
```

## Testing Workflows

### Unit Test Script Functions

```python
def test_process_data_transforms_correctly(tmp_path: Path):
    # Arrange
    input_df = pd.DataFrame({"a": [1, 2, 3]})
    input_path = tmp_path / "input.parquet"
    input_df.to_parquet(input_path)

    # Act - call the script function directly
    output_path = process_data.func(str(input_path))

    # Assert
    output_df = pd.read_parquet(output_path)
    assert len(output_df) == 3
```

### Integration Test with MinIO

```python
@pytest.fixture
def minio_container():
    with MinioContainer() as minio:
        yield minio
def test_workflow_end_to_end(minio_container):
    # Upload test data to MinIO
    # Submit workflow
    # Wait for completion
    # Verify results in MinIO
    ...
```
