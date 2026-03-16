# Desloppify Subjective Review

You are performing a holistic code quality review for desloppify integration.

## Context

- Repository:
  {{REPO_PATH}}
- Query file:
  {{QUERY_JSON_PATH}}

## Your Task

1. Run `uvx desloppify review --prepare` if query.json does not exist
2. Read the query.json file to get:
   - Dimension definitions
   - Language-specific guidance
   - Files to review
3. Perform holistic review (see process below)
4. Output findings.json
5. Run `uvx desloppify review --import findings.json`
6. Report summary

## Review Process

### Phase 1: Structural Overview

Before scoring any dimension:

1. List the directory structure (`view .
   type=directory`)
2. Identify key modules/components
3. Note patterns you observe:
   - Naming conventions used
   - Error handling approaches
   - Abstraction patterns
   - Code organization style
4. Form initial impressions

### Phase 2: Dimension Assessment

For each of the 12 dimensions, provide:

- **Score (0-100)**:
  Be calibrated.
  95+ is genuinely excellent.
- **Evidence**:
  Specific observations justifying the score
- **Findings**:
  For scores below 100, specific issues with file references

#### Dimension Definitions

| Dimension | What to Assess |
|-----------|----------------|
| high_elegance | Architecture patterns, overall design coherence |
| mid_elegance | Module and class-level design quality |
| low_elegance | Function and method-level craftsmanship |
| contracts | API clarity, interface definitions, boundary design |
| type_safety | Type hint coverage, type correctness, inference |
| design_coherence | Consistency of design decisions across codebase |
| abstraction_fit | Right level of abstraction, not over/under-engineered |
| logic_clarity | Readability, intent expression, self-documenting code |
| structure_nav | Navigability, discoverability, organization |
| error_consistency | Error handling patterns, consistency |
| naming_quality | Naming conventions, clarity, consistency |
| ai_generated_debt | Signs of vibe coding slop, copy-paste patterns |

## Output Format

Create `findings.json` with this exact schema:

```json
{
  "assessments": {
    "high_elegance": <score>,
    "mid_elegance": <score>,
    "low_elegance": <score>,
    "contracts": <score>,
    "type_safety": <score>,
    "design_coherence": <score>,
    "abstraction_fit": <score>,
    "logic_clarity": <score>,
    "structure_nav": <score>,
    "error_consistency": <score>,
    "naming_quality": <score>,
    "ai_generated_debt": <score>
  },
  "findings": [
    {
      "dimension": "<dimension_name>",
      "identifier": "<unique-kebab-case-id>",
      "summary": "<one line description>",
      "related_files": ["<file1>", "<file2>"],
      "evidence": "<specific observation>",
      "suggestion": "<how to fix>",
      "confidence": "high|medium|low"
    }
  ],
  "dimension_notes": {
    "<dimension>": {
      "evidence": "<overall observations for this dimension>"
    }
  }
}
```

## Rules

1. **Scores require evidence**:
   Any score below 100 must have findings
2. **Multiple findings for low scores**:
   Scores below 95 need multiple findings
3. **Be specific**:
   Reference actual files, functions, patterns
4. **Be calibrated**:
   Do not grade inflate.
   80 is acceptable.
   95+ is excellent.
5. **Cross-cutting insights**:
   Note patterns that span multiple files

## After Review

1. Save findings.json to repository root
2. Run:
   `uvx desloppify review --import findings.json`
3. Report:
   "Review complete.
   Imported N findings across M dimensions."
4. Show:
   Score summary and top 3 priority findings
