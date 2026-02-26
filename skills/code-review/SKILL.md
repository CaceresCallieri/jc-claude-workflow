---
name: code-review
description: Run a comprehensive code review, auto-triage findings, and fix issues automatically. Use when the user wants code reviewed, asks for feedback on implementation, says /code-review, or requests improvement suggestions.
---

# Code Review Skill

Review code, auto-triage findings, fix obvious issues without asking, and only consult the user on genuinely ambiguous decisions. Single invocation — no manual follow-up needed.

## Workflow

### Phase 1: Review

1. **Identify review target**:
   - If arguments provided (e.g., `/code-review src/utils.ts`): Review the specified files
   - If no arguments: Review files modified during the current conversation

2. **Launch the code-reviewer sub-agent**:
   - Use the Task tool with `subagent_type: code-reviewer` and `model: "sonnet"`
   - Provide: target files, context about what was implemented, relevant architectural background

3. **Present findings** using the Enhancement Table format below

### Phase 2: Auto-Triage

Immediately after presenting findings, classify each issue into three buckets. Do NOT wait for user approval — proceed straight to execution.

**Auto-fix** when ALL are true:
- The Fix column describes a concrete, unambiguous implementation
- Benefit is `medium`+ OR complexity is `trivial` (regardless of benefit)
- Change is localized (single file or tightly coupled files)
- Does not alter public APIs, config schemas, or user-facing behavior
- Type is: bugfix, performance, simplification, or readability

**Auto-discard** when ANY is true:
- Benefit is `low` AND complexity is `medium`+
- Purely cosmetic (synonym renames, bracket style, comment rewording)
- Subjective style preference with no functional impact
- Contradicts established project patterns

**Consult** when ANY is true:
- Architectural decisions or design pattern choices
- Multiple valid approaches with meaningfully different trade-offs
- Affects public APIs, config schemas, or user-facing behavior
- Touches security-sensitive code
- Type is `architecture` or `extraction` with complexity `medium`+

### Phase 3: Triage Summary

Show a compact, non-blocking summary:

```
## Triage

**Fixing** ([count]): #1 bugfix, #2 perf, #4 simplify
**Skipping** ([count]): #3 — [one-line reason]
**Asking you** ([count]): #5 — [one-line question]
```

This is informational only — do NOT wait for confirmation. Proceed immediately.

### Phase 4: Execute + Consult (Parallel)

In a **single response with multiple tool calls**, simultaneously:

1. **Dispatch fix agents** for all auto-fix items:
   - Use Task tool with `subagent_type: general-purpose`
   - Group fixes touching the same file → single agent, sequential
   - Independent files → separate parallel agents
   - Each agent prompt must be **self-contained** (agents have no conversation context)

2. **Use `AskUserQuestion`** for any consult items:
   - Batch related questions into a single prompt
   - Include trade-offs and your recommendation for each
   - If zero consult items, skip this entirely

**Agent prompt template:**
```
You are implementing code review fix(es). Make ONLY the changes described below — do not refactor, improve, or modify anything else.

## Fix #[N]: [Title]
- **File**: [path]
- **Line(s)**: [line numbers]
- **Problem**: [description]
- **Solution**: [concrete implementation steps]

[Include relevant code context]

After making changes, verify the edit was applied correctly by reading back the modified section.
```

### Phase 5: Report

After user responds to consult items (if any):
- Approved items → dispatch additional fix agents
- Declined items → add to Skipped

Once ALL agents complete, present a unified report:

```
## Code Review Complete

### Changes Made
| # | Location | What Changed | Why |
|---|----------|-------------|-----|

### Skipped
| # | Location | Reason |
|---|----------|--------|

### Testing Guide
| Area | Risk | What to Test |
|------|------|-------------|

### Regression Risks
- [Specific risk connected to a fix, and how to check]
```

**Testing guide rules:**
- Name actual files, functions, and behaviors to verify
- Connect each risk back to the fix that introduced it
- Prioritize by risk level
- Include both happy path and edge cases

### Phase 6: Frontend Regression Testing (Web Projects Only)

After completing the Phase 5 report, determine if browser-based regression testing is both **possible** and **appropriate**. Both pre-flight checks must pass — if either fails, skip Phase 6 entirely.

#### Step 1: Pre-flight Checks

**Check A — Browser automation available:**

Check for `playwright-cli` availability by running `which playwright-cli` via Bash.

- If `playwright-cli` is **found**: proceed to Check B (preferred path).
- If `playwright-cli` is **not found**: check if Chrome DevTools MCP tools are available (is `mcp__chrome-devtools__list_pages` in your available tools?).
  - If MCP is available: proceed to Check B (fallback path — include `**Tooling**: mcp` in the dispatch prompt at Step 4).
  - If neither is available: **skip Phase 6 entirely**. Do not mention browser testing in the report — it is simply not an option in this environment.

**Check B — Web project detected:**

Check for ANY of these indicators (use Glob, do not ask the user):

- `package.json` containing web framework dependencies (`react`, `vue`, `angular`, `svelte`, `next`, `nuxt`, `astro`, `solid`, `qwik`, `remix`, `gatsby`, `vite`, `webpack`, `parcel`, `tailwindcss`)
- Web config files: `vite.config.*`, `next.config.*`, `webpack.config.*`, `nuxt.config.*`, `astro.config.*`, `angular.json`, `svelte.config.*`, `.babelrc`, `postcss.config.*`, `tailwind.config.*`
- HTML entry points: `index.html`, `public/index.html`, `src/index.html`
- Significant `.html`, `.jsx`, `.tsx`, `.vue`, `.svelte`, `.astro` files in the changed files

If **none** of these indicators are found, **skip Phase 6 entirely** — this is not a web project.

**Both checks must pass to proceed.** If either fails, Phase 6 ends here — silently, with no mention in the report.

#### Step 2: Determine Testable URL

Attempt to find the dev server URL:

1. Check `package.json` `scripts` for dev/start commands (look for port numbers)
2. Check for framework-standard ports: Vite (5173), Next.js (3000), Create React App (3000), Angular (4200), Nuxt (3000), Astro (4321)
3. Probe common ports for a running dev server: `curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>` for each candidate port

If no URL can be determined, **ask the user** with `AskUserQuestion`:
```
The code review found regression risks that can be verified in the browser.
Is a dev server running? If so, what's the URL?
```

Options:
- "http://localhost:3000" (or detected port)
- "Not running / Skip browser testing"

If the user chooses to skip, end Phase 6.

#### Step 3: Build Test Plan from Regression Risks

Convert the **Regression Risks** and **Testing Guide** from Phase 5 into a structured test plan for the frontend-tester agent. Each regression risk that involves user-facing behavior becomes a test case.

**Only include tests that can be verified in the browser:**
- UI element presence/absence
- Form behavior and validation
- Navigation and routing
- Interactive components (modals, dropdowns, tooltips)
- Error states and loading states
- Content rendering

**Exclude** (these belong to unit/integration tests, not browser tests):
- Internal function logic
- API response format
- Database operations
- Server-side rendering internals
- Build configuration

#### Step 4: Dispatch Frontend Tester

Use the Task tool with `subagent_type: frontend-tester` and `model: "sonnet"` (always specify the model explicitly to prevent inheriting the parent's model):

```
You are testing a web application after a code review applied fixes.
Verify that the changes did not introduce regressions.

**URL**: [dev server URL]
**Display**: headless

**Context**: The following code review changes were made:
[Brief summary of changes from Phase 5 Changes Made table]

**Tests**:
1. [Navigate to page] → Verify [expected element/behavior]
2. [Perform action] → Verify [expected result]
3. [Check for regression] → Verify [specific risk from Phase 5]
...

**Known pre-existing issues** (ignore these):
- [Any known console errors or warnings from the project]
```

If Check A determined the MCP fallback path (playwright-cli not found), add `**Tooling**: mcp` to the prompt. The frontend-tester agent will use Chrome DevTools MCP tools when it sees this directive.

#### Step 5: Present Browser Test Results

After the frontend-tester agent returns, append its results to the code review report:

```
## Browser Regression Test Results

[Results from frontend-tester agent]
```

- If all tests **PASS**: Confirm confidence in the changes
- If any tests **FAIL**: Flag the regression, identify which code review fix likely caused it, and recommend next steps
- If tests were **SKIPPED**: Explain why and suggest manual verification

## Enhancement Table Format

Present ALL findings in a scannable table — **never omit any issue**.

```markdown
## Findings

| # | Type | Location | Problem | Fix | Complexity | Benefit |
|---|------|----------|---------|-----|------------|---------|
| 1 | 🐛 bugfix | `file.ts:42` | Description | Solution | `low` | `high` |
```

**Type Icons:** 🐛 bugfix · 🔒 security · ⚡ performance · 🧹 simplification · 📦 extraction · 📖 readability · 🏗️ architecture · 🧪 testing

**Complexity:** `trivial` · `low` · `medium` · `high` · `critical`

**Benefit:**
- `critical` — Bug, security vulnerability, or data integrity issue
- `high` — Significant reliability, performance, or maintainability improvement
- `medium` — Noticeable code quality or developer experience improvement
- `low` — Minor polish, nice-to-have

## Critical Rules

1. **Never omit findings** — every issue from the sub-agent must appear in the Enhancement Table
2. **Never wait for triage approval** — auto-fix agents launch immediately after the triage summary
3. **Always consult when uncertain** — use `AskUserQuestion` rather than silently discarding merit-based issues
4. **Self-contained agent prompts** — each Task agent gets all context it needs, no "see above" references
5. **Maximize parallelism** — launch independent fix agents simultaneously; dispatch consult-approved fixes after user responds
6. **Never over-fix** — agents implement exactly what's planned, no bonus refactoring
7. **Report everything** — every change, skip, and decision appears in the final report
8. **Testing guide is mandatory** — always provide verification steps and regression risks
9. **Frontend testing requires both conditions** — Phase 6 only runs when browser automation is available (playwright-cli preferred, Chrome DevTools MCP as fallback) AND web project indicators are detected. If either condition fails, skip Phase 6 silently. Only ask the user for the dev server URL if both pre-flight checks pass but the URL cannot be determined automatically
10. **Frontend tester is read-only** — the frontend-tester agent verifies behavior but never modifies code; if it finds regressions, report them for the user to decide on next steps
