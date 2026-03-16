---
name: structured-thinking
description: Use when facing complex debugging, architecture decisions, or investigations - leverages think-strategies MCP tools
---

# Structured Thinking

Use the `think-strategies` MCP tools when task complexity exceeds what can be
reliably handled through direct action.

## When to Use

**Complexity indicators that warrant structured thinking:**

1. **Multiple competing hypotheses** - Debugging, performance issues, flaky
   tests
2. **Significant architectural decisions** - Long-term implications, multiple
   approaches
3. **Complex refactoring or migrations** - Multi-file changes, data
   transformations
4. **Investigation and analysis** - Unfamiliar codebases, root cause analysis
5. **Multi-step planning** - Coordination across systems, careful sequencing
6. **Three-way trade-offs** - Balancing competing objectives (speed vs cost vs
   quality)

## When NOT to Use

- Simple, well-defined tasks with clear implementation paths
- Routine code changes (adding a field, fixing a typo)
- Quick lookups or information retrieval
- Following explicit user instructions with no ambiguity

**Rule of thumb**:
If you can execute in 2-3 steps without tracking state or considering
alternatives, proceed directly.

## Strategy Selection

| Problem Type | Strategy | When to Use |
|-------------|----------|-------------|
| Step-by-step solving | `linear` or `chain_of_thought` | Sequential reasoning with possible revisions |
| Debugging with hypotheses | `react` | Hypothesis → test → observe → refine cycle |
| Exploring alternatives | `tree_of_thoughts` | Multiple branches to evaluate and compare |
| Plan then execute | `rewoo` | Parallel tool usage, plan-execute workflow |
| Iterative calculations | `scratchpad` | State tracking across iterations |
| Decompose questions | `self_ask` | Break into sub-questions and answers |
| Verify reasoning | `self_consistency` | Multiple paths to consensus on high-stakes decisions |
| Abstract first | `step_back` | Establish principles before specifics |
| **Three-way trade-offs** | `trilemma` | Balance competing objectives through satisficing |

## Core Tool: think-strategies

```javascript
think-strategies_think-strategies({
  strategy: "react",           // Required: one of 10 strategies
  thought: "Current thinking step...",
  thoughtNumber: 1,
  totalThoughts: 5,            // Initial estimate, can adjust
  nextThoughtNeeded: true,
  // Optional:
  plannedActions: [...],       // Queue tool calls for think→act→reflect
  actionResults: [...],        // Results from executed tools
  action: "...",               // Strategy-specific (ReAct, ReWOO)
  observation: "...",          // Strategy-specific observation
  finalAnswer: "...",          // When thinking complete
  // For branching/revisions:
  isRevision: true,            // Mark as revision
  revisesThought: 2,           // Which thought being revised
  branchFromThought: 1,        // Create alternative path
  branchId: "alt-approach"     // Name the branch
})
```

## Key Capabilities

### Revisions

When you realize a previous thought was wrong:

```javascript
{
  thought: "My conclusion in thought 2 was incorrect because...",
  thoughtNumber: 4,
  isRevision: true,
  revisesThought: 2
}
```

### Branching

Explore alternative approaches:

```javascript
{
  thought: "Let's explore an alternative: monolithic architecture...",
  thoughtNumber: 3,
  branchFromThought: 1,
  branchId: "alt-monolith"
}
```

### Dynamic Thought Adjustment

Realize you need more analysis:

```javascript
{
  thought: "Need to examine pricing strategies before concluding...",
  thoughtNumber: 3,
  totalThoughts: 6  // Increased from original 3
}
```

### Think→Act→Reflect Workflow

```javascript
{
  thought: "Need to check current state before proceeding...",
  plannedActions: [
    { tool: "git_status_git", args: {} }
  ],
  nextThoughtNeeded: true
}
// After action executes:
{
  thought: "Git status shows 3 uncommitted files...",
  actionResults: [{ tool: "git_status_git", result: "..." }],
  nextThoughtNeeded: true
}
```

## Trilemma Strategy (Three-Way Trade-offs)

For balancing competing objectives like Speed vs Quality vs Cost:

```javascript
// Stage 1: problem_reception - identify objectives
{
  strategy: "trilemma",
  thought: "Three competing objectives: FAST (3 months), CHEAP ($100K), GOOD (high quality)...",
  thoughtNumber: 1
}

// Stage 2: objective_initialization - set thresholds
{
  thought: "Setting thresholds: FAST: 0.7, CHEAP: 0.6, GOOD: 0.5. Current: FAST: 0.9, CHEAP: 0.3, GOOD: 0.8",
  thoughtNumber: 2
}

// Stage 3-6: trade_off_evaluation and satisficing_iteration
// Stage 7: equilibrium_check - verify all thresholds met
// Stage 8: final_balance - document compromise
```

**Key concept**:
Satisficing, not optimizing.
Find "good enough" across all three rather than perfection in one.

## Anti-Patterns to Avoid

1. **Premature conclusion** - Too few thoughts for complex problems
2. **Unfocused thoughts** - Rambling without clear progression
3. **Ignoring errors** - Continuing despite noticing reasoning mistakes (use
   `isRevision`)
4. **Excessive branching** - Many branches without synthesis
5. **Not adjusting** - Sticking to initial thought count when more analysis
   needed

## Session Management

Use `think-session-manager` for persistence:

```javascript
// List recent sessions
think-session-manager({ action: "list", limit: 10 })

// Resume a session
think-session-manager({ action: "resume", sessionId: "abc123" })
```

## Examples

```text
❌ "Add a created_at field to the User model"
   → Direct action. Simple, well-defined.

✅ "Why does payment processing sometimes fail?"
   → react strategy. Multiple hypotheses, need investigation.

✅ "Design the caching layer for the API"
   → tree_of_thoughts. Multiple approaches to compare.

✅ "Migrate from REST to GraphQL without breaking clients"
   → rewoo strategy. Complex multi-step with parallel tasks.

✅ "Ship feature fast but also cheap and high quality"
   → trilemma strategy. Three-way trade-off requiring satisficing.
```

## Integration

- Document conclusions in basic-memory via `knowledge-capture` skill
- Use `plannedActions` to integrate with any available MCP tools
- Sessions persist for resumption across conversations
