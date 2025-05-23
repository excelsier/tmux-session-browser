#!/usr/bin/env bash

# tmux-auto-llm-simple.sh - Simple automatic LLM renaming for tmux sessions
# Can be called from cron, tmux hooks, or manually

set -euo pipefail

# Configuration
CACHE_DIR="/tmp/tmux-llm-cache"
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2}"
MIN_CONTENT_LENGTH=50
SKIP_PATTERNS="^(popup-|_|[0-9]+$)"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Source the LLM naming script for the analyze function
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tmux-llm-naming.sh" 2>/dev/null || {
    echo "Error: Could not source tmux-llm-naming.sh"
    exit 1
}

# Get content hash to detect changes
get_content_hash() {
    local session="$1"
    local content=$(tmux capture-pane -t "$session" -p -S -2000 2>/dev/null | tail -100)
    echo "$content" | sha256sum | cut -d' ' -f1
}

# Check if session should be renamed
should_rename() {
    local session="$1"
    
    # Skip system sessions
    if [[ "$session" =~ $SKIP_PATTERNS ]]; then
        return 1
    fi
    
    # Check content hash
    local current_hash=$(get_content_hash "$session")
    local cache_file="$CACHE_DIR/${session}.hash"
    
    if [ -f "$cache_file" ]; then
        local cached_hash=$(cat "$cache_file")
        if [ "$current_hash" = "$cached_hash" ]; then
            return 1  # No changes
        fi
    fi
    
    # Save new hash
    echo "$current_hash" > "$cache_file"
    return 0
}

# Main rename function
auto_rename_sessions() {
    local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null || true)
    
    if [ -z "$sessions" ]; then
        return
    fi
    
    while IFS= read -r session; do
        if should_rename "$session"; then
            # Use the analyze_with_llm function from tmux-llm-naming.sh
            if new_name=$(analyze_with_llm "$session" 2>/dev/null); then
                if [ -n "$new_name" ] && [ "$new_name" != "$session" ] && ! tmux has-session -t "$new_name" 2>/dev/null; then
                    tmux rename-session -t "$session" "$new_name" 2>/dev/null && {
                        echo "Renamed: $session -> $new_name"
                        
                        # Update cache
                        if [ -f "$CACHE_DIR/${session}.hash" ]; then
                            mv "$CACHE_DIR/${session}.hash" "$CACHE_DIR/${new_name}.hash"
                        fi
                    }
                fi
            fi
        fi
    done <<< "$sessions"
}

# Run the auto-rename
auto_rename_sessions