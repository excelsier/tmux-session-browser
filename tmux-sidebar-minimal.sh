#!/bin/bash

# Tmux Minimal Sidebar - Clean, fast, always-on session monitor
# Optimized for persistent display with essential info

# Configuration
REFRESH_INTERVAL=10
SIDEBAR_WIDTH=30
CACHE_DIR="$HOME/.cache/tmux-sidebar"
LLM_CACHE_FILE="$CACHE_DIR/llm-minimal.cache"

# Minimal color scheme
ACTIVE='\033[1;32m'    # Bright green
INACTIVE='\033[0;90m'  # Gray
CLAUDE='\033[1;35m'    # Bright purple
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Create cache directory
mkdir -p "$CACHE_DIR"

# Check for LLM
HAS_LLM=false
if command -v ollama >/dev/null 2>&1; then
    HAS_LLM=true
fi

# Get LLM insight (cached)
get_insight() {
    local session="$1"
    local cache_key="$session"
    
    # Check cache (10 min TTL)
    if [ -f "$LLM_CACHE_FILE" ]; then
        local entry=$(grep "^$cache_key:" "$LLM_CACHE_FILE" 2>/dev/null | tail -1)
        if [ -n "$entry" ]; then
            local ts=$(echo "$entry" | cut -d: -f2)
            local text=$(echo "$entry" | cut -d: -f3-)
            if [ $(($(date +%s) - ts)) -lt 600 ]; then
                echo "$text"
                return
            fi
        fi
    fi
    
    # Check for Claude
    local has_claude=$(tmux list-panes -t "$session" -F '#{pane_current_command}' 2>/dev/null | grep -E "(node|claude)" | head -1)
    
    if [ -n "$has_claude" ] && [ "$HAS_LLM" = true ]; then
        # Quick LLM check in background
        (
            local content=$(tmux capture-pane -t "$session" -p -S -20 2>/dev/null | tail -5 | tr '\n' ' ' | cut -c1-100)
            if [ -n "$content" ]; then
                local insight=$(echo "Task in 3 words: $content" | timeout 1 ollama run llama3.2:latest 2>/dev/null | tr -d '\n' | cut -c1-20)
                if [ -n "$insight" ]; then
                    echo "$cache_key:$(date +%s):$insight" >> "$LLM_CACHE_FILE"
                fi
            fi
        ) 2>/dev/null &
        echo "..."
    else
        echo ""
    fi
}

# Main display
show_sidebar() {
    clear
    
    # Header
    echo -e "${BOLD}TMUX SESSIONS${NC} $(date +%H:%M)"
    echo -e "${DIM}────────────────────────────${NC}"
    
    # Sessions
    tmux list-sessions -F '#{session_name}:#{session_windows}:#{session_attached}:#{session_activity}' 2>/dev/null | while IFS=: read -r name wins att act; do
        # Status
        if [ "$att" = "1" ]; then
            status="${ACTIVE}●${NC}"
        else
            local age=$(($(date +%s) - act))
            if [ $age -lt 300 ]; then
                status="${ACTIVE}○${NC}"
            else
                status="${INACTIVE}○${NC}"
            fi
        fi
        
        # Claude indicator
        local claude_icon=""
        if tmux list-panes -t "$name" -F '#{pane_current_command}' 2>/dev/null | grep -qE "(node|claude)"; then
            claude_icon="${CLAUDE}♦${NC} "
        fi
        
        # Display
        printf "%s %s%-12s ${DIM}%sw${NC}\n" "$status" "$claude_icon" "$name" "$wins"
        
        # LLM insight (if available)
        if [ -n "$claude_icon" ]; then
            local insight=$(get_insight "$name")
            if [ -n "$insight" ]; then
                printf "  ${DIM}→ %s${NC}\n" "$insight"
            fi
        fi
    done
    
    # Separator
    echo -e "\n${DIM}────────────────────────────${NC}"
    
    # Mini cheatsheet
    echo -e "${BOLD}COMMANDS${NC}"
    echo -e "${DIM}C-a i${NC} → AI dashboard"
    echo -e "${DIM}C-a s${NC} → Browse sessions"
    echo -e "${DIM}C-a d${NC} → Detach"
    echo -e "${DIM}C-a c${NC} → New window"
    echo -e "${DIM}C-a n/p${NC} → Next/prev"
    
    # Footer
    echo -e "\n${DIM}[q]uit [r]efresh${NC}"
}

# Main loop
run_sidebar() {
    trap 'tput cnorm; exit 0' INT TERM EXIT
    tput civis  # Hide cursor
    
    while true; do
        show_sidebar
        
        # Non-blocking input check
        if read -t $REFRESH_INTERVAL -n1 key 2>/dev/null; then
            case "$key" in
                q|Q) break ;;
                r|R) continue ;;
            esac
        fi
    done
}

# Toggle function
toggle_sidebar() {
    local existing=$(tmux list-panes -F '#{pane_id}:#{pane_current_command}' | grep sidebar | cut -d: -f1 | head -1)
    
    if [ -n "$existing" ]; then
        tmux kill-pane -t "$existing"
    else
        tmux split-window -h -l 30 "$0 run"
    fi
}

# Main
case "${1:-toggle}" in
    run) run_sidebar ;;
    toggle) toggle_sidebar ;;
    *) toggle_sidebar ;;
esac