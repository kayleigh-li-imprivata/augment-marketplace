# Memory Registry

Index of all captured knowledge in the marketplace.

## Global Memory

### Architecture Decisions

#### Prod Promotion Enhancement
**Path:** `memory/global/artifacts/architecture/prod-promotion-enhancement.md`  
**Summary:** ArgoCD event-driven promotion pattern for production deployments.

### Tooling Setup

#### Grafana MCP Setup
**Path:** `memory/global/artifacts/tooling/grafana-mcp-setup.md`  
**Summary:** How to set up and run the Grafana MCP server against AWS Managed Grafana (ai-prod-amg). Requires sshuttle, GRAFANA_SERVICE_ACCOUNT_TOKEN env var, uvx mcp-grafana package, and a fresh auggie session. curl does not work directly — only the auggie MCP client works.

#### AI Env Access (SSO, sshuttle, kubeconfig)
**Path:** `memory/global/artifacts/tooling/ai-env-access.md`  
**Summary:** One-stop reference for authenticating to and reaching any `ai-*` EKS cluster across Dev/QA/Sandbox/Prod. Covers AWS SSO account/role matrix (app `439323037767`, data-prod `582974859345`, data-nonprod `702767219569`, sandbox `787222310730`), jumpbox selection (`ai-jumpbox-proxy` for Dev/QA/Sandbox, `ai-prod-jumpbox-proxy` for Prod), sshuttle preflight, and `aws eks update-kubeconfig` recipes per env.

## Project Memory: alert-summarizer

### Index
**Path:** `memory/projects/alert-summarizer/index.md`  
**Summary:** AI-powered authentication failure alert analysis service using PydanticAI, AWS Bedrock, and agentic SQL patterns.

## Project Memory: workstation-clustering

### Index
**Path:** `memory/projects/workstation-clustering/index.md`  
**Summary:** Project overview, navigation, and quick reference for workstation-clustering project.

### Learning
**Path:** `memory/projects/workstation-clustering/LEARNING.md`  
**Summary:** Lessons learned, patterns discovered, and knowledge gained during workstation-clustering development.

### Memory Strategy
**Path:** `memory/projects/workstation-clustering/memory-strategy.md`  
**Summary:** How we organize and maintain project-specific knowledge for workstation-clustering.

### Release Process
**Path:** `memory/projects/workstation-clustering/RELEASE.md`  
**Summary:** Deployment workflow, release checklist, and production promotion process.

### Sandbox Test Execution
**Path:** `memory/projects/workstation-clustering/SANDBOX_TEST_EXECUTION.md`  
**Summary:** Testing procedures and guidelines for sandbox environment validation.

### Investigate Prod
**Path:** `memory/projects/workstation-clustering/INVESTIGATE_PROD.md`  
**Summary:** Diagnostic checklist for investigating prod pipeline state (e.g., "El Camino" tenant freshness). Preflight env access via `ai-env-access.md`, then walk: CronWorkflow schedules + last successful runs in `ai-prod` namespace, S3 artifact freshness in `s3://imprivata-icp-datalayer-prod-...`, daily-update vs rename workflow distinction, and tenant client_id lookups (El Camino `181568`, Imprivata Inc `10566`). Calls out common wrong inferences: format-change vs logic-change, daily-update does NOT rename, cron schedule vs downstream API observation lag.
