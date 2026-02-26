#!/bin/bash

# Read JSON input from stdin FIRST (stdin can only be read once)
JSON_INPUT=""
if [ ! -t 0 ]; then
    JSON_INPUT=$(cat)
fi

# Debug: save input to file for troubleshooting (comment out when not needed)
# echo "$JSON_INPUT" > /tmp/claude-statusline-debug.json

# ─────────────────────────────────────────────────────────────────────────────
# ANSI Color Codes
# ─────────────────────────────────────────────────────────────────────────────
RESET='\033[0m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'

# ─────────────────────────────────────────────────────────────────────────────
# Nerd Font Icons (requires a Nerd Font to render)
# ─────────────────────────────────────────────────────────────────────────────
ICON_GIT_BRANCH=$'\xee\x82\xa0'  # U+E0A0 - Git branch (powerline)
ICON_STAGED='●'                  # U+25CF - Filled circle (staged changes)
ICON_UNSTAGED='○'                # U+25CB - Empty circle (unstaged changes)

# Get the last folder of the current working directory
get_current_directory_basename() {
    basename "$(pwd)"
}

# Get the current git branch if in a git repository
get_current_git_branch() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git branch --show-current 2>/dev/null || echo "HEAD"
    else
        echo ""
    fi
}

# Get git line changes (additions, deletions, and file counts)
# Returns: "staged_add staged_del staged_files unstaged_add unstaged_del unstaged_files" (space-separated)
get_git_changes() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo ""
        return
    fi

    # Get staged changes
    local staged_add=0
    local staged_del=0
    local staged_files=0
    while read -r add del _; do
        # Skip binary files (shown as -)
        [[ "$add" == "-" ]] && continue
        staged_add=$((staged_add + add))
        staged_del=$((staged_del + del))
        staged_files=$((staged_files + 1))
    done < <(git diff --cached --numstat 2>/dev/null)

    # Get unstaged changes
    local unstaged_add=0
    local unstaged_del=0
    local unstaged_files=0
    while read -r add del _; do
        # Skip binary files (shown as -)
        [[ "$add" == "-" ]] && continue
        unstaged_add=$((unstaged_add + add))
        unstaged_del=$((unstaged_del + del))
        unstaged_files=$((unstaged_files + 1))
    done < <(git diff --numstat 2>/dev/null)

    echo "$staged_add $staged_del $staged_files $unstaged_add $unstaged_del $unstaged_files"
}

# Calculate context length from transcript file (same approach as ccstatusline)
# This reads the JSONL transcript and finds the most recent message's token usage
get_context_from_transcript() {
    local transcript_path="$1"

    if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
        echo ""
        return
    fi

    # Find the most recent line with message.usage data (not sidechain)
    # Read file in reverse, find first valid usage entry
    tac "$transcript_path" 2>/dev/null | while IFS= read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue

        # Check if line has message.usage
        local usage=$(echo "$line" | jq -r '.message.usage // empty' 2>/dev/null)
        if [ -n "$usage" ] && [ "$usage" != "null" ]; then
            # Skip sidechain messages
            local is_sidechain=$(echo "$line" | jq -r '.isSidechain // false' 2>/dev/null)
            if [ "$is_sidechain" != "true" ]; then
                # Calculate: input_tokens + cache_read_input_tokens + cache_creation_input_tokens
                local context=$(echo "$line" | jq -r '.message.usage | ((.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0))' 2>/dev/null)
                if [ -n "$context" ] && [ "$context" -gt 0 ] 2>/dev/null; then
                    echo "$context"
                    return
                fi
            fi
        fi
    done
}

# Get the current model display name from JSON input
get_model_name() {
    if [ -z "$JSON_INPUT" ]; then
        echo ""
        return
    fi

    if command -v jq >/dev/null 2>&1; then
        local model=$(echo "$JSON_INPUT" | jq -r '.model.display_name // empty' 2>/dev/null)
        if [ -n "$model" ] && [ "$model" != "null" ]; then
            echo "$model"
            return
        fi
    fi

    echo ""
}

# Get color based on context usage percentage
get_context_color() {
    local percentage="$1"
    if [ "$percentage" -ge 80 ]; then
        echo "$RED"
    elif [ "$percentage" -ge 50 ]; then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# Parse context information from transcript file or JSON input
# Returns: "tokens percentage" (space-separated for color calculation)
get_context_information() {
    if [ -z "$JSON_INPUT" ]; then
        echo ""
        return
    fi

    # Requires jq for JSON parsing
    if ! command -v jq >/dev/null 2>&1; then
        echo ""
        return
    fi

    # Get context window size
    local context_limit=$(echo "$JSON_INPUT" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
    if [ -z "$context_limit" ] || [ "$context_limit" = "null" ]; then
        echo ""
        return
    fi

    # Get transcript path and calculate context from it (accurate method)
    local transcript_path=$(echo "$JSON_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
    local context_length=""

    if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
        context_length=$(get_context_from_transcript "$transcript_path")
    fi

    if [ -n "$context_length" ] && [ "$context_length" -gt 0 ] 2>/dev/null; then
        local percentage=$((context_length * 100 / context_limit))
        # Format large numbers with k suffix for readability
        if [ "$context_length" -ge 1000 ]; then
            local context_k=$((context_length / 1000))
            local context_limit_k=$((context_limit / 1000))
            echo "${context_k}k/${context_limit_k}k ${percentage}"
        else
            echo "${context_length}/${context_limit} ${percentage}"
        fi
        return
    fi

    echo ""
}

# Format git changes for display
# Input: "staged_add staged_del staged_files unstaged_add unstaged_del unstaged_files"
format_git_changes() {
    local changes="$1"
    if [ -z "$changes" ]; then
        echo ""
        return
    fi

    # Parse the space-separated values
    local staged_add staged_del staged_files unstaged_add unstaged_del unstaged_files
    read -r staged_add staged_del staged_files unstaged_add unstaged_del unstaged_files <<< "$changes"

    local output=""

    # Format staged changes (●)
    if [ "$staged_files" -gt 0 ]; then
        output="${output} ${ICON_STAGED}${GREEN}+${staged_add}${RESET}${RED}-${staged_del}${RESET}${DIM}(${staged_files})${RESET}"
    fi

    # Format unstaged changes (○)
    if [ "$unstaged_files" -gt 0 ]; then
        output="${output} ${ICON_UNSTAGED}${GREEN}+${unstaged_add}${RESET}${RED}-${unstaged_del}${RESET}${DIM}(${unstaged_files})${RESET}"
    fi

    echo -e "$output"
}

# Format model name for display
format_model_info() {
    local model="$1"
    if [ -n "$model" ]; then
        echo -e "${DIM} | ${RESET}${MAGENTA}${model}${RESET}"
    else
        echo ""
    fi
}

# Format context information for display with colors
format_context_info() {
    local context_data="$1"
    if [ -n "$context_data" ]; then
        # Split: "80k/200k 40" -> tokens="80k/200k", percentage="40"
        local tokens="${context_data% *}"
        local percentage="${context_data##* }"
        local color=$(get_context_color "$percentage")
        echo -e "${DIM} | ${RESET}${DIM}Ctx:${RESET} ${color}${tokens} (${percentage}%)${RESET}"
    else
        echo ""
    fi
}

# Main status line function
generate_status_line() {
    local current_dir_basename=$(get_current_directory_basename)
    local current_git_branch=$(get_current_git_branch)
    local git_changes=$(get_git_changes)
    local model_name=$(get_model_name)
    local context_data=$(get_context_information)
    local formatted_git_changes=$(format_git_changes "$git_changes")
    local formatted_model=$(format_model_info "$model_name")
    local formatted_context=$(format_context_info "$context_data")

    if [ -n "$current_git_branch" ]; then
        echo -e "${CYAN}${current_dir_basename}${RESET} ${GREEN}${ICON_GIT_BRANCH} ${current_git_branch}${RESET}${formatted_git_changes}${formatted_model}${formatted_context}"
    else
        echo -e "${CYAN}${current_dir_basename}${RESET}${formatted_model}${formatted_context}"
    fi
}

# Output the status line
generate_status_line
