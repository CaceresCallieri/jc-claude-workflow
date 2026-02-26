---
description: Install and configure the Claude Code ANSI statusline with git info, model name, and context usage. Use when the user says /setup-statusline, wants to set up a statusline, or configure the status bar.
allowed-tools: ["Bash", "Read", "Edit", "Write"]
---

# Setup Statusline

Install the custom ANSI statusline script and configure Claude Code to use it.
The statusline displays: directory name, git branch, staged/unstaged changes,
model name, and color-coded context window usage.

## Context (gathered at load time)

Dependencies:
- jq: !`command -v jq >/dev/null 2>&1 && echo "FOUND" || echo "MISSING"`
- tac: !`command -v tac >/dev/null 2>&1 && echo "FOUND" || echo "MISSING"`
- git: !`command -v git >/dev/null 2>&1 && echo "FOUND" || echo "MISSING"`

Current state:
- Script exists: !`test -f ~/.claude/status-line.sh && echo "EXISTS" || echo "MISSING"`
- Settings exists: !`test -f ~/.claude/settings.json && echo "EXISTS" || echo "MISSING"`

Plugin script location: `${CLAUDE_PLUGIN_ROOT}/scripts/status-line.sh`

## Instructions

Follow these phases sequentially using your tools. Do NOT skip ahead.

### Phase 1 — Check Prerequisites

Review the dependency check results above. If any shows MISSING, inform the user with install instructions and STOP:
- **Arch Linux**: `paru -S jq coreutils git`
- **Ubuntu/Debian**: `sudo apt install jq coreutils git`
- **macOS**: `brew install jq coreutils git` (tac is in coreutils as `gtac`)

Only proceed if all three show FOUND.

### Phase 2 — Install Script

Use the Bash tool for each step sequentially:

1. If the "Script exists" check above shows EXISTS, create a timestamped backup:
   ```bash
   cp ~/.claude/status-line.sh ~/.claude/status-line.sh.backup.$(date +%Y%m%d%H%M%S)
   ```

2. Ensure the target directory exists:
   ```bash
   mkdir -p ~/.claude
   ```

3. Copy the script from the plugin directory (use the path from "Plugin script location" above):
   ```bash
   cp "${CLAUDE_PLUGIN_ROOT}/scripts/status-line.sh" ~/.claude/status-line.sh
   ```

4. Set execute permission:
   ```bash
   chmod +x ~/.claude/status-line.sh
   ```

### Phase 3 — Configure settings.json

1. Read `~/.claude/settings.json` using the Read tool.

2. If the file does NOT exist, create it with the Write tool containing:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/status-line.sh",
       "padding": 0
     }
   }
   ```

3. If the file EXISTS:
   - If it already has a `statusLine` key with identical values (`type: "command"`, `command: "~/.claude/status-line.sh"`, `padding: 0`), inform the user it is already configured and skip.
   - If it has a `statusLine` key with DIFFERENT values, update it using the Edit tool.
   - If it does NOT have a `statusLine` key, add it using the Edit tool. Insert the block before the closing `}` of the root object.

4. CRITICAL: Preserve ALL other existing settings. Do not remove or modify any other keys.

5. If the file contains malformed JSON, STOP and warn the user. Do NOT modify it.

### Phase 4 — Verify

Use the Bash tool to run these checks:

1. Verify script exists and is executable:
   ```bash
   test -x ~/.claude/status-line.sh && echo "Script: OK" || echo "Script: FAIL"
   ```

2. Verify settings.json has the statusLine key:
   Read `~/.claude/settings.json` with the Read tool and confirm the `statusLine` block is present.

3. Dry-run the script:
   ```bash
   echo '{}' | ~/.claude/status-line.sh
   ```

### Phase 5 — Report

Present the user with a summary:

```
Statusline Setup Complete

Script:   ~/.claude/status-line.sh ✓
Settings: ~/.claude/settings.json  ✓
Backup:   [path if created, or "not needed"]

What it displays:
- Directory name (cyan)
- Git branch with Nerd Font icon (green)
- Staged changes with +additions/-deletions
- Unstaged changes with +additions/-deletions
- Model name (magenta)
- Context usage with color-coded percentage

Requirements:
- Nerd Font in your terminal for icons
- jq, git, tac in PATH

Restart Claude Code for the statusline to take effect.
```

## Error Handling

- If `cp` fails: check permissions on `~/.claude/` and report the specific error
- If settings.json is malformed JSON: warn the user and do NOT modify; suggest manual intervention
- If the dry-run outputs nothing: this is normal when no real session data is available; the statusline will work correctly in an active Claude Code session
