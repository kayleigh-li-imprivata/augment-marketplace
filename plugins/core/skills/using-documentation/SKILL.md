---
name: using-documentation
description: Use when accessing library documentation, asking about software capabilities, or checking what a tool can do - starts with llms.txt, falls back to crwl if web-fetch fails
---

# Using Documentation

This skill helps access library/framework documentation effectively using the
docs-crawler MCP server and Basic Memory integration.

## When to Use

Use this skill when:

- Working with a new library or framework
- Need API reference or examples for a library
- User asks "how do I use X?", "what's the API for Y?"
- **User asks about the capabilities of software** ("can X do Y?", "does X
  support Y?", "what can X do?")
- Designing a feature using external libraries
- Implementing code that depends on library behavior
- User mentions a library/framework and needs guidance
- **Before starting work** on any task involving libraries or frameworks

## Prerequisites

The `docs-crawler` MCP server must be configured in Augment settings.

## Pre-Work Documentation Check (CRITICAL)

**Before starting work** on any task involving a library, framework, tool, or
service, check if documentation has already been crawled.

## Workflow

### 1. Check If Documentation Exists

First, check if we already have crawled documentation:

```python
# By URL
mcp__docs-crawler__check_docs(source_url="https://docs.pydantic.dev/")

# By name
mcp__docs-crawler__check_docs(source_name="pydantic")
```

### 2. Decision: Crawl or Use Existing

**If docs don't exist:**

- Ask user if they want to crawl the documentation
- Determine appropriate depth ("quick" for basics, "deep" for comprehensive)

**If docs exist but are stale (>30 days):**

- Suggest refresh if the library has likely been updated
- Use existing if user needs info quickly

**If docs exist and fresh:**

- Proceed to search/retrieve

### 3. Crawl Documentation (When Needed)

```python
# Quick crawl - gets overview, main concepts, key APIs
mcp__docs-crawler__crawl_docs(
    url="https://docs.library.com/",
    depth="quick",
    wait=True  # or False for background
)

# Deep crawl - comprehensive documentation
mcp__docs-crawler__crawl_docs(
    url="https://docs.library.com/",
    depth="deep",
    wait=True
)
```

### 4. Search for Information

After docs are stored, use Basic Memory to find specific info:

```python
# Search for specific topic
mcp__basic-memory__search_notes(
    query="pydantic field validation",
    tags=["docs", "pydantic"]
)

# Build context around a concept
mcp__basic-memory__build_context(
    url="memory://docs/pydantic/*",
    depth=2
)
```

## Depth Strategy Guide

| Scenario | Recommended Depth |
| -------- | ----------------- |
| Quick API lookup | quick |
| Learning new library | deep |
| Troubleshooting specific issue | quick |
| Comprehensive design work | deep |
| Time-sensitive task | quick |
| New team member onboarding | deep |

## Available Tools

| Tool | Purpose |
| ---- | ------- |
| `check_docs` | Check if docs exist for a source |
| `crawl_docs` | Crawl and store documentation |
| `crawl_status` | Check status of async crawl |
| `list_sources` | List all crawled doc sources |
| `refresh_docs` | Re-crawl an existing source |

## Example Conversations

**User:** "I need to use Pydantic for validation"

1. Check if Pydantic docs exist
2. If not:
   "I can crawl the Pydantic docs.
   Quick overview or deep dive?"
3. If yes:
   Search for validation-related content
4. Present relevant information organized by use case

**User:** "How does FastAPI handle dependency injection?"

1. Check for FastAPI docs
2. Search reasoning pillar for "dependency injection"
3. Search examples pillar for DI patterns
4. Synthesize into clear explanation with examples

**User:** "What's the signature for httpx.AsyncClient.get?"

1. Check for httpx docs
2. Search memory pillar for "AsyncClient.get"
3. Return exact signature and parameters

## Capability Questions Workflow

When asked about software capabilities ("can X do Y?", "does X support Y?",
"what features does X have?"):

1. **Try llms.txt first** - Fetch `https://docs.example.com/llms.txt` or
   `https://example.com/llms.txt`
2. **Use web-fetch for specific pages** - If llms.txt lists relevant pages
3. **Fall back to crwl** - If web-fetch fails (403, rate-limited, bot-blocked),
   use the `crwl` tool:
   ```bash
   crwl <url>
   ```
4. **Search crawled docs** - If docs are already stored in Basic Memory

## llms.txt Discovery

When asked to review documentation for any tool, library, framework, or service:

1. **Search for llms.txt first** - Look for an `llms.txt` file at the
   documentation root
   - Common locations:
     `https://docs.example.com/llms.txt`, `https://example.com/llms.txt`
   - This file provides a structured index optimized for AI consumption

2. **Use llms.txt as the primary index** - When found, use it to:
   - Understand the full scope of available documentation
   - Identify the most relevant pages for the current task
   - Navigate directly to authoritative sources

3. **Fetch relevant pages from the index** - Based on the user's request, fetch
   specific documentation pages listed in llms.txt using `web-fetch`

4. **Fall back to crwl if web-fetch fails** - Some sites block automated
   fetching. Use `crwl` as an alternative:
   ```bash
   crwl <url>
   ```

5. **Fall back to web search** - If no llms.txt exists and direct fetching
   fails, use web-search

## Best Practices

1. **Check before crawling** - Don't re-crawl unnecessarily
2. **Match depth to need** - Quick for lookups, deep for learning
3. **Use pillars intentionally** - Memory for facts, reasoning for why, examples
   for how
4. **Combine with web search** - For very recent changes, supplement with
   web-fetch
5. **Update stale docs** - Suggest refresh for docs older than 30 days
6. **Search for llms.txt** - When reviewing external documentation
