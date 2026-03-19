---
status: Proposed
date: 2026-02-17
decision-makers: []
consulted: []
---

# ADR-004: Release Strategy

# Context

Imprivata AI Engineering projects currently applies a manual release process
that is error prone, inconsistent, and inefficient.

Here we outline the current release process, the gaps in the current process,
and a proposed automation plan to address these gaps.

---

## Current Release Process

The current release process involves manual steps for creating releases, tags,
and updating GitOps configurations:

```text
1. [project] Merge to dev → Auto-deploy to ai-dev cluster
2. [project] Create release branch (eg. release/v1.2.3)
3. [project] Manually create and push tag (v1.2.3)
4. [project] Merge release branch to main
5. [gitops-apps] PR to update QA to point to release branch (release/v1.2.3)
6. [gitops-apps] Merge PR → Auto-deploy to ai-qa cluster
7. [gitops-apps] PR to update Prod to point to tag (v1.2.3)
8. [gitops-apps] Merge PR → Auto-deploy to ai-prod cluster
```

**Key Point:** The **gitops-apps** repo controls which version (tag/branch) of
the project repo is deployed to each environment.
When updating the `targetRevision` in gitops-apps, ArgoCD pulls the code from
the project repo at that specific tag/branch.

**QA vs Prod Deployment:**
- **QA** typically points to the **release branch** (e.g., `release/v1.2.3`) to
  allow for last-minute fixes
- **Prod** points to the **release tag** (e.g., `v1.2.3`) for immutable
  deployments
- QA and Prod are updated **separately** via different PRs to gitops-apps

---

### Step-by-Step Process

#### 1. Development & Testing (dev branch)

- Developers merge feature branches into `dev` via PRs
- GitHub Actions automatically:
  - Runs linting (MegaLinter)
  - Builds and pushes Docker image to ECR with tag format:
    `<git-sha>`
  - Builds and pushes Docker image to GHCR
  - Publishes Helm chart to GHCR with version:
    `0.0.0-dev.<git-sha>`
- ArgoCD automatically deploys to **ai-dev cluster** (because gitops-apps points
  dev environment to `dev` branch)

**Verification:**
```bash
# Check deployment status
kubectl get pods -n {project-ns}
# Check workflows
kubectl get workflows -n {project-ns}
# View logs
kubectl logs -n {project-ns} -l app.kubernetes.io/name={project-name} -f
```

**GitOps Configuration:**
- File:
  `gitops-apps/argocd/apps/{project-name}/.argocd.yaml`
- Dev settings:
  ```yaml
  dev:
    enabled: true
    targetRevision: dev  # Tracks dev branch
  ```

---

#### 2. Create Release Branch

When ready to promote to QA/Production, create release branch off `dev` using
semantic versioning:
- GitHub Actions builds and pushes images for the release branch
- Helm chart is published with version:
  `0.0.0-dev.release-v1-2-3-<git-sha>`

---

#### 3. Create Release Tag (MANUAL STEP)

Manually create and push the release tag:
```bash
# On the release branch
git checkout release/v1.2.3
git tag -a v1.2.3 -m "Release v1.2.3: <brief description>"
git push origin v1.2.3
```

- GitHub Actions builds and pushes images with tag:
  `<git-sha>`
- Helm chart is published with semantic version:
  `1.2.3`
- Also creates chart versions:
  `1.2` and `1` (if not v0.x)

**Verify release artifacts:**
- Docker image:
  `439323037767.dkr.ecr.us-east-2.amazonaws.com/{project-name}:<git-sha>`
- Helm chart:
  `oci://ghcr.io/imprivata-ai/charts/{project-name}:1.2.3`

---

#### 4. Merge Release to Main

Create PR to merge release branch into main
- GitHub Actions builds and pushes images from main branch
- Helm chart published with version:
  `0.0.0-main.<git-sha>`

---

#### 5. Update GitOps for QA Deployment

Create a PR to update `argocd/apps/{project-name}/.argocd.yaml` for QA:
   ```bash
   git checkout -b update-{project-name}-qa-v1.2.3
   ```

   ```yaml
   clusters:
     qa:
       enabled: true
       targetRevision: release/v1.2.3  # ← Update to point to release branch
   ```

- ArgoCD pulls code from **project repo** at release branch `release/v1.2.3`
- ArgoCD automatically syncs and deploys to **QA environment** (ai-qa cluster)

---

#### 6. Update GitOps for Production Deployment

After QA validation, create a separate PR to update production:
   ```bash
   git checkout -b update-{project-name}-prod-v1.2.3
   ```

   ```yaml
   clusters:
     prod:
       enabled: true
       targetRevision: v1.2.3  # ← Update to point to the tag (not branch)
   ```

- ArgoCD pulls code from **project repo** at tag `v1.2.3`
- ArgoCD automatically syncs and deploys to **Production environment** (ai-prod
  cluster)

---

## Environment Overview

### Deployment Targets

| Environment | Cluster | Namespace    | Branch/Tag Tracked (from project repo)   | Auto-Deploy            | Purpose                           |
|-------------|---------|--------------|------------------------------------------|------------------------|-----------------------------------|
| **Dev**     | ai-dev  | {project-ns} | `dev` branch                             | ✅ Yes (direct)        | Development & integration testing |
| **QA**      | ai-qa   | {project-ns} | Release branch (e.g., `release/v1.2.3`)  | ✅ Yes (via GitOps PR) | Pre-production validation         |
| **Prod**    | ai-prod | {project-ns} | Release tags (e.g., `v1.2.3`)            | ✅ Yes (via GitOps PR) | Production                        |

### Artifact Locations

**Docker Images:**
- **ECR (Primary):**
  `439323037767.dkr.ecr.us-east-2.amazonaws.com/{project-name}:<tag>`
- **GHCR (Mirror):** `ghcr.io/imprivata-ai/{project-name}:<tag>`

**Helm Charts:**
- **GHCR OCI Registry:**
  `oci://ghcr.io/imprivata-ai/charts/{project-name}:<version>`

### Version Naming Conventions

| Trigger              | Docker Image Tag | Helm Chart Version     | Example              |
|----------------------|------------------|------------------------|----------------------|
| Push to `dev`        | `<git-sha>`      | `0.0.0-dev.<git-sha>`  | `0.0.0-dev.abc1234`  |
| Push to `main`       | `<git-sha>`      | `0.0.0-main.<git-sha>` | `0.0.0-main.def5678` |
| Release tag `v1.2.3` | `<git-sha>`      | `1.2.3`, `1.2`, `1`    | `1.2.3`              |

---

## Missing Pieces and Best Practices

### What's Missing in the Current Manual Process

The current manual release process has several gaps that create risk and
inefficiency:

**1.
No Automated Changelog Management**
- ❌ Changelogs are manually maintained (or not maintained at all)
- ❌ Easy to forget to document changes before release
- ❌ No single source of truth for "what changed in this release"

**2.
Manual Version Bumping**
- ❌ Developers must manually decide:
  is this a major, minor, or patch release?
- ❌ Version numbers in multiple files (`pyproject.toml`, `Chart.yaml`) must be
  updated manually
- ❌ Risk of inconsistent versions across files
- ❌ No enforcement of semantic versioning conventions

**3.
Manual Tag Creation**
- ❌ Tags must be manually created and pushed
- ❌ Easy to forget to tag after merging to main
- ❌ No validation that tag matches version in code

**4.
Manual GitOps Updates**
- ❌ Requires manual PR creation in gitops-apps repository
- ❌ No automated validation that the version exists before deploying

**5.
No Automated Dependency Updates**
- ❌ Security vulnerabilities in dependencies go unnoticed
- ❌ Manual monitoring of dependency updates is time-consuming
- ❌ No systematic process for keeping dependencies up-to-date

### Why These Gaps Matter

Proper release documentation and versioning are critical for:

**1.
Team Communication & Transparency**
- **Changelog** provides a clear history of what changed and when
- **Release notes** communicate user-facing changes to stakeholders
- **Versioning** signals the impact of changes (breaking vs. non-breaking)
- Helps QA/DS leads understand what needs testing before approval

**2.
Debugging & Troubleshooting**
- When production issues occur, changelog helps identify which changes caused
  the problem
- Version numbers make it easy to identify exactly what code is running in each
  environment
- Enables quick identification of known-good versions for deployment rollback

**3.
Compliance & Auditability**
- Provides audit trail of all changes deployed to production
- Documents who approved releases and when
- Required for regulatory compliance in many industries

**4.
Dependency Management**
- Semantic versioning (MAJOR.MINOR.PATCH) helps downstream consumers understand
  compatibility
- Breaking changes (MAJOR bump) signal when updates require code changes
- Minor/patch bumps signal safe updates

**5.
Stakeholder Confidence**
- Well-maintained release notes show professionalism and care
- Helps product managers communicate changes to customers
- Builds trust with users and stakeholders

### How Automation Addresses These Gaps

The proposed automation directly addresses each gap in the current process:

| Gap in Manual Process    | Automation Solution                                     | Benefit                                                 |
|--------------------------|---------------------------------------------------------|---------------------------------------------------------|
| No automated changelog   | release-please auto-generates from PR titles            | Consistent, complete changelogs with zero manual work   |
| Manual version bumping   | release-please auto-bumps based on conventional commits | Correct semver bumps, no human decision needed          |
| Manual tag creation      | GitHub Actions auto-creates tags after tests pass       | Tags always created, always match code version          |
| Manual GitOps updates    | GitHub Actions auto-creates gitops-apps PRs             | Faster deployments, no typos, validated versions        |
| No dependency monitoring | Dependabot scans and creates PRs for updates            | Security fixes applied quickly, dependencies stay fresh |

### Best Practices and Key Principles

**1.
Automate the tedious, review the important**
- Automate:
  changelog generation, version bumps, PR creation, dependency updates
- Keep human review for:
  Release PR approval, GitOps PR approval, production promotion decisions

**2.
Make it easy to do the right thing**
- Automation makes it easier to follow the process than to skip it
- Templates and workflows ensure consistency without extra effort
- Conventional commits are enforced via PR title validation

**3.
Fail fast, recover quickly**
- Automated checks catch issues early (linting, tests, version validation)
- Staged rollout (dev → QA → prod) catches problems before they reach
  production
- Version tagging enables quick deployment rollback if needed

**4.
Document everything automatically**
- Every release has:
  changelog, version bump, release notes, approval trail
- No manual documentation means no forgotten documentation
- Audit trail is built into the process, not added as an afterthought

---

## Proposed Release Process


### Overview

The release process is proposed with the following goals:

1. ✅ **Automated Dependency Updates** (via Dependabot)
2. ✅ **Automated Changelog & Versioning** (via release-please)
3. ✅ **Automated Release Creation** (via GitHub Actions)
4. ✅ **Staged GitOps Deployment** (QA auto-deploys, Prod requires approval)

### Workflows


#### 1. Automated Dependency Updates
Dependabot automatically scans external package registries (PyPI, Docker Hub,
GitHub, Helm repositories) for newer dependencies version and creates PRs to
update them:
- Periodic scans for dependency updates
  - Respects version constraints in `pyproject.toml`
  - Major version updates create individual PRs
- N-day cooldown prevents updating to buggy new releases (security updates
  bypass cooldown)
- **All Dependabot PRs auto-merge** after CI passes
- CI tests catch cross-ecosystem incompatibilities (e.g., Docker Python version
  mismatch)
  - CI tests catch cross-ecosystem incompatibilities

**Grouping strategy:**

| Ecosystem                | Files Tracked               | Grouping            | Cooldown |
|--------------------------|----------------------------|---------------------|----------|
| Python (pip)             | `pyproject.toml`, `uv.lock` | Minor/patch grouped | 14 days  |
| Python (opentelemetry-*) | `pyproject.toml`, `uv.lock` | Grouped separately  | 14 days  |
| Docker                   | `Dockerfile`                | Individual PRs      | 14 days  |
| GitHub Actions           | `.github/workflows/*.yml`   | All grouped         | 7 days   |
| Helm                     | `Chart.yaml`                | All grouped         | 14 days  |


**Files:** `.github/dependabot.yml`,
`.github/workflows/dependabot-automerge.yml`

---

#### 2. Automated Changelog & Versioning

`release-please` automatically generates changelogs and bumps versions based on
conventional commit messages.

**Trigger:** Push to `dev` branch

1. **Job 1:** Creates/updates "Prepare-Release PR" with:
   - Updated CHANGELOG.md (one entry per squashed PR)
   - Version bump in `pyproject.toml` and `Chart.yaml`
2. **Job 2:** Creates `dev` → `main` PR (if doesn't exist)

**Files:** `.github/workflows/prepare-release.yml`,
`release-please-config.json`, `.release-please-manifest.json`

**Version bump rules:**
- `feat:` → MINOR (1.0.0 → 1.1.0)
- `fix:` → PATCH (1.0.0 → 1.0.1)
- `feat!:` or `fix!:` → MAJOR (1.0.0 → 2.0.0)
- `docs:`, `chore:`, `ci:` → No bump

**PR title validation:**
- `.github/workflows/pr-title.yml` enforces conventional commits
- Valid types:
  `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`,
  `chore`
- Breaking changes:
  Add `!` after type (e.g., `feat!:`)

---

#### 3. Automated Release Creation
Fully automated via GitHub Actions.

**Trigger:** Merge `dev` → `main` PR
1. Waits for Test, Docker, and Helm workflows to complete on `main`
2. Validates all workflows succeeded (skips if any failed)
3. Reads version from `pyproject.toml` (e.g., `1.2.3`)
4. Creates git tag `1.2.3` (**no `v` prefix**)
5. Creates GitHub Release with:
   - Release notes from CHANGELOG.md
   - OpenAPI spec attachment (`openapi-1.2.3.json`)
6. Triggers `deploy-qa.yml`

**File:** `.github/workflows/create-release.yml`

---

#### 4. Staged GitOps Deployment

Staged rollout with QA auto-deploy, Prod manual.


**Stage 1:
QA (Automatic)**
- **Trigger:** GitHub Release published
- **Actions:**
  - Updates `gitops-apps/.argocd.yaml`:
    `clusters.qa.targetRevision = "1.2.3"`
  - Copies `values.qa.yaml` to gitops-apps (if exists)
  - Creates PR:
    `[QA] Deploy workstation-clustering 1.2.3`
- **Deploy:** Merge PR → ArgoCD deploys to QA

**Stage 2:
Production (Manual)**
- **Trigger:** Actions → "Promote to Production" → Run workflow
- **Inputs:**
  - `version`:
    e.g., `1.2.3` (no `v` prefix)
  - `skip_qa_check`:
    Emergency bypass (default:
    false)
- **Validation:** Verifies QA is on this version (unless skipped)
- **Actions:**
  - Updates `gitops-apps/.argocd.yaml`:
    `clusters.prod.targetRevision = "1.2.3"`
  - Copies `values.prod.yaml` to gitops-apps (if exists)
  - Creates PR:
    `[PROD] Deploy workstation-clustering 1.2.3`
- **Deploy:** Review + Merge PR → ArgoCD deploys to Production

**Key points:**
- Both QA and Prod point to immutable tags (not branches)
- QA version check prevents deploying to Prod before QA validation

**Files:** `.github/workflows/deploy-qa.yml`,
`.github/workflows/promote-to-prod.yml`

**Prerequisites:** `GITOPS_PAT` secret with access to `imprivata-ai/gitops-apps`

---

#### 5. Rollback Capability

⚠️ **MANUAL PROCESS**

1. Identify previous stable version from GitHub Releases (e.g., `1.2.2`)
2. Go to Actions → "Promote to Production" → Run workflow
3. Enter previous version `1.2.2` (no `v` prefix)
4. Check "Skip QA version check" (emergency bypass)
5. Review and merge rollback PR in gitops-apps

**Why manual:**
- ML failures are subtle and not caught by simple health checks
- Forces team to understand root cause
- Simpler to implement and maintain

**Future:** Consider automated rollback with monitoring/alerting infrastructure
and canary deployments

---
