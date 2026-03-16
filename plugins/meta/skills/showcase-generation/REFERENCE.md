# Showcase Generation Reference

Templates, lint patterns, and directory structure for showcase repository.

## Markdownlint Patterns

### Consecutive Blockquotes (MD028)

**Wrong** - blank line between blockquotes:

```markdown
> First quote

> Second quote
```

**Correct** - no blank line, or use HTML separator:

```markdown
> First quote
> Second quote
```

Or with explicit break:

```markdown
> First quote

<!-- break -->

> Second quote
```

### Line Length (MD013)

Keep lines under 120 characters.
For inline code that exceeds:

**Wrong** - long inline code:

```markdown
When configuring `very_long_function_name_that_exceeds_the_line_limit()` you
should consider...
```

**Correct** - use code block instead:

```markdown
When configuring the processing function:

\`\`\`python
very_long_function_name_that_exceeds_the_line_limit()
\`\`\`
```

### Blockquote Guidelines (MD013)

For guidelines within blockquotes that exceed line length:

```markdown
Log Level Guidelines: ERROR for exceptions, WARNING for recoverable errors,
INFO for request/response summaries, DEBUG for detailed execution flow.
```

## Directory Structure

```text
matt-niedelman-imprivata/     # Repository root (no intermediate showcase/)
├── README.md                 # Entry point, "Overview" section
├── .markdownlint.json        # Lint config for showcase
│
├── case-studies/             # Multi-session arcs and learnings
│   ├── {case-name}/
│   │   ├── arc-summary.md    # Arc metadata and timeline
│   │   ├── README.md         # Narrative case study
│   │   └── examples/         # Example files mentioned in study
│   └── index.md              # Case study navigation
│
├── philosophy/               # How I think about AI-assisted development
│   ├── README.md             # Core principles
│   └── {topic}.md            # Specific topics
│
├── skills/                   # Top 5-10 impactful skills
│   └── {skill-name}/
│       ├── README.md         # Full-depth annotation
│       └── examples/         # Usage examples if helpful
│
├── rules/                    # Priority rules with impact
│   └── {rule-name}.md        # Annotated rule
│
├── agents/                   # Subagent configuration
│   └── {agent-name}.md       # Annotated agent
│
├── hooks/                    # Automation hooks
│   └── {hook-name}/
│       ├── README.md
│       └── example-output.md
│
├── external/                 # Non-augment tools
│   └── {tool-name}/
│       ├── README.md
│       └── example-rules.md
└── specs/                    # Feature specifications
```

## Source Links

Every annotated file must link to its source in the dotfiles submodule:

```markdown
# {Name} - Annotated

**Source:** [{filename}](../../dotfiles/{path}/{filename})
```

### Source Path Mapping

| Actual Location | Dotfiles Path |
| --- | --- |
| `~/.augment/rules/` | `dotfiles/dot_augment/rules/` |
| `~/.augment/skills/` | `dotfiles/dot_augment/skills/` |
| `~/.augment/agents/` | `dotfiles/dot_augment/agents/` |
| `~/.augment/hooks/` | `dotfiles/dot_augment/hooks/` |
| `~/.augment/settings.json` | `dotfiles/dot_augment/settings.json` |
| `~/.config/ast-grep/rules/` | `dotfiles/private_dot_config/ast-grep/rules/` |
| `~/.config/ruff/ruff.toml` | `dotfiles/private_dot_config/ruff/ruff.toml` |

### Link Format Examples

| Source | Link Text |
| --- | --- |
| `~/.augment/rules/core.md` | `[core.md](../../dotfiles/dot_augment/rules/core.md)` |
| `~/.config/ast-grep/rules/` | `[rules/](../../dotfiles/private_dot_config/ast-grep/rules/)` |
| `~/.config/ruff/ruff.toml` | `[ruff.toml](../../dotfiles/private_dot_config/ruff/ruff.toml)` |

**Shorten link text in tables** to stay under 120 characters per line.

## Annotation Template: Full Depth

```markdown
# {Name} - Annotated

**Source:** [{filename}](../../dotfiles/dot_augment/{category}/{filename})

## Why I Created This

{1-2 paragraphs explaining the problem I faced and why I built this solution}
## Annotation Template: Summary

```markdown
# {Name}

## Purpose

{1-2 sentence description of what this does}

## Key Points

- {Main behavior 1}
- {Main behavior 2}
- {Main behavior 3}

## Notable Choices

- {Design decision and brief rationale}

## Related Items

- [{related-item}](./{path}) - {why related}
```

## Execution Modes

### Autonomous Mode

When generating the full repository autonomously:

1. **Start with index files** - README.md, case-studies/index.md
2. **Prioritize case studies** - These require the most depth
3. **Generate config annotations** - Rules, skills, hooks
4. **Flag gaps** - Note what needs interactive enrichment from actual sessions

**Autonomous output should include:**

```markdown
## Generated Content Summary

### Created (ready for review)
- {list of files with sufficient depth}

### Needs Interactive Enrichment
- {list of files that need more depth}
- {specific questions to ask in interactive sessions}
```

### Interactive Mode

When working with the user interactively:

1. **Ask clarifying questions** - Surface insights that aren't in written notes
2. **Capture specific examples** - Real scenarios beat generic descriptions
3. **Get the "why"** - Philosophy requires understanding motivation

### Hybrid Workflow (Recommended)

1. **Autonomous**:
   Generate structure and identify gaps
2. **Interactive**:
   Enrich philosophy, top skills, and case studies
