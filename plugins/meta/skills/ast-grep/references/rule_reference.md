# ast-grep Rule Reference

This document provides comprehensive documentation for ast-grep rule syntax,
covering all rule types and metavariables.

## Introduction to ast-grep Rules

ast-grep rules are declarative specifications for matching and filtering
Abstract Syntax Tree (AST) nodes.
They enable structural code search and analysis by defining conditions an AST
node must meet to be matched.

### Rule Categories

ast-grep rules are categorized into three types:

* **Atomic Rules**:
  Match individual AST nodes based on intrinsic properties like code patterns
  (`pattern`), node type (`kind`), or text content (`regex`).
* **Relational Rules**:
  Define conditions based on a target node's position or relationship to other
  nodes (e.g., `inside`, `has`, `precedes`, `follows`).
* **Composite Rules**:
  Combine other rules using logical operations (AND, OR, NOT) to form complex
  matching criteria (e.g., `all`, `any`, `not`, `matches`).

## Rule Object Properties

| Property | Type | Category | Purpose | Example |
| :--- | :--- | :--- | :--- | :--- |
| `pattern` | String or Object | Atomic | Matches AST node by code pattern. | `pattern: console.log($ARG)` |
| `kind` | String | Atomic | Matches AST node by its kind name. | `kind: call_expression` |
| `regex` | String | Atomic | Matches node's text by Rust regex. | `regex: ^[a-z]+$` |
| `nthChild` | number, string, Object | Atomic | Matches nodes by their index within parent's children. | `nthChild: 1` |
| `range` | RangeObject | Atomic | Matches node by character-based start/end positions. | `range: { start: { line: 0, column: 0 }, end: { line: 0, column: 10 } }` |
| `inside` | Object | Relational | Target node must be inside node matching sub-rule. | `inside: { pattern: class $C { $$$ }, stopBy: end }` |
| `has` | Object | Relational | Target node must have descendant matching sub-rule. | `has: { pattern: await $EXPR, stopBy: end }` |
| `precedes` | Object | Relational | Target node must appear before node matching sub-rule. | `precedes: { pattern: return $VAL }` |
| `follows` | Object | Relational | Target node must appear after node matching sub-rule. | `follows: { pattern: import $M from '$P' }` |
| `all` | Array<Rule> | Composite | Matches if all sub-rules match. | `all: [ { kind: call_expression }, { pattern: foo($A) } ]` |
| `any` | Array<Rule> | Composite | Matches if any sub-rules match. | `any: [ { pattern: foo() }, { pattern: bar() } ]` |
| `not` | Object | Composite | Matches if sub-rule does not match. | `not: { pattern: console.log($ARG) }` |
| `matches` | String | Composite | Matches if predefined utility rule matches. | `matches: my-utility-rule-id` |

## Atomic Rules

### pattern: String and Object Forms

The `pattern` rule matches a single AST node based on a code pattern.

**String Pattern**:
Directly matches using ast-grep's pattern syntax with metavariables.

```yaml
pattern: console.log($ARG)
```

**Object Pattern**:
Offers granular control for ambiguous patterns or specific contexts.

* `selector`:
  Pinpoints a specific part of the parsed pattern to match.
* `context`:
  Provides surrounding code context for correct parsing.
* `strictness`:
  Modifies the pattern's matching algorithm (`cst`, `smart`, `ast`, `relaxed`,
  `signature`).

### kind: Matching by Node Type

The `kind` rule matches an AST node by its `tree_sitter_node_kind` name.

```yaml
kind: call_expression
```

### regex: Text-Based Node Matching

The `regex` rule matches the entire text content of an AST node using a Rust
regular expression.

### nthChild: Positional Node Matching

Finds nodes by their 1-based index within their parent's children list.

## Relational Rules

### inside: Matching Within a Parent Node

```yaml
inside:
  pattern: class $C { $$$ }
  stopBy: end
```

### has: Matching with a Descendant Node

```yaml
has:
  pattern: await $EXPR
  stopBy: end
```

### precedes and follows: Sequential Node Matching

* `precedes`:
  Target node must appear before a node matching the sub-rule.
* `follows`:
  Target node must appear after a node matching the sub-rule.

### stopBy and field: Refining Relational Searches

**stopBy**:
Controls search termination for relational rules.

* `"neighbor"` (default):
  Stops when immediate surrounding node doesn't match.
* `"end"`:
  Searches to the end of the direction.
* `Rule object`:
  Stops when a surrounding node matches the provided rule.

**Best Practice**:
Always use `stopBy:
end` to ensure complete traversal.

## Composite Rules

### all: Conjunction (AND) of Rules

```yaml
all:
  - kind: call_expression
  - pattern: console.log($ARG)
```

### any: Disjunction (OR) of Rules

```yaml
any:
  - pattern: console.log($ARG)
  - pattern: console.warn($ARG)
```

### not: Negation (NOT) of a Rule

```yaml
not:
  pattern: console.log($ARG)
```

## Metavariables

### $VAR: Single Named Node Capture

Captures a single named node in the AST.

* **Example**:
  `console.log($GREETING)` matches `console.log('Hello World')`.
* **Reuse**:
  `$A == $A` matches `a == a` but not `a == b`.

### $$VAR: Single Unnamed Node Capture

Captures a single unnamed node (e.g., operators, punctuation).

### $$$MULTI: Multi-Node Capture

Matches zero or more AST nodes (non-greedy).

* **Example**:
  `console.log($$$)` matches `console.log()`, `console.log('hello')`, etc.

### Non-Capturing Metavariables (_VAR)

Metavariables starting with `_` are not captured and can match different
content.

## Common Patterns

### Find Functions with Specific Content

```yaml
rule:
  kind: function_declaration
  has:
    pattern: await $EXPR
    stopBy: end
```

### Find Code Inside Specific Contexts

```yaml
rule:
  pattern: console.log($$$)
  inside:
    kind: method_definition
    stopBy: end
```

### Find Code Missing Expected Patterns

```yaml
rule:
  all:
    - kind: function_declaration
    - has:
        pattern: await $EXPR
        stopBy: end
    - not:
        has:
          pattern: try { $$$ } catch ($E) { $$$ }
          stopBy: end
```
