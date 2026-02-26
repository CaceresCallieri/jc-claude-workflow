# jc-claude-workflow

A Claude Code plugin that packages a portable dev workflow for use across machines.

## What's Included

### Skills

- **code-review** — Comprehensive code review with auto-triage. Launches a code-reviewer sub-agent, classifies findings (auto-fix / auto-discard / consult), dispatches parallel fix agents, and optionally runs browser regression tests via the frontend-tester agent.
- **commit** — Conventional commit workflow that analyzes changes, splits commits by concern, and produces clean commit messages.

### Agents

- **code-reviewer** — Expert code review sub-agent that analyzes code structure, identifies bugs, performance issues, and simplification opportunities.
- **frontend-tester** — Browser-based QA agent that verifies UI behavior through Chrome DevTools MCP. Requires a Chrome DevTools MCP connection (works over reverse tunnels).

### Commands

- **setup-statusline** — One-time setup command (`/setup-statusline`) that installs a custom ANSI statusline script to `~/.claude/` and configures `settings.json`. Displays git info (branch, staged/unstaged changes), model name, and color-coded context window usage. Requires jq, git, tac, and a Nerd Font terminal.

### Settings

- `outputStyle: Explanatory` — Educational insights alongside task completion.
- `includeCoAuthoredBy: false` — No AI co-author references in commits.

## Installation

```bash
# Step 1: Register the marketplace
/plugin marketplace add CaceresCallieri/jc-claude-workflow

# Step 2: Install the plugin
/plugin install jc-claude-workflow@jc-claude-workflow
```

For local development:

```bash
/plugin install ~/projects/jc-claude-workflow
```

## Updating

After pushing changes to GitHub, update on the target machine:

```bash
/plugin update jc-claude-workflow@jc-claude-workflow
```

## Prerequisites

- **git** and **gh** CLI for the commit skill and GitHub integration
- **jq** for the statusline script (JSON parsing)
- **Nerd Font** in your terminal emulator for statusline icons
- **Chrome DevTools MCP** connection for the frontend-tester agent (can work over SSH reverse tunnels)
