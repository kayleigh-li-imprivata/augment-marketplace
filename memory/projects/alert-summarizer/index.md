# Alert Summarizer - Project Overview

## 📋 What This Project Does

**Alert Summarizer** is an AI-powered service that analyzes authentication
failure alerts from Imprivata's Access Intelligence Platform (AIP).
It helps security teams quickly distinguish between genuine security threats and
benign login issues (like forgotten passwords or system misconfigurations).

### Core Workflow
1. **Receives** authentication failure alert data via REST API
2. **Analyzes** patterns using Claude Sonnet 4 (AWS Bedrock)
3. **Queries** alert data using AI-generated SQL (DuckDB)
4. **Retrieves** relevant documentation from knowledge base
5. **Returns** structured natural-language summaries with security assessments

### Key Capabilities
- ✅ **Async processing** - Returns 202 Accepted immediately, delivers results
  via webhook
- ✅ **Real-time budget control** - Stops execution if cost limits exceeded
- ✅ **Agentic SQL** - LLM writes and executes SQL queries to analyze data
- ✅ **Structured output** - Guaranteed JSON schema compliance via Pydantic
- ✅ **Cost optimization** - 90% savings via prompt caching
- ✅ **Full observability** - OpenTelemetry tracing for every operation

---

## 🏗️ Infrastructure & Architecture

### API Layer
- **Framework**:
  FastAPI with Uvicorn ASGI server
- **Pattern**:
  Async background tasks (202 Accepted pattern)
- **Deployment**:
  Docker containers on Kubernetes (Helm charts)
- **Observability**:
  OpenTelemetry with OTLP export
- **Health checks**:
  `/healthz` endpoint with Docker healthcheck

### AWS Infrastructure
- **LLM Service**:
  AWS Bedrock (Claude Sonnet 4.6)
- **Knowledge Base**:
  Bedrock Knowledge Base (vector search)
- **Authentication**:
  IAM role assumption with cross-account access
- **Secrets**:
  AWS Secrets Manager for OAuth credentials
- **Regions**: 
  - Bedrock:
    `us-east-1`
  - Knowledge Base:
    `us-east-2`
  - Secrets Manager:
    `us-east-2`

### Container Architecture
Multi-stage Dockerfile:
1. **base**:
   Python 3.12 + uv package manager
2. **dev**:
   Install dependencies (no project code)
3. **app**:
   Add source code and sync
4. **api**:
   Production entrypoint with OpenTelemetry instrumentation

### CI/CD Pipeline
- **GitHub Actions**:
  Automated testing, linting, Docker builds
- **Registries**:
  AWS ECR + GitHub Container Registry (GHCR)
- **Deployment**:
  Skaffold + Helm for Kubernetes
- **Quality Gates**:
  MegaLinter, pytest, coverage reporting

---

## 🤖 AI Components & Techniques

### 1. **LLM Model**
- **Provider**:
  AWS Bedrock
- **Model**:
  `us.anthropic.claude-sonnet-4-6`
- **Context Window**:
  1 million tokens (extended context beta)
- **Temperature**:
  0.2 (deterministic, factual responses)
- **Framework**:
  PydanticAI (type-safe agent framework)

### 2. **Prompt Caching** (90% Cost Reduction)
Caches three components to minimize redundant token processing:
- System instructions (static prompt)
- Tool definitions (function schemas)
- Conversation history (multi-turn optimization)

### 3. **Agentic Tools** (RAG Pattern)

#### **Tool 1:
     `get_alert_info`**
- Discovers available data tables dynamically
- Returns metadata about alert structure

#### **Tool 2:
     `query_table`** (SQL Agent)
- **LLM writes SQL queries** to analyze alert data
- Uses **DuckDB in-memory** database for fast analytics
- Converts PyArrow tables to queryable format
- Returns markdown tables for LLM consumption
- **20 retries** with error feedback - LLM fixes bad SQL

#### **Tool 3:
     `query_knowledge_base`**
- Vector search against Bedrock Knowledge Base
- Retrieves relevant Imprivata documentation
- **10 retries** for resilience

### 4. **Real-Time Budget Control** Unique approach:
       Budget enforcement **during** execution, not after
- Uses `agent.iter()` to inspect each step of the agentic loop
- Calculates cost per message using `genai-prices` library
- Stops immediately when budget exceeded (prevents runaway costs)
- Tracks cumulative cost in validated Pydantic model

### 5. **Structured Output**
- Uses PydanticAI's `output_type=AlertSummary` for guaranteed schema
- Automatic validation and retry on malformed responses
- Type-safe throughout the codebase (no JSON parsing errors)
- `ModelRetry` exception allows LLM to self-correct

### 6. **Error Handling & Resilience**
- **Agent-level retries**:
  `@tool(retries=20)` - LLM gets error message and tries again
- **AWS-level retries**:
  Adaptive retry mode with exponential backoff
- **Throttling handling**:
  Automatic backoff for rate limits
- **Self-healing queries**:
  LLM adjusts SQL based on error feedback

### 7. **Security & Isolation**
- **New DuckDB connection per query** (`:memory:`) - prevents data leakage
- **Temporary file isolation** - each request gets its own temp directory
- **Connection cleanup** - immediate closure after query execution

---

## 🛠️ Tech Stack

### Core Dependencies
| Component | Technology | Version |
|-----------|-----------|---------|
| **Language** | Python | 3.12+ |
| **Package Manager** | uv | 0.7.18 |
| **API Framework** | FastAPI | 0.115+ |
| **ASGI Server** | Uvicorn | 0.34+ |
| **AI Framework** | PydanticAI | 1.56+ |
| **Data Validation** | Pydantic | 2.11+ |
| **AWS SDK** | Boto3 | 1.40+ |
| **Database** | DuckDB | 1.3+ |
| **Data Format** | PyArrow | 21.0+ |
| **Cost Tracking** | genai-prices | 0.0.54+ |
| **Observability** | OpenTelemetry | 1.39+ |
| **HTTP Client** | httpx | 0.28+ |

### Development Tools
- **Testing**:
  pytest, pytest-asyncio, pytest-xdist (parallel execution)
- **Linting**:
  MegaLinter (Ruff, YAML, Terraform, etc.)
- **Pre-commit**:
  Automated quality checks
- **Coverage**:
  pytest-cov with context tracking
- **Evals**:
  pytest-evals for LLM evaluation

### Infrastructure Tools
- **Containerization**:
  Docker with multi-stage builds
- **Orchestration**:
  Kubernetes + Helm
- **Deployment**:
  Skaffold
- **Environment Management**:
  direnv
- **Version Control**:
  Git + GitHub Actions

---

## 🚀 Local Setup & Running with Fake Data

### Prerequisites
- **Python 3.12+**
- **uv package manager**:
  Install via `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **No AWS credentials needed** for local development!

### Quick Start (Development Mode)

#### 1. Install Dependencies
```bash
# Install production dependencies only (no AWS CodeArtifact needed)
uv sync --no-dev
```

#### 2. Start the API Server (DEV_ENV Mode)
```bash
# DEV_ENV=true uses TestModel instead of Bedrock
DEV_ENV=true uv run uvicorn alert_summarizer.api:app --host 0.0.0.0 --port 5000 --reload
```

The `--reload` flag enables automatic code reloading during development.

#### 3. Send a Test Request
Create a file `test_request.py`:
```python
import httpx

response = httpx.post(
    "http://localhost:5000/summarize",
    json={
        "uuid": "test-123",
        "prompt": "Analyze this alert",
        "report": {
            "library_display_code": "FailedLogins",
            "metadata": {"description": "Failed login attempts"},
            "data": [
                {
                    "user": "jsmith",
                    "timestamp": "2026-03-25T10:00:00Z",
                    "reason": "Invalid password",
                    "workstation": "WS-001"
                }
            ]
        },
        "related_reports": [],
        "webhook_url": None,
        "budget_limit": 1.0
    },
    headers={
        "impr-aip-client-id": "test-client"
    }
)

print(response.json())
```

Run it:
```bash
uv run python test_request.py
```

#### 4. Check Server Logs
In DEV_ENV mode, results are **logged to the console** instead of sent via
webhook:
```
INFO - Successfully generated summary for UUID test-123
INFO - DEV_ENV mode - logging result instead of sending webhook
```

---

### What Happens in DEV_ENV Mode?

When `DEV_ENV=true` is set:
- ✅ **No AWS credentials required**
- ✅ **TestModel** replaces Bedrock LLM (returns mock responses)
- ✅ **Knowledge Base** queries return empty results
- ✅ **Authentication** is skipped
- ✅ **Webhooks** are replaced with console logging
- ✅ **Same code paths** as production (high test fidelity)

This allows you to:
- Test the API structure
- Validate request/response schemas
- Debug background task processing
- Develop without AWS access

---

### Running with Realistic AI Output (Requires AWS)

For production-like AI responses, you need AWS credentials:

#### 1. Configure AWS Access
```bash
# Login via AWS SSO
aws sso login

# Set up direnv (optional but recommended)
# Create .envrc file with:
export BEDROCK_ASSUME_ROLE_ARN="arn:aws:iam::787222310730:role/alert-summ-alpha-dev"
export KNOWLEDGE_BASE_ID="D97OK0PFPB"
export DEPLOYMENT_ENVIRONMENT="sandbox"
```

#### 2. Install Development Dependencies
```bash
# Requires AWS CodeArtifact authentication
uv tool install keyring --with keyrings.codeartifact
uv sync --all-extras --dev
```

#### 3. Start Server (Production Mode)
```bash
# Without DEV_ENV - uses real Bedrock
uv run uvicorn alert_summarizer.api:app --host 0.0.0.0 --port 5000 --reload
```

#### 4. With OpenTelemetry Instrumentation
```bash
# Export traces to local collector
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"

uv run opentelemetry-instrument uvicorn alert_summarizer.api:app --host 0.0.0.0 --port 5000 --reload
```

---

## 🧪 Testing

### Run All Tests
```bash
# Parallel execution with coverage
uv run pytest

# Without coverage reporting
uv run pytest --no-cov

# Specific test file
uv run pytest tests/test_summary_agent.py
```

### Run LLM Evaluations
```bash
# Execute eval tests (requires AWS)
uv run pytest --suppress-failed-exit-code --run-eval -n 0

# Analyze eval results
uv run pytest --run-eval-analysis
```

Eval results are stored in `test-out/` directory with detailed LLMJudge outputs.

---

## 📊 Key Features Demonstrated

### 1. **Production-Grade AI Engineering**
- Real-time cost control during execution
- Structured output with type safety
- Self-healing queries via error feedback
- Comprehensive observability

### 2. **Scalable Architecture**
- Async-first design (no blocking operations)
- Background task processing
- Webhook-based result delivery
- Kubernetes-ready containerization

### 3. **Cost Optimization**
- 90% reduction via prompt caching
- Budget enforcement mid-execution
- Token usage tracking per step
- Tiered pricing support (long context)

### 4. **Security & Reliability**
- Data isolation per request
- Multi-layer error handling
- Automatic retry with backoff
- Cross-account IAM role assumption

### 5. **Developer Experience**
- DEV_ENV mode for local testing
- Type-safe end-to-end
- Comprehensive test coverage
- Pre-commit quality checks

---

## 📁 Project Structure

```
alert-summarizer/
├── src/alert_summarizer/       # Main application code
│   ├── api.py                  # FastAPI endpoints & background tasks
│   ├── summary_agent.py        # PydanticAI agent & tools
│   ├── schema.py               # Pydantic models
│   ├── config.py               # Settings & environment config
│   ├── utils.py                # AWS clients, auth, cost tracking
│   ├── prompts.py              # System instructions
│   └── exceptions.py           # Custom exception classes
├── tests/                      # Test suite
│   ├── test_summary_agent.py  # Agent logic tests
│   ├── test_api.py            # API endpoint tests
│   └── conftest.py            # Pytest fixtures
├── infra/helm/                 # Kubernetes deployment
│   └── alert-summarizer/      # Helm chart
├── experiments/                # Development scripts
├── docs/                       # Documentation
├── .github/workflows/          # CI/CD pipelines
├── Dockerfile                  # Multi-stage container build
├── pyproject.toml             # Dependencies & config
├── uv.lock                    # Locked dependencies
└── README.md                  # Development guide
```

---

## 🔗 Related Documentation

- **System Walkthrough**:
  `docs/20260125-system-walkthrough.md`
- **Slides**:
  `docs/20260125-system-walkthrough-slides.md`
- **Development Guide**:
  `README.md`
- **API Documentation**:
  Available at `http://localhost:5000/docs` when running

---

## 💡 Key Innovations

This project showcases several advanced patterns:

1. **Budget enforcement DURING execution** (not just limits)
2. **LLM writes SQL** to query its own data (agentic RAG)
3. **Self-healing queries** via ModelRetry feedback loop
4. **90% cost reduction** via aggressive caching
5. **Zero data leakage** via per-request isolation
6. **Production-grade async** with webhook callbacks
7. **Full observability** with OpenTelemetry
8. **Type-safe end-to-end** with Pydantic

---

## 📞 Support & Contributing

For questions or contributions, refer to the main `README.md` and project
documentation.

**Built with ❤️ by the Imprivata AI Team**
