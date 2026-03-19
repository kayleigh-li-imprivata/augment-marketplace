# Workstation Clustering - Project Memory

## 🎯 Project Overview

ML-powered analysis of user login patterns at hospital workstations to detect workstation clusters, identify unusual behavior and inform adaptive authentication policies.

**Repository:** `/home/kayleighli/imprivata/workstation-clustering`

---

## 📚 Available Knowledge (Load on Demand)

### Memory Management
**File:** `memory-strategy.md` (58 lines)
- TOC approach for token efficiency (80-90% savings)
- On-demand loading vs auto-loading comparison
- How to add new knowledge to memory
- File naming conventions

### Infrastructure & Architecture
**File:** `LEARNING.md` (604 lines)
- Helm chart architecture and Argo Workflows integration
- How components link together (API, workflows, IRSA, ServiceAccount)
- Workflow submission flow and resource management
- IRSA (IAM Roles for Service Accounts) setup
- ConfigMap and Secret management patterns

### Development & Testing  
**File:** `SANDBOX_TEST_EXECUTION.md` (252 lines)
- Running dev experiments in sandbox environment
- Testing overwrite mode and rename workflows
- VPN/network access setup (GlobalProtect, SSH tunnel)
- AWS CLI and S3 access verification
- Argo Workflows UI port forwarding
- Troubleshooting workflow execution

### Release Process
**File:** `RELEASE.md` (478 lines)
- Automated GitOps release workflow
- Dev → QA → Prod promotion process
- GitHub Actions and ArgoCD integration
- Release branch vs tag strategy
- Manual vs automated release steps

---

## 🔑 Quick Facts

### Current Branch
- **Active:** `feature/log-improvements`
- **Base:** `dev`

### Environments
- **Dev:** `ai-dev` cluster (auto-deploy from `dev` branch)
- **Sandbox:** `argo-workflows` namespace (testing)
- **QA:** `ai-qa` cluster (points to release branch)
- **Prod:** `ai-prod` cluster (points to release tag)

---

## 📝 Usage Notes

**For Augment AI:**
- This is a Table of Contents - load files on-demand based on conversation topic
- Use `view` tool to load specific files when needed
- Don't auto-load all files - only what's relevant

**For Developers:**
- Files live in `~/.augment/memory/workstation-clustering/`
- To add new knowledge: create `.md` file, then update this index
- Keep index lightweight - detailed content goes in separate files

---

## 🔗 Related

- `~/.augment/rules/coding-standards.md` - Global coding standards
