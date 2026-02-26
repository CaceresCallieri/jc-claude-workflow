---
description: Install and configure the Claude Code ANSI statusline with git info, model name, and context usage. Use when the user says /setup-statusline, wants to set up a statusline, or configure the status bar.
allowed-tools: ["Bash", "Read", "Edit", "Write"]
---

# Setup Statusline

Install the custom ANSI statusline script and configure Claude Code to use it.
The statusline displays: directory name, git branch, staged/unstaged changes,
model name, and color-coded context window usage.

## Phase 1 — Prerequisites

Check required dependencies before proceeding:

1. jq: !`command -v jq >/dev/null 2>&1 && echo "FOUND" || echo "MISSING"`
2. tac: !`command -v tac >/dev/null 2>&1 && echo "FOUND" || echo "MISSING"`
3. git: !`command -v git >/dev/null 2>&1 && echo "FOUND" || echo "MISSING"`

If any dependency is MISSING, inform the user with install instructions:
- **Arch Linux**: `paru -S jq coreutils git`
- **Ubuntu/Debian**: `sudo apt install jq coreutils git`
- **macOS**: `brew install jq coreutils git` (tac is in coreutils as `gtac`)

Do NOT proceed until all three dependencies are confirmed present.

## Phase 2 — Install Script

1. Check if a statusline script already exists:
   !`test -f ~/.claude/status-line.sh && echo "EXISTS" || echo "MISSING"`

2. If EXISTS, create a timestamped backup:
   !`cp ~/.claude/status-line.sh ~/.claude/status-line.sh.backup.$(date +%Y%m%d%H%M%S)`
   Inform the user a backup was created.

3. Ensure target directory exists:
   !`mkdir -p ~/.claude`

4. Copy the script from plugin:
   !`cp "${CLAUDE_PLUGIN_ROOT}/scripts/status-line.sh" ~/.claude/status-line.sh`

5. Set execute permission:
   !`chmod +x ~/.claude/status-line.sh`

## Phase 3 — Configure settings.json

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

## Phase 4 — Verify

1. Verify script exists and is executable:
   !`test -x ~/.claude/status-line.sh && echo "OK" || echo "FAIL"`

2. Verify settings.json has the statusLine key:
   Read `~/.claude/settings.json` and confirm the `statusLine` block is present and correct.

3. Dry-run the script (it will output a partial statusline even with empty JSON):
   !`echo '{}' | ~/.claude/status-line.sh`

## Phase 5 — Report

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
