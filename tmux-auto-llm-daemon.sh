#!/usr/bin/env bash

# tmux-auto-llm-daemon.sh - Background service for automatic LLM session renaming
# This daemon periodically renames tmux sessions based on their content using LLM

set -euo pipefail

# Configuration
DAEMON_NAME="tmux-auto-llm"
PID_FILE="/tmp/${DAEMON_NAME}.pid"
LOG_FILE="/tmp/${DAEMON_NAME}.log"
CACHE_DIR="/tmp/tmux-llm-cache"
INTERVAL="${TMUX_LLM_INTERVAL:-300}"  # Default 5 minutes
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2}"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Check if daemon is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

# Get content hash for a session to detect changes
get_content_hash() {
    local session="$1"
    local content=$(tmux capture-pane -t "$session" -p -S -2000 2>/dev/null | tail -100)
    echo "$content" | sha256sum | cut -d' ' -f1
}

# Check if session needs renaming
needs_renaming() {
    local session="$1"
    local current_hash=$(get_content_hash "$session")
    local cache_file="$CACHE_DIR/${session}.hash"
    
    # Check if we have a cached hash
    if [ -f "$cache_file" ]; then
        local cached_hash=$(cat "$cache_file")
        if [ "$current_hash" = "$cached_hash" ]; then
            return 1  # No changes, skip
        fi
    fi
    
    # Save new hash
    echo "$current_hash" > "$cache_file"
    return 0  # Needs renaming
}

# Analyze session content with LLM
analyze_with_llm() {
    local session="$1"
    local window="${2:-}"
    local pane="${3:-}"
    
    log "Analyzing session: $session"
    
    # Get terminal content
    local terminal_history=""
    if [ -n "$window" ] && [ -n "$pane" ]; then
        terminal_history=$(tmux capture-pane -t "$session:$window.$pane" -p -S -2000 2>/dev/null | tail -100)
    else
        terminal_history=$(tmux capture-pane -t "$session" -p -S -2000 2>/dev/null | tail -100)
    fi
    
    # Check if it's empty or too short
    if [ -z "$terminal_history" ] || [ ${#terminal_history} -lt 50 ]; then
        log "Session $session has no significant content"
        return 1
    fi
    
    # Check for Claude Code activity
    local is_claude=0
    if echo "$terminal_history" | grep -q "Claude Code\|claude-code\|Assistant:\|Human:"; then
        is_claude=1
        log "Detected Claude Code session"
    fi
    
    # Prepare prompt based on context
    local prompt=""
    if [ $is_claude -eq 1 ]; then
        prompt="Analyze this Claude Code conversation and suggest a 2-4 word tmux session name that describes what's being worked on. Focus on the specific task or feature. Examples: 'debug-auth-flow', 'setup-docker-env', 'fix-api-tests'. Just output the name, nothing else."
    else
        prompt="Analyze this terminal session and suggest a 2-4 word tmux session name. Examples: 'vim-config', 'npm-install', 'git-commits'. Just output the name, nothing else."
    fi
    
    # Call Ollama
    local suggested_name=$(echo "$terminal_history" | ollama run "$OLLAMA_MODEL" "$prompt" 2>/dev/null | tr -d '\n' | sed 's/[^a-zA-Z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
    
    if [ -n "$suggested_name" ] && [ "$suggested_name" != "$session" ]; then
        log "Suggested name for $session: $suggested_name"
        echo "$suggested_name"
        return 0
    fi
    
    return 1
}

# Rename sessions that need it
rename_sessions() {
    log "Starting rename cycle"
    
    # Get all sessions
    local sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null || true)
    
    if [ -z "$sessions" ]; then
        log "No tmux sessions found"
        return
    fi
    
    local renamed_count=0
    
    while IFS= read -r session; do
        # Skip system sessions and already well-named sessions
        if [[ "$session" =~ ^(popup-|_) ]] || [[ "$session" =~ ^[0-9]+$ ]]; then
            continue
        fi
        
        # Check if content has changed
        if ! needs_renaming "$session"; then
            log "Session $session hasn't changed, skipping"
            continue
        fi
        
        # Get new name suggestion
        if new_name=$(analyze_with_llm "$session"); then
            # Check if new name is different and not already taken
            if [ "$new_name" != "$session" ] && ! tmux has-session -t "$new_name" 2>/dev/null; then
                tmux rename-session -t "$session" "$new_name" 2>/dev/null && {
                    log "Renamed: $session -> $new_name"
                    renamed_count=$((renamed_count + 1))
                    
                    # Update terminal title
                    tmux send-keys -t "$new_name" "" C-m 2>/dev/null || true
                    
                    # Update cache with new session name
                    if [ -f "$CACHE_DIR/${session}.hash" ]; then
                        mv "$CACHE_DIR/${session}.hash" "$CACHE_DIR/${new_name}.hash"
                    fi
                }
            fi
        fi
        
        # Small delay to avoid overloading
        sleep 1
    done <<< "$sessions"
    
    log "Rename cycle complete. Renamed $renamed_count sessions"
}

# Main daemon loop
daemon_loop() {
    log "Daemon started with PID $$, interval: ${INTERVAL}s"
    
    # Save PID
    echo $$ > "$PID_FILE"
    
    # Trap signals for clean shutdown
    trap 'log "Daemon stopped"; rm -f "$PID_FILE"; exit 0' SIGTERM SIGINT
    
    while true; do
        rename_sessions
        sleep "$INTERVAL"
    done
}

# Start daemon
start_daemon() {
    if is_running; then
        echo -e "${YELLOW}Daemon is already running${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Starting $DAEMON_NAME daemon...${NC}"
    nohup "$0" daemon > /dev/null 2>&1 &
    sleep 1
    
    if is_running; then
        echo -e "${GREEN}Daemon started successfully${NC}"
        echo "Check logs at: $LOG_FILE"
    else
        echo -e "${RED}Failed to start daemon${NC}"
        return 1
    fi
}

# Stop daemon
stop_daemon() {
    if ! is_running; then
        echo -e "${YELLOW}Daemon is not running${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Stopping $DAEMON_NAME daemon...${NC}"
    local pid=$(cat "$PID_FILE")
    kill "$pid" 2>/dev/null
    
    # Wait for process to stop
    local count=0
    while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if ! ps -p "$pid" > /dev/null 2>&1; then
        rm -f "$PID_FILE"
        echo -e "${GREEN}Daemon stopped${NC}"
    else
        echo -e "${RED}Failed to stop daemon gracefully, forcing...${NC}"
        kill -9 "$pid" 2>/dev/null
        rm -f "$PID_FILE"
    fi
}

# Show daemon status
show_status() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        echo -e "${GREEN}✓ Daemon is running${NC} (PID: $pid)"
        echo "Interval: ${INTERVAL}s"
        echo "Log file: $LOG_FILE"
        
        # Show recent activity
        if [ -f "$LOG_FILE" ]; then
            echo -e "\nRecent activity:"
            tail -5 "$LOG_FILE" | sed 's/^/  /'
        fi
    else
        echo -e "${RED}✗ Daemon is not running${NC}"
    fi
}

# Run single rename cycle
run_once() {
    echo -e "${GREEN}Running single rename cycle...${NC}"
    rename_sessions
    echo -e "${GREEN}Done${NC}"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 {start|stop|restart|status|once|daemon}

Commands:
  start    - Start the auto-rename daemon
  stop     - Stop the auto-rename daemon
  restart  - Restart the daemon
  status   - Show daemon status
  once     - Run rename cycle once (no daemon)
  daemon   - Run in daemon mode (internal use)

Environment variables:
  TMUX_LLM_INTERVAL - Seconds between rename cycles (default: 300)
  OLLAMA_MODEL      - Ollama model to use (default: llama3.2)

Example:
  # Start with 10 minute interval
  TMUX_LLM_INTERVAL=600 $0 start
EOF
}

# Main command handler
case "${1:-}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    status)
        show_status
        ;;
    once)
        run_once
        ;;
    daemon)
        daemon_loop
        ;;
    *)
        usage
        exit 1
        ;;
esac