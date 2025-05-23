#!/bin/bash

# Tmux Sidebar Dashboard - Always-on session status with LLM summaries
# Shows live session info, what each session is working on, and command cheatsheet

# Configuration
REFRESH_INTERVAL=30  # Seconds between updates
SIDEBAR_WIDTH=40    # Percentage of screen width
CACHE_DIR="$HOME/.cache/tmux-sidebar"
LLM_CACHE_FILE="$CACHE_DIR/llm-summaries.cache"
SIDEBAR_FIFO="$CACHE_DIR/sidebar.fifo"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Create cache directory
mkdir -p "$CACHE_DIR"

# Function to get terminal width for formatting
get_sidebar_width() {
    local total_width=$(tput cols)
    local sidebar_chars=$((total_width * SIDEBAR_WIDTH / 100))
    echo $sidebar_chars
}

# Function to truncate text to fit sidebar
truncate_text() {
    local text="$1"
    local max_width="${2:-30}"
    if [ ${#text} -gt $max_width ]; then
        echo "${text:0:$((max_width-3))}..."
    else
        echo "$text"
    fi
}

# Function to get LLM summary from cache or generate
get_llm_summary() {
    local session="$1"
    local cache_key="${session}_summary"
    
    # Check cache age (5 minutes)
    if [ -f "$LLM_CACHE_FILE" ]; then
        local cache_entry=$(grep "^$cache_key:" "$LLM_CACHE_FILE" 2>/dev/null)
        if [ -n "$cache_entry" ]; then
            local timestamp=$(echo "$cache_entry" | cut -d: -f2)
            local summary=$(echo "$cache_entry" | cut -d: -f3-)
            local age=$(($(date +%s) - timestamp))
            
            if [ $age -lt 300 ]; then
                echo "$summary"
                return 0
            fi
        fi
    fi
    
    # Generate new summary if Claude is detected
    local has_claude=$(tmux list-panes -t "$session" -F '#{pane_pid}' 2>/dev/null | while read pid; do
        ps -p "$pid" -o command= 2>/dev/null | grep -q "claude" && echo "yes" && break
    done)
    
    if [ "$has_claude" = "yes" ] && command -v ollama >/dev/null 2>&1; then
        # Quick LLM analysis (simplified for performance)
        local content=$(tmux capture-pane -t "$session" -p -S -50 2>/dev/null | tail -20)
        local summary="Analyzing..."
        
        # Run in background to avoid blocking
        (
            if [ -n "$content" ]; then
                local prompt="In 5 words or less, what is this Claude session working on? Content: $content"
                summary=$(echo "$prompt" | timeout 3 ollama run llama3.2:latest 2>/dev/null | tr -d '\n' | cut -c1-30)
                
                # Update cache
                grep -v "^$cache_key:" "$LLM_CACHE_FILE" 2>/dev/null > "$LLM_CACHE_FILE.tmp" || true
                echo "$cache_key:$(date +%s):$summary" >> "$LLM_CACHE_FILE.tmp"
                mv "$LLM_CACHE_FILE.tmp" "$LLM_CACHE_FILE"
            fi
        ) &
        
        echo "Claude session"
    else
        echo "Shell session"
    fi
}

# Function to format session line
format_session_line() {
    local session="$1"
    local info="$2"
    local width="$3"
    
    # Parse session info
    local name=$(echo "$info" | cut -d: -f1)
    local windows=$(echo "$info" | cut -d: -f2)
    local attached=$(echo "$info" | cut -d: -f3)
    local activity=$(echo "$info" | cut -d: -f4)
    
    # Format attached status
    local status_icon="○"
    local status_color="$DIM"
    if [ "$attached" = "1" ]; then
        status_icon="●"
        status_color="$GREEN"
    fi
    
    # Get LLM summary
    local summary=$(get_llm_summary "$name")
    
    # Build formatted line
    local line=""
    line+="${status_color}${status_icon}${NC} "
    line+="${BOLD}$(truncate_text "$name" 12)${NC}"
    line+="${DIM} ($windows win)${NC}"
    
    # Add summary on next line
    echo -e "$line"
    echo -e "  ${DIM}→ $(truncate_text "$summary" $((width-4)))${NC}"
}

# Function to draw separator
draw_separator() {
    local width="$1"
    printf "${DIM}"
    printf '─%.0s' $(seq 1 $width)
    printf "${NC}\n"
}

# Function to display cheatsheet
display_cheatsheet() {
    local width="$1"
    
    echo -e "${BOLD}${CYAN}╭─ TMUX CHEATSHEET ─╮${NC}"
    echo ""
    echo -e "${YELLOW}Session Management:${NC}"
    echo -e " ${GREEN}C-a i${NC} → LLM dashboard"
    echo -e " ${GREEN}C-a u${NC} → Quick browse"
    echo -e " ${GREEN}C-a s${NC} → Session picker"
    echo -e " ${GREEN}C-a d${NC} → Detach"
    echo -e " ${GREEN}C-a $${NC} → Rename session"
    echo ""
    echo -e "${YELLOW}Window/Pane:${NC}"
    echo -e " ${GREEN}C-a c${NC} → New window"
    echo -e " ${GREEN}C-a n/p${NC} → Next/prev win"
    echo -e " ${GREEN}C-a 0-9${NC} → Go to window"
    echo -e " ${GREEN}C-a %${NC} → Split vertical"
    echo -e " ${GREEN}C-a \"${NC} → Split horizontal"
    echo -e " ${GREEN}C-a x${NC} → Kill pane"
    echo ""
    echo -e "${YELLOW}Navigation:${NC}"
    echo -e " ${GREEN}C-a ←↑↓→${NC} → Switch pane"
    echo -e " ${GREEN}C-a z${NC} → Zoom pane"
    echo -e " ${GREEN}C-a [${NC} → Scroll mode"
    echo -e " ${GREEN}C-a r${NC} → Reload config"
    echo ""
    echo -e "${DIM}Prefix: C-a (Ctrl+a)${NC}"
}

# Function to render the sidebar
render_sidebar() {
    local width=$(get_sidebar_width)
    
    # Clear screen
    clear
    
    # Header
    echo -e "${BOLD}${PURPLE}╭─ TMUX DASHBOARD ─╮${NC}"
    echo -e "${DIM}$(date '+%H:%M:%S') | Auto-refresh: ${REFRESH_INTERVAL}s${NC}"
    echo ""
    
    # Session Status Section
    echo -e "${BOLD}${BLUE}📊 SESSION STATUS${NC}"
    draw_separator $width
    
    # Get all sessions with info
    local sessions=$(tmux list-sessions -F '#{session_name}:#{session_windows}:#{session_attached}:#{session_activity}' 2>/dev/null)
    
    if [ -n "$sessions" ]; then
        echo "$sessions" | while IFS= read -r session_info; do
            format_session_line "$(echo "$session_info" | cut -d: -f1)" "$session_info" $width
            echo ""
        done
    else
        echo -e "${DIM}No sessions${NC}"
    fi
    
    draw_separator $width
    echo ""
    
    # Cheatsheet Section
    display_cheatsheet $width
    
    # Footer
    echo ""
    draw_separator $width
    echo -e "${DIM}Press 'q' to close sidebar${NC}"
    echo -e "${DIM}Press 'r' to refresh now${NC}"
    echo -e "${DIM}Press 'l' for LLM re-analyze${NC}"
}

# Function to handle user input
handle_input() {
    local char
    read -n1 -t $REFRESH_INTERVAL char 2>/dev/null
    
    case "$char" in
        "q"|"Q")
            return 1
            ;;
        "r"|"R")
            # Force refresh
            return 0
            ;;
        "l"|"L")
            # Clear LLM cache and refresh
            rm -f "$LLM_CACHE_FILE"
            return 0
            ;;
    esac
    
    return 0
}

# Function to run in sidebar mode
run_sidebar() {
    # Trap to clean up on exit
    trap "echo 'Sidebar closed'; exit 0" INT TERM
    
    echo -e "${BLUE}Starting Tmux Sidebar Dashboard...${NC}"
    sleep 1
    
    # Main loop
    while true; do
        render_sidebar
        
        # Wait for input or timeout
        if ! handle_input; then
            break
        fi
    done
}

# Function to launch sidebar in tmux pane
launch_in_tmux() {
    local position="${1:-right}"
    local size="${2:-$SIDEBAR_WIDTH}"
    
    case "$position" in
        "right")
            tmux split-window -h -l "$size%" "$0" run
            ;;
        "left")
            tmux split-window -hb -l "$size%" "$0" run
            ;;
        "top")
            tmux split-window -vb -l "$size%" "$0" run
            ;;
        "bottom")
            tmux split-window -v -l "$size%" "$0" run
            ;;
        *)
            echo "Invalid position: $position"
            exit 1
            ;;
    esac
}

# Function to toggle sidebar
toggle_sidebar() {
    # Check if sidebar is already running
    local sidebar_pane=$(tmux list-panes -F '#{pane_id}:#{pane_current_command}' | grep -E "tmux-sidebar-dashboard|bash.*sidebar" | cut -d: -f1 | head -1)
    
    if [ -n "$sidebar_pane" ]; then
        # Kill existing sidebar
        tmux kill-pane -t "$sidebar_pane"
        echo "Sidebar closed"
    else
        # Launch new sidebar
        launch_in_tmux "right" "$SIDEBAR_WIDTH"
    fi
}

# Main execution
case "${1:-toggle}" in
    "run")
        run_sidebar
        ;;
    "toggle")
        toggle_sidebar
        ;;
    "launch")
        launch_in_tmux "${2:-right}" "${3:-$SIDEBAR_WIDTH}"
        ;;
    "left"|"right"|"top"|"bottom")
        launch_in_tmux "$1" "${2:-$SIDEBAR_WIDTH}"
        ;;
    "help"|"-h"|"--help")
        echo "Tmux Sidebar Dashboard"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  run     - Run sidebar (internal use)"
        echo "  toggle  - Toggle sidebar on/off (default)"
        echo "  launch [position] [size] - Launch in specific position"
        echo "  left/right/top/bottom [size] - Quick launch"
        echo ""
        echo "Examples:"
        echo "  $0                    # Toggle sidebar"
        echo "  $0 right 30          # Right sidebar, 30% width"
        echo "  $0 left              # Left sidebar, default width"
        echo ""
        echo "In sidebar:"
        echo "  q - Quit"
        echo "  r - Refresh now"
        echo "  l - Re-analyze with LLM"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage"
        exit 1
        ;;
esac