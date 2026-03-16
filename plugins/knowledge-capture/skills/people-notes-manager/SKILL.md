---
name: people-notes-manager
description: Use when updating person notes from GitHub activity, processing meeting transcripts to extract people insights, or adding ad-hoc observations about colleagues - manages the knowledge/people/ directory
---

# People Notes Manager

Keeps the knowledge graph of people current through GitHub MCP server queries,
Zoom meeting transcripts, and ad-hoc conversational updates.

## When to Use

- "Update people notes from GitHub"
- "Refresh contributor data"
- "Process these meeting notes:
  [paste]"
- "Add note about Brian:
  [insight]"
- Periodic refresh of team contributor activity

## Three Operating Modes

| Mode | Input | Output |
|------|-------|--------|
| **GitHub Refresh** | Scan `imprivata-ai` org | Update all person notes with commit/PR/review data |
| **Meeting Notes** | Zoom AI transcript | Person updates + decisions/actions/topics to knowledge base |
| **Ad-hoc Update** | Conversational insight | Targeted update to specific person's note |

## Update Philosophy

| Data Type | Gather | Write |
|-----------|--------|-------|
| **Factual** (commits, repos, collaboration) | Automatic | Auto-update silently |
| **Subjective** (communication style, expertise, growth areas) | Automatic | Present for approval before writing |
| **New people** | Automatic | Auto-create minimal note, ask for team assignment |

**Key principle:** Always gather all available data during a refresh.
The approval gate is on *writing* subjective insights to notes, not on
*retrieving* the data.
Present a complete picture of what was learned, then ask which subjective
updates to apply.

---

## Mode 1: GitHub Refresh

### Step 1: Gather Org Data

```python
# Search for PRs by author in org
search_pull_requests_github(
    query=f"author:{username} org:imprivata-ai", owner="imprivata-ai"
)

# List commits for a repo (filter by author)
list_commits_github(owner="imprivata-ai", repo="{repo}", author=username)

# Get PR details including reviews
pull_request_read_github(
    method="get", owner="imprivata-ai", repo="{repo}", pullNumber=pr_number
)
pull_request_read_github(
    method="get_reviews", owner="imprivata-ai", repo="{repo}", pullNumber=pr_number
)
```

### Step 2: Aggregate Per Person

For each contributor, calculate:

- Total commits across all repos
- Primary repositories (ranked by commit count)
- PRs authored (count, recent)
- Reviews given (count, to whom)
- Collaboration graph (frequent reviewers/reviewees)

### Step 3: Match to Existing Notes

```python
# List existing person notes
list_directory_basic - memory(dir_name="/knowledge/people", depth=3)

# Match by GitHub username (from frontmatter) or name
```

**If person exists:** Update factual fields directly, propose subjective
changes.

**If person is new:** Auto-create using template, prompt for team:

```text
Found new contributor @username (47 commits across 3 repos).
Which team? [ai-engineering / mle / other]
```

### Step 4: Gather Subjective Insights

**Always analyze during refresh (no explicit request needed):**

```python
# Search recent PRs by author
search_pull_requests_github(query=f"author:{username} org:imprivata-ai", perPage=10)

# Get PR details including body
pull_request_read_github(
    method="get", owner="imprivata-ai", repo="{repo}", pullNumber=pr_number
)

# Search reviews given by this person
search_pull_requests_github(query=f"reviewed-by:{username} org:imprivata-ai")

# Get review details
pull_request_read_github(
    method="get_reviews", owner="imprivata-ai", repo="{repo}", pullNumber=pr_number
)
```

**Analyze for:**

| Insight Type | Data Source | What to Look For |
|--------------|-------------|------------------|
| Communication Style | PR descriptions, review comments | Structure, tone, thoroughness |
| Technical Strengths | Repos contributed to, file types | Primary technologies, patterns |
| Domain Expertise | Commit messages, PR titles | Product areas, specializations |
| Collaboration Patterns | Reviews given/received | Key working relationships |

### Step 5: Update Notes

**Auto-update these fields (no approval needed):**

- Summary → Total Commits
- Summary → Primary Repositories
- Relations → contributes_to entries

**Present for approval before writing:**

- Technical Strengths (inferred from repo types)
- Domain Expertise (inferred from commit patterns)
- Communication Style (from PR descriptions/reviews)
- Work Style Characteristics (from PR patterns)

**Output format for subjective insights:**

```markdown
## Proposed Updates for [Person Name]

### Communication Style
**Current:** [existing content or "Not documented"]
**Proposed addition:** "PR descriptions are highly structured with clear sections..."
**Evidence:** PR #123, PR #456

### Technical Strengths
**Current:** #python, #api-development
**Proposed addition:** #kubernetes-deployment, #helm
**Evidence:** 15 commits to gitops-apps, 8 to helm charts

Apply these updates? [all / select / skip]
```

---

## Mode 2: Meeting Notes Processing

### Step 1: Accept Input

User pastes Zoom AI transcript/summary.

### Step 2: Extract Participants

Match names to existing person notes using:

- Exact name match
- First name match
- Aliases from frontmatter

Prompt for unknown participants:

```text
Found unknown participant "Sarah Chen" - create new person note? [yes + ask team / skip]
```

### Step 3: Extract Knowledge Items

| Type | Pattern | Destination |
|------|---------|-------------|
| **Decisions** | "We decided...", "Agreed to..." | Link to relevant spec/project |
| **Action items** | "X will...", "TODO:", assignments | Create in `todos/` or `planning/tasks/` |
| **Topics** | Project/repo/technology mentions | Link to existing notes |
| **People insights** | Observations about communication, expertise | Queue for person note update |

### Step 4: Present Extracted Items

```markdown
## Extracted from Meeting

### Decisions
- Use Hasura for data fabric API → links to [[Design: Cross-Product Data Fabric API]]

### Action Items
- [ ] Alice to review PR by Friday
- [ ] Bob to set up OTEL dashboard

### People Insights (require approval)
- **Brian**: Raised operational concerns about webhook handling
- **Katie**: Demonstrated deep knowledge of Kubernetes networking
```

### Step 5: Apply Updates

- Auto-apply:
  decisions, action items, topic links
- Require approval:
  people insights before updating person notes

---

## Mode 3: Ad-hoc Update

### Step 1: Identify Person

Parse the input for a name, match to existing notes.

If ambiguous:
"Did you mean Brian Pomerantz or Brian Smith?"

### Step 2: Classify Insight

| Insight Type | Target Section |
|--------------|----------------|
| Skill/strength | Technical Strengths or Domain Expertise |
| Communication pattern | Communication Style |
| Growth interest | Professional Development Areas |
| Work preference | Work Style Characteristics |
| Collaboration note | Key Collaborations |
| Growth opportunity | Areas for Growth/Improvement |

### Step 3: Present Proposed Update

```markdown
**Update to Brian Pomerantz:**

Section: Professional Development Areas → Leadership Growth
Add: "Increasingly effective at unblocking team members"

Apply? [yes / edit / skip]
```

### Step 4: Optionally Add Observation

For significant insights, also add to Observations section:

```markdown
- [insight] Increasingly effective at unblocking team members #leadership
```

---

## Person Note Template Reference

New notes follow `guidelines/person-note-template.md`:

**Required sections:** Summary, Technical Strengths, Domain Expertise, Key
Collaborations, Relations

**Optional sections:** Communication Style, Professional Development, Work
Style, Areas for Growth

**Frontmatter must include:**

```yaml
github: username  # For matching during refresh
```

---

## Edge Cases

| Situation | Handling |
|-----------|----------|
| GitHub username not in note | Prompt to add during first refresh |
| Stale repo in person note | Flag: "Brian hasn't committed to X in 6 months - still primary?" |
| Team contribution shift | Flag for potential team reassignment |
| Ambiguous name match | Prompt for clarification |
| API rate limit | Batch requests, cache within session |
