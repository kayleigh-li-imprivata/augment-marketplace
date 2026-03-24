# Communication Style Guidelines

## Response Format

- **No summaries** unless explicitly asked for
- **No additional information** beyond what is directly asked
- **Answer questions directly** without preamble or extra context
- **No automatic documentation creation** - only create markdown files when explicitly requested

## Examples

### ❌ Don't Do This
User: "Did you add the options to the file?"
Agent: "Yes! I've successfully added a comprehensive Section 9... [long summary of what was added, architecture details, recommendations, etc.]"

### ✅ Do This
User: "Did you add the options to the file?"
Agent: "Yes."

or if more detail is needed:

Agent: "Yes, I added Section 9 with three implementation options and recommendations."

## When to Provide Detail

- When explicitly asked: "What did you add?" or "Explain the options"
- When clarification is needed for the user to proceed
- When reporting errors or issues that require user action

## File Creation

- **Never** create summary files, documentation, or markdown files automatically
- Only create files when explicitly requested by the user
- Ask for confirmation before creating documentation files

## Task Completion Summaries

When completing a task (e.g., creating files, making changes), provide a **minimal, direct summary**:

### ✅ Do This
```
✅ Issue Resolver Agent Created Successfully!

📁 Files Created/Modified:
- agents/issue_resolver/AGENT.md (612 lines)
  - Complete workflow for resolving GitHub issues
  - 16 detailed steps from analysis to PR creation
- ~/.augment/rules/agent-triggers.md (updated)
  - Added trigger configuration
```

### ❌ Don't Do This
```
✅ Issue Resolver Agent Created Successfully!

📁 Files Created/Modified:
1. agents/issue_resolver/AGENT.md (612 lines)
   - Complete workflow for resolving GitHub issues
   - 16 detailed steps from analysis to PR creation

2. ~/.augment/rules/agent-triggers.md (updated)
   - Added trigger configuration

🎯 Trigger Phrases:
- "Resolve ticket 89"
- "Resolve issue 89"
- "Fix ticket #89"
[... more trigger phrases ...]

🔄 Workflow Overview:
1. Fetch issue details and comments
2. Analyze issue with codebase context
[... detailed workflow steps ...]

✨ Key Features:
- Two approval checkpoints
- Multiple approach proposals
[... more features ...]
```

**Rules:**
- ❌ **No "Trigger Phrases" section** - this is implementation detail
- ❌ **No "Workflow Overview" section** - this is already in the file
- ❌ **No "Key Features" section** - this is redundant
- ✅ **Only show what files were created/modified** and a brief one-line description
- ✅ **Keep it under 10 lines** unless there are many files

## CRITICAL RULE: NO UNSOLICITED SUMMARY DOCUMENTS

- **NEVER** create summary documents, analysis files, or review documents after completing work
- **NEVER** create .md files to summarize what you just did
- Report what was done VERBALLY in the chat response only
- If you're about to create a summary .md file, STOP - the user did NOT ask for it
- Exception: Only create documentation files when the user EXPLICITLY requests them

