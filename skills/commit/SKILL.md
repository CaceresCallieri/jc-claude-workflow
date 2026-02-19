---
name: commit
description: Create well-formatted conventional commits. Use when committing changes, saving progress, checkpointing work, or when the user says /commit, commit, or similar.
---

# Commit Skill

Create clear, professional commit messages following the Conventional Commits specification.

## Workflow

1. **Analyze project conventions**: Run `git log --oneline -10` to understand the project's commit style, scopes, and patterns
2. **Review current changes**: Run `git status` and `git diff` to understand what will be committed
3. **Identify conversation-related changes**: Determine which files were modified during the current conversation—ignore unrelated changes
4. **Assess scope**: Determine if changes should be split into multiple logical commits
5. **Split commits when appropriate**: If changes span multiple concerns (different features, fixes, or areas), create separate commits for each logical unit
6. **Check for related issues**: If the conversation originated from or references a GitHub issue, note the issue number for the commit footer
7. **Craft the message(s)**: Follow the format below for each commit
7. **Execute commits using direct file specification**: Use `git commit <file1> <file2> ... -m "message"` to commit only conversation-related files, bypassing any pre-staged changes
8. **Notify about remaining changes**: After committing, inform the user if there are other uncommitted changes in the working directory that were not part of this conversation

## Commit Technique

**Always use direct file commits** to ensure precise control:

```bash
# Correct: commits only specified files, ignores staging area
git commit path/to/file1 path/to/file2 -m "message"

# Avoid: commits everything staged, including unrelated pre-staged files
git add file && git commit -m "message"
```

This prevents accidentally including pre-staged files from before the conversation.

## Commit Message Format

```
<type>[scope]: <description>

[body]

[footer]
```

### Header (Required)

- **Type**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`
- **Scope**: Use project-specific scopes observed in commit history
- **Description**:
  - 50-72 characters
  - Imperative mood ("add" not "added")
  - Lowercase, no period
  - Focus on WHAT changed

### Body (Recommended)

- Explain WHY and provide context
- Describe how systems interact
- Technical details for future developers
- Wrap at 72 characters
- Use bullet points for multiple changes

### Footer (When Applicable)

- **Issue references**: If the current work closes or relates to a GitHub issue, always include the reference:
  - `Closes #123` — when the commit fully resolves the issue
  - `Refs #456` — when the commit is related but doesn't fully close it
  - If the conversation was initiated from or mentions an issue, proactively include the appropriate footer
- `BREAKING CHANGE: description` for breaking changes

## Critical Rules

1. **Never mention AI/Claude** in commit messages
2. **Match project style** from recent commits
3. **Be technically precise** with terminology
4. **Prioritize clarity** for future developers
5. **Split commits proactively** when changes span multiple concerns—don't combine unrelated changes
6. **Only commit conversation changes** — commit only files modified in the current session
7. **Use direct file commits** — always use `git commit <files> -m "msg"` to avoid including pre-staged unrelated changes
8. **Report remaining changes** — always notify the user about any uncommitted changes after completing
9. **Focus on significant changes** — when committing after code review fixes or polish, describe the overall feature/refactor, not just the last minor tweaks
10. **Preview commits in bypass mode** — when Claude Code is running with "Dangerously Skip Permissions" enabled, always display the full commit message and list of files to be committed for user review BEFORE executing the commit. In normal permission modes, proceed directly with the commit command as the permission prompt provides the review opportunity

## Holistic Commit Messages

When committing after incremental fixes (code review feedback, style adjustments, security fixes, visibility changes, etc.), the commit message should reflect the **overall significant changes**, not just the last minor tweaks.

### When This Applies

- After completing code review fixes on a larger feature/refactor
- After making small style or formatting adjustments to new code
- After fixing minor issues discovered during testing
- After polishing code that was part of a larger change

### How to Handle

1. **Review the full scope**: Use `git diff` to see all uncommitted changes, not just recent edits
2. **Identify the primary change**: What was the main feature, refactor, or fix being implemented?
3. **Treat fixes as part of the whole**: Code review fixes, style adjustments, and polish are part of delivering the feature—not separate changes
4. **Write for the feature, not the fix**: The commit message should describe the feature/refactor, with fixes naturally included

### Example

**Scenario**: Implemented a new authentication system, then fixed variable naming and added error handling based on code review.

**Wrong approach**:
```
fix(auth): rename variables and add error handling
```

**Correct approach**:
```
feat(auth): implement JWT-based authentication system

- Add token generation and validation middleware
- Create user session management with refresh tokens
- Integrate with existing user service
```

The variable renaming and error handling are implicit parts of delivering a complete feature—they don't define the commit.

## When to Clarify

- Purpose of certain changes is unclear
- Uncertain which files belong to the current conversation
- Optimal commit split strategy is ambiguous
- Whether recent fixes are part of a larger feature or standalone changes
