#!/bin/bash

# Tmux Smart Naming - Auto-rename sessions and windows based on content
# Detects projects, git repos, Claude Code sessions, and running processes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to detect project type from directory
detect_project_type() {
    local dir="$1"
    
    # Handle empty or invalid directory
    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo "unknown"
        return
    fi
    
    if [ -f "$dir/package.json" ]; then
        # Node.js project - get name from package.json
        local name=$(jq -r '.name // empty' "$dir/package.json" 2>/dev/null)
        if [ -z "$name" ]; then
            # Fallback to grep if jq not available
            name=$(grep '"name"' "$dir/package.json" | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr -d ' ')
        fi
        if [ -n "$name" ] && [ "$name" != "null" ]; then
            echo "$name"
        else
            echo "$(basename "$dir")"
        fi
    elif [ -f "$dir/Cargo.toml" ]; then
        # Rust project
        local name=$(grep '^name[[:space:]]*=' "$dir/Cargo.toml" | head -1 | sed 's/name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/')
        echo "${name:-$(basename "$dir")}"
    elif [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] || [ -f "$dir/requirements.txt" ]; then
        # Python project
        echo "py-$(basename "$dir")"
    elif [ -f "$dir/go.mod" ]; then
        # Go project
        local name=$(head -1 "$dir/go.mod" | awk '{print $2}' | sed 's/.*\///')
        echo "${name:-$(basename "$dir")}"
    elif [ -d "$dir/.git" ]; then
        # Git repository - get repo name
        echo "$(basename "$dir")"
    else
        # Generic directory
        echo "$(basename "$dir")"
    fi
}

# Function to detect if Claude Code is running in a pane
detect_claude_activity() {
    local session="$1"
    local window="$2"
    local pane="$3"
    
    # Get pane info
    local pane_info=$(tmux display -t "$session:$window.$pane" -p '#{pane_pid}:#{pane_current_path}')
    local pane_pid=$(echo "$pane_info" | cut -d: -f1)
    local pane_path=$(echo "$pane_info" | cut -d: -f2-)
    
    # Check if Claude Code is running in this pane or its children
    local all_pids=""
    if command -v pstree >/dev/null 2>&1; then
        all_pids=$(pstree -p "$pane_pid" 2>/dev/null | grep -o '([0-9]*)' | tr -d '()' 2>/dev/null || true)
    fi
    
    if [ -z "$all_pids" ]; then
        # Fallback if pstree not available or failed
        all_pids="$pane_pid $(pgrep -P "$pane_pid" 2>/dev/null || true)"
    fi
    
    for pid in $all_pids; do
        local cmd=$(ps -p "$pid" -o command= 2>/dev/null)
        if [[ "$cmd" == *"claude"* ]] && [[ "$cmd" != *"grep"* ]]; then
            # Found Claude Code process
            local project=$(detect_project_type "$pane_path")
            if [ "$project" != "unknown" ]; then
                echo "♦$project"
                return 0
            else
                echo "♦claude"
                return 0
            fi
        fi
    done
    
    return 1
}

# Function to get current activity description
get_activity_description() {
    local session="$1"
    local window="$2"
    local pane="$3"
    
    # Get current command and path
    local pane_info=$(tmux display -t "$session:$window.$pane" -p '#{pane_current_command}:#{pane_current_path}')
    local cmd=$(echo "$pane_info" | cut -d: -f1)
    local path=$(echo "$pane_info" | cut -d: -f2-)
    
    # Check for Claude activity first (highest priority)
    local claude_activity=""
    if detect_claude_activity "$session" "$window" "$pane" >/dev/null 2>&1; then
        claude_activity=$(detect_claude_activity "$session" "$window" "$pane" 2>/dev/null)
        if [ -n "$claude_activity" ]; then
            echo "$claude_activity"
            return 0
        fi
    fi
    
    # Detect project type from current path
    local project=$(detect_project_type "$path")
    
    # Combine command and project info
    case "$cmd" in
        "vim"|"nvim"|"nano"|"emacs")
            echo "📝$project"
            ;;
        "git")
            echo "🔀$project"
            ;;
        "npm"|"yarn"|"pnpm")
            echo "📦$project"
            ;;
        "python"|"python3")
            echo "🐍$project"
            ;;
        "node")
            echo "🟢$project"
            ;;
        "cargo")
            echo "🦀$project"
            ;;
        "go")
            echo "🐹$project"
            ;;
        "zsh"|"bash"|"fish")
            if [ "$project" != "unknown" ]; then
                # Special handling for home directory
                if [ "$project" = "krempovych" ] || [ "$path" = "$HOME" ]; then
                    echo "🏠home"
                else
                    echo "$project"
                fi
            else
                echo "🏠home"
            fi
            ;;
        *)
            if [ "$project" != "unknown" ]; then
                # Special handling for home directory
                if [ "$project" = "krempovych" ] || [ "$path" = "$HOME" ]; then
                    echo "🏠home"
                else
                    echo "$project"
                fi
            else
                echo "$(basename "$path")"
            fi
            ;;
    esac
}

# Function to generate smart window name
generate_window_name() {
    local session="$1"
    local window="$2"
    
    # Get all panes in the window
    local panes=$(tmux list-panes -t "$session:$window" -F '#{pane_index}')
    local activities=()
    
    for pane in $panes; do
        local activity=$(get_activity_description "$session" "$window" "$pane")
        activities+=("$activity")
    done
    
    # Create concise name from activities
    if [ ${#activities[@]} -eq 1 ]; then
        echo "${activities[0]}"
    else
        # Multiple panes - try to find the most relevant activity
        for activity in "${activities[@]}"; do
            if [[ "$activity" == claude:* ]]; then
                echo "$activity"
                return 0
            fi
        done
        
        # If no Claude, use the first non-shell activity
        for activity in "${activities[@]}"; do
            if [[ "$activity" != *":zsh" ]] && [[ "$activity" != *":bash" ]] && [[ "$activity" != "dir:"* ]]; then
                echo "$activity"
                return 0
            fi
        done
        
        # Fallback to first activity
        echo "${activities[0]}"
    fi
}

# Function to generate smart session name
generate_session_name() {
    local session="$1"
    
    # Get all windows in session
    local windows=$(tmux list-windows -t "$session" -F '#{window_index}')
    local claude_projects=()
    local other_projects=()
    
    for window in $windows; do
        local window_activity=$(generate_window_name "$session" "$window")
        
        if [[ "$window_activity" == ♦* ]]; then
            claude_projects+=("$window_activity")
        else
            other_projects+=("$window_activity")
        fi
    done
    
    # Prioritize Claude projects for session naming
    if [ ${#claude_projects[@]} -gt 0 ]; then
        # Find the most common Claude project
        local project=$(printf '%s\n' "${claude_projects[@]}" | sed 's/♦//' | sort | uniq -c | sort -nr | head -1 | awk '{$1=""; print $0}' | sed 's/^ //')
        if [ -n "$project" ] && [ "$project" != "claude" ]; then
            echo "♦$project"
        else
            echo "♦$(basename "$(tmux display -t "$session" -p '#{session_path}' 2>/dev/null || echo "$session")")"
        fi
    elif [ ${#other_projects[@]} -gt 0 ]; then
        # Use most common project, remove emoji prefixes for session name
        local project=$(printf '%s\n' "${other_projects[@]}" | sed 's/^[🔀📦📝🟢🦀🐹🐍]//' | sort | uniq -c | sort -nr | head -1 | awk '{$1=""; print $0}' | sed 's/^ //')
        echo "$project"
    else
        # Keep original name if nothing better found
        echo "$session"
    fi
}

# Main function to rename session and its windows
smart_rename_session() {
    local session="$1"
    local dry_run="$2"
    
    echo -e "${BLUE}Analyzing session: $session${NC}"
    
    # Generate new session name
    local new_session_name=$(generate_session_name "$session")
    
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}Session '$session' would be renamed to: '$new_session_name'${NC}"
    else
        if [ "$new_session_name" != "$session" ]; then
            tmux rename-session -t "$session" "$new_session_name"
            echo -e "${GREEN}Session renamed: $session -> $new_session_name${NC}"
            session="$new_session_name" # Update for window renaming
        fi
    fi
    
    # Rename windows
    local windows=$(tmux list-windows -t "$session" -F '#{window_index}:#{window_name}')
    while IFS=: read -r window_index current_name; do
        local new_window_name=$(generate_window_name "$session" "$window_index")
        
        if [ "$dry_run" = "true" ]; then
            echo -e "${CYAN}  Window $window_index '$current_name' would be renamed to: '$new_window_name'${NC}"
        else
            if [ "$new_window_name" != "$current_name" ]; then
                tmux rename-window -t "$session:$window_index" "$new_window_name"
                echo -e "${GREEN}  Window renamed: $current_name -> $new_window_name${NC}"
            fi
        fi
    done <<< "$windows"
}

# Function to watch and auto-rename
auto_rename_watch() {
    echo -e "${BLUE}Starting auto-rename watcher...${NC}"
    echo "Press Ctrl+C to stop"
    
    while true; do
        local sessions=$(tmux list-sessions -F '#{session_name}')
        for session in $sessions; do
            smart_rename_session "$session" false
        done
        sleep 30 # Check every 30 seconds
    done
}

# Main script - only run if not being sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
case "${1:-rename}" in
    "dry-run")
        echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
        sessions=$(tmux list-sessions -F '#{session_name}')
        for session in $sessions; do
            smart_rename_session "$session" true
            echo ""
        done
        ;;
    "watch")
        auto_rename_watch
        ;;
    "rename")
        sessions=$(tmux list-sessions -F '#{session_name}')
        for session in $sessions; do
            smart_rename_session "$session" false
            echo ""
        done
        ;;
    *)
        echo "Usage: $0 [dry-run|rename|watch]"
        echo ""
        echo "  dry-run - Show what would be renamed without making changes"
        echo "  rename  - Rename all sessions and windows once (default)"
        echo "  watch   - Continuously monitor and rename (every 30s)"
        exit 1
        ;;
esac
fi