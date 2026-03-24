# Global User Guidelines for Augment

---

# 🚨 CRITICAL RULES - ABSOLUTE REQUIREMENTS 🚨

## ⛔ Git Operations - MANDATORY APPROVAL REQUIRED ⛔

**STOP! READ THIS BEFORE ANY GIT OPERATION!**

Before executing ANY git command (`git add`, `git commit`, `git push`, `git merge`, `git rebase`, etc.):

### ✅ REQUIRED CHECKLIST - MUST COMPLETE EVERY TIME:

1. **SHOW** the user what changes will be affected:
   ```bash
   git diff
   git status
   ```

2. **ASK** explicitly: "Would you like me to commit these changes?"
   - Wait for explicit "yes" / "commit this" / "go ahead"
   - If user says anything else, DO NOT PROCEED

3. **IF APPROVED TO COMMIT**, then **ASK** separately: "Would you like me to push to remote?"
   - Wait for explicit "yes" / "push this" / "go ahead"
   - If user says anything else, DO NOT PUSH

4. **NEVER** assume approval
5. **NEVER** batch git operations without asking for each step
6. **NEVER** commit and push in the same action without separate approvals

### ❌ VIOLATIONS THAT ARE NEVER ACCEPTABLE:

- ❌ Committing without showing diff first
- ❌ Committing without explicit approval
- ❌ Pushing without explicit approval
- ❌ Assuming "test this" means "commit and push this"
- ❌ Committing temporary/testing changes
- ❌ Force-pushing without explicit approval

### ✅ ONLY EXCEPTION:

User explicitly says one of these phrases:
- "commit this"
- "push this"
- "commit and push"
- "go ahead and commit"
- "go ahead and push"

### 🤖 AUTO MODE - NO EXCEPTION:

**This rule applies EVEN in "Auto" mode or autonomous operation.**
- Auto mode does NOT grant permission to skip approval
- Auto mode does NOT allow batching git operations
- You MUST still ask for approval before ANY git operation
- If in Auto mode, STOP and ask for approval before proceeding with git operations

**IF IN ANY DOUBT: ASK FIRST!**

---

## Code Organization & Architecture

### Module Structure
- **Never import inside functions** - all imports must be at module level for performance and clarity
- **Never build nested functions** - keep all functions at module level for maintainability
- **Write modular, single-responsibility functions** - each function should do one thing well
  - Reference: `workstation-clustering` for design patterns
- **Preserve existing architecture and patterns** - maintain consistency with the codebase
- **Follow existing naming conventions and code style** - consistency over personal preference

### Code Quality
- **Avoid code duplication** - reuse existing utilities and helper functions when possible
- **Remove dead code during refactoring** - but verify it's truly unused first (check references, git history)

## Data & Type Safety

- **Use Pydantic models for all data classes** - leverage validation and type safety

## Documentation Standards

### Docstrings
- **Add clean and concise docstrings to all functions** - explain what, not how
- **Update docstrings when behavior changes** - keep them in sync with implementation
- **Keep documentation aligned with implementation** - outdated docs are worse than no docs

### Comments
- **Add comments only to non-obvious logic** - code should be self-documenting when possible
- **Explain "why", not "what"** - the code shows what it does, comments explain reasoning

## Testing Standards

### Test Structure
- **Follow Arrange-Act-Assert (AAA) pattern** - clear separation of setup, execution, and verification
- **Use pytest fixtures extensively** - avoid duplication in test setup
- **Use parametrized tests** - test multiple cases with single test function when appropriate

### Test Quality
- **Create smart assertions**:
  - Assign complex logic to variables before asserting
  - Keep assert statements clean and readable
  - Structure assertions so one failure doesn't block others from running
- **Write deterministic tests** - avoid flaky tests that depend on timing, randomness, or external state
- **Focus on behavior and outcomes** - avoid trivial tests (e.g., simple type checks)
- **Test what matters**: new behaviors, edge cases, error conditions

### Test Execution
- **Use `uv` to run tests** - default command: `uv run pytest -n auto`
- **Enable parallelism** - use `-n auto` or `-n logical` for faster test execution

### Test Maintenance
- **Add tests for new features** - cover new behaviors, edge cases, and error conditions
- **Update tests when refactoring** - ensure all test suites pass after changes
- **Keep tests aligned with implementation** - tests should reflect current behavior

## Merge & Conflict Resolution

### Conflict Resolution Process
1. **Preserve both sides' intent when possible** - don't discard work without understanding it
2. **Analyze each conflict individually**:
   - Check what's introduced from feature branch
   - Check what's different in target branch (e.g., dev/main)
   - Understand the context and purpose of each change
3. **DO NOT simply accept one side** - reason through each conflict and decide deliberately
4. **When in doubt, verify against the feature branch's goal** - understand what problem it's solving
5. **Rerun tests after resolving conflicts** - ensure nothing broke during resolution

### Merge Best Practices
- Review the full diff between branches before starting
- Understand the feature's purpose before resolving conflicts
- Test thoroughly after merge - run full test suite

## Additional Standards

### Test Markers
- **Always include `@pytest.mark.target()` decorator** - mark every test with the function/class it targets for better test organization and filtering

### Documentation Style
- **Use emojis when appropriate** - enhance readability and visual scanning
  - ✅ / ❌ for yes/no, pros/cons, pass/fail
  - ⚠️ for warnings or cautions
  - 💡 for tips or suggestions
  - 🔍 for details or investigations
  - 📝 for notes or documentation
  - 🚀 for performance or improvements
  - 🐛 for bugs or issues

## Scope and File Creation

- **Do what has been asked; nothing more, nothing less**
- **NEVER create files unless they're absolutely necessary** for achieving your goal
- **ALWAYS prefer editing an existing file to creating a new one**
- **NEVER proactively create documentation files** (*.md) or README files unless explicitly requested by the User
- **NEVER summarize your action in files** unless explicitly requested by the User
