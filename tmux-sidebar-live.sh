#!/bin/bash

# Tmux Live Sidebar - Real-time session monitoring with LLM insights
# Persistent sidebar showing session status, activities, and commands

# Configuration
REFRESH_INTERVAL=5   # Seconds between updates (faster for live feel)
SIDEBAR_WIDTH=35     # Percentage of screen width
CACHE_DIR="$HOME/.cache/tmux-sidebar"
LLM_CACHE_FILE="$CACHE_DIR/llm-summaries.cache"
LLM_CACHE_TTL=180    # 3 minutes cache for LLM results

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
NC='\033[0m'

# Unicode characters
CHECK='✓'
CROSS='✗'
DOT='•'
ARROW='→'
STAR='★'
DIAMOND='♦'
CIRCLE='○'
FILLED_CIRCLE='●'
BOX_H='─'
BOX_V='│'
BOX_TL='╭'
BOX_TR='╮'
BOX_BL='╰'
BOX_BR='╯'

# Create cache directory
mkdir -p "$CACHE_DIR"

# Global variables
SIDEBAR_PID=$$
LAST_UPDATE=0
LLM_AVAILABLE=false

# Check if Ollama is available
if command -v ollama >/dev/null 2>&1 && ollama list | grep -q "llama3.2:latest"; then
    LLM_AVAILABLE=true
fi

# Function to get terminal dimensions
get_dimensions() {
    local height=$(tput lines)
    local width=$(tput cols)
    local sidebar_width=$((width * SIDEBAR_WIDTH / 100))
    echo "$height:$width:$sidebar_width"
}

# Function to draw a box with title
draw_box() {
    local title="$1"
    local width="$2"
    local title_len=${#title}
    local padding=$(( (width - title_len - 2) / 2 ))
    
    # Top border with title
    printf "${BOLD}${BOX_TL}"
    printf "${BOX_H}%.0s" $(seq 1 $padding)
    printf " $title "
    printf "${BOX_H}%.0s" $(seq 1 $((width - padding - title_len - 2)))
    printf "${BOX_TR}${NC}\n"
}

# Function to close box
close_box() {
    local width="$1"
    printf "${BOLD}${BOX_BL}"
    printf "${BOX_H}%.0s" $(seq 1 $((width)))
    printf "${BOX_BR}${NC}\n"
}

# Function to truncate and pad text
format_text() {
    local text="$1"
    local max_width="$2"
    local align="${3:-left}"
    
    # Remove color codes for length calculation
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    
    if [ $text_len -gt $max_width ]; then
        # Truncate
        echo -e "${text:0:$((max_width-3))}..."
    elif [ "$align" = "center" ]; then
        # Center align
        local padding=$(( (max_width - text_len) / 2 ))
        printf "%*s%s%*s" $padding "" "$text" $((max_width - text_len - padding)) ""
    elif [ "$align" = "right" ]; then
        # Right align
        printf "%*s%s" $((max_width - text_len)) "" "$text"
    else
        # Left align with padding
        printf "%-*s" $max_width "$text"
    fi
}

# Function to get session activity indicator
get_activity_indicator() {
    local session="$1"
    local last_activity="$2"
    local current_time=$(date +%s)
    local activity_age=$((current_time - last_activity))
    
    if [ $activity_age -lt 60 ]; then
        echo "${GREEN}${FILLED_CIRCLE}${NC}"  # Active (< 1 min)
    elif [ $activity_age -lt 300 ]; then
        echo "${YELLOW}${FILLED_CIRCLE}${NC}"  # Recent (< 5 min)
    elif [ $activity_age -lt 3600 ]; then
        echo "${DIM}${FILLED_CIRCLE}${NC}"    # Idle (< 1 hour)
    else
        echo "${DIM}${CIRCLE}${NC}"           # Inactive
    fi
}

# Function to get quick LLM summary
get_quick_llm_summary() {
    local session="$1"
    
    # Check cache first
    local cache_key="${session}_llm"
    if [ -f "$LLM_CACHE_FILE" ]; then
        local cache_entry=$(grep "^$cache_key:" "$LLM_CACHE_FILE" 2>/dev/null | tail -1)
        if [ -n "$cache_entry" ]; then
            local timestamp=$(echo "$cache_entry" | cut -d: -f2)
            local summary=$(echo "$cache_entry" | cut -d: -f3-)
            local age=$(($(date +%s) - timestamp))
            
            if [ $age -lt $LLM_CACHE_TTL ]; then
                echo "$summary"
                return 0
            fi
        fi
    fi
    
    # Check if Claude is running
    local claude_panes=$(tmux list-panes -t "$session" -F '#{pane_id}:#{pane_current_command}' 2>/dev/null | grep -E "(node|claude)" || true)
    
    if [ -n "$claude_panes" ] && [ "$LLM_AVAILABLE" = true ]; then
        # Get minimal content for speed
        local content=$(tmux capture-pane -t "$session" -p -S -30 2>/dev/null | tail -10 | tr '\n' ' ' | cut -c1-200)
        
        if [ -n "$content" ]; then
            # Run LLM analysis in background
            (
                local prompt="In exactly 3-5 words, what task is being worked on? Content: $content"
                local summary=$(echo "$prompt" | timeout 2 ollama run llama3.2:latest 2>/dev/null | tr -d '\n' | sed 's/[^a-zA-Z0-9 -]//g' | cut -c1-25)
                
                if [ -n "$summary" ]; then
                    # Update cache
                    echo "$cache_key:$(date +%s):${DIAMOND} $summary" >> "$LLM_CACHE_FILE"
                fi
            ) 2>/dev/null &
            
            echo "${DIAMOND} Analyzing..."
        else
            echo "${DIAMOND} Claude active"
        fi
    else
        # Get current directory or command
        local pane_path=$(tmux display -t "$session:1.1" -p '#{pane_current_path}' 2>/dev/null | xargs basename 2>/dev/null)
        if [ -n "$pane_path" ] && [ "$pane_path" != "krempovych" ]; then
            echo "📁 $pane_path"
        else
            echo "🔧 Shell session"
        fi
    fi
}

# Function to display session panel
display_sessions() {
    local dims="$1"
    local width=$(echo "$dims" | cut -d: -f3)
    local inner_width=$((width - 2))
    
    draw_box "ACTIVE SESSIONS" $width
    
    # Get all sessions with detailed info
    local sessions=$(tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_attached}|#{session_activity}|#{session_created}' 2>/dev/null | sort)
    
    if [ -z "$sessions" ]; then
        printf " ${DIM}No active sessions${NC}\n"
        close_box $width
        return
    fi
    
    # Display each session
    echo "$sessions" | while IFS='|' read -r name windows attached activity created; do
        # Activity indicator
        local indicator=$(get_activity_indicator "$name" "$activity")
        
        # Attached status
        local attach_icon=""
        if [ "$attached" = "1" ]; then
            attach_icon="${GREEN}▶${NC}"
        fi
        
        # Session name line
        printf " %s %s%s ${DIM}(%s win)${NC}\n" \
            "$indicator" \
            "$(format_text "${BOLD}$name${NC}" 20)" \
            "$attach_icon" \
            "$windows"
        
        # LLM summary line
        local summary=$(get_quick_llm_summary "$name")
        printf "   ${DIM}%s${NC}\n" "$(format_text "$summary" $((inner_width - 3)))"
        
        # Separator
        printf " ${DIM}"
        printf '·%.0s' $(seq 1 $((inner_width)))
        printf "${NC}\n"
    done
    
    close_box $width
}

# Function to display command reference
display_commands() {
    local dims="$1"
    local width=$(echo "$dims" | cut -d: -f3)
    
    draw_box "QUICK COMMANDS" $width
    
    # Session commands
    printf " ${YELLOW}${UNDERLINE}Sessions:${NC}\n"
    printf " ${GREEN}C-a i${NC}  ${ARROW} AI dashboard\n"
    printf " ${GREEN}C-a u${NC}  ${ARROW} Browse & clean\n"
    printf " ${GREEN}C-a s${NC}  ${ARROW} Session picker\n"
    printf " ${GREEN}C-a d${NC}  ${ARROW} Detach session\n"
    printf " ${GREEN}C-a \$${NC}  ${ARROW} Rename session\n"
    printf "\n"
    
    # Window commands
    printf " ${YELLOW}${UNDERLINE}Windows:${NC}\n"
    printf " ${GREEN}C-a c${NC}  ${ARROW} New window\n"
    printf " ${GREEN}C-a n/p${NC} ${ARROW} Next/Previous\n"
    printf " ${GREEN}C-a 0-9${NC} ${ARROW} Jump to #\n"
    printf " ${GREEN}C-a ,${NC}  ${ARROW} Rename window\n"
    printf "\n"
    
    # Pane commands
    printf " ${YELLOW}${UNDERLINE}Panes:${NC}\n"
    printf " ${GREEN}C-a %%${NC}  ${ARROW} Split vertical\n"
    printf " ${GREEN}C-a \"${NC}  ${ARROW} Split horizontal\n"
    printf " ${GREEN}C-a arrows${NC} ${ARROW} Navigate\n"
    printf " ${GREEN}C-a z${NC}  ${ARROW} Zoom toggle\n"
    
    close_box $width
}

# Function to display status bar
display_status() {
    local dims="$1"
    local width=$(echo "$dims" | cut -d: -f3)
    
    draw_box "STATUS" $width
    
    # Time and refresh info
    printf " ${BOLD}Time:${NC} $(date '+%H:%M:%S')\n"
    printf " ${BOLD}Refresh:${NC} Every ${REFRESH_INTERVAL}s\n"
    
    # LLM status
    if [ "$LLM_AVAILABLE" = true ]; then
        printf " ${BOLD}AI:${NC} ${GREEN}${CHECK} Available${NC}\n"
    else
        printf " ${BOLD}AI:${NC} ${DIM}${CROSS} Offline${NC}\n"
    fi
    
    # Session count
    local session_count=$(tmux list-sessions 2>/dev/null | wc -l)
    printf " ${BOLD}Sessions:${NC} $session_count active\n"
    
    close_box $width
}

# Function to display controls
display_controls() {
    local dims="$1"
    local width=$(echo "$dims" | cut -d: -f3)
    
    printf "\n"
    printf " ${DIM}[q] Quit ${BOX_V} [r] Refresh ${BOX_V} [l] Re-analyze${NC}\n"
    printf " ${DIM}[t] Toggle position ${BOX_V} [w] Width${NC}\n"
}

# Main render function
render_dashboard() {
    local dims=$(get_dimensions)
    local height=$(echo "$dims" | cut -d: -f1)
    local width=$(echo "$dims" | cut -d: -f2)
    local sidebar_width=$(echo "$dims" | cut -d: -f3)
    
    # Clear screen and reset cursor
    clear
    tput cup 0 0
    
    # Header
    printf "${BOLD}${PURPLE}"
    format_text "♦ TMUX LIVE DASHBOARD ♦" $sidebar_width "center"
    printf "${NC}\n\n"
    
    # Sessions panel
    display_sessions "$dims"
    echo ""
    
    # Commands panel
    display_commands "$dims"
    echo ""
    
    # Status panel
    display_status "$dims"
    
    # Controls
    display_controls "$dims"
    
    # Update timestamp
    LAST_UPDATE=$(date +%s)
}

# Function to handle continuous updates
run_live_dashboard() {
    # Hide cursor
    tput civis
    
    # Trap to restore cursor on exit
    trap 'tput cnorm; echo -e "\n${GREEN}Dashboard closed${NC}"; exit 0' INT TERM EXIT
    
    # Initial render
    render_dashboard
    
    # Main loop with non-blocking input
    while true; do
        # Check for user input (non-blocking)
        if read -t $REFRESH_INTERVAL -n1 key; then
            case "$key" in
                "q"|"Q")
                    break
                    ;;
                "r"|"R")
                    # Force refresh
                    render_dashboard
                    continue
                    ;;
                "l"|"L")
                    # Clear LLM cache
                    rm -f "$LLM_CACHE_FILE"
                    render_dashboard
                    continue
                    ;;
                "t"|"T")
                    # Toggle position (requires restart)
                    echo -e "\n${YELLOW}Restarting in opposite position...${NC}"
                    sleep 1
                    break
                    ;;
                "w"|"W")
                    # Adjust width (placeholder)
                    echo -e "\n${YELLOW}Width adjustment coming soon...${NC}"
                    sleep 1
                    render_dashboard
                    continue
                    ;;
            esac
        fi
        
        # Auto-refresh
        render_dashboard
    done
}

# Function to check if sidebar is running
is_sidebar_running() {
    tmux list-panes -F '#{pane_id}:#{pane_current_command}' 2>/dev/null | \
        grep -E "sidebar-(dashboard|live)" >/dev/null 2>&1
}

# Function to kill existing sidebar
kill_sidebar() {
    local sidebar_panes=$(tmux list-panes -F '#{pane_id}:#{pane_current_command}' 2>/dev/null | \
        grep -E "sidebar-(dashboard|live)" | cut -d: -f1)
    
    for pane in $sidebar_panes; do
        tmux kill-pane -t "$pane" 2>/dev/null || true
    done
}

# Function to launch sidebar
launch_sidebar() {
    local position="${1:-right}"
    local size="${2:-$SIDEBAR_WIDTH}"
    
    # Kill existing sidebar first
    kill_sidebar
    
    # Launch new sidebar
    case "$position" in
        "right")
            tmux split-window -h -l "${size}%" -c "#{pane_current_path}" "$0 run"
            ;;
        "left")
            tmux split-window -hb -l "${size}%" -c "#{pane_current_path}" "$0 run"
            ;;
        *)
            echo "Invalid position: $position"
            return 1
            ;;
    esac
}

# Main execution
case "${1:-toggle}" in
    "run")
        run_live_dashboard
        ;;
    "toggle")
        if is_sidebar_running; then
            kill_sidebar
            echo "Sidebar closed"
        else
            launch_sidebar "right"
        fi
        ;;
    "left"|"right")
        launch_sidebar "$1" "${2:-$SIDEBAR_WIDTH}"
        ;;
    "kill")
        kill_sidebar
        echo "Sidebar closed"
        ;;
    "help"|"-h"|"--help")
        echo "Tmux Live Sidebar Dashboard"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  toggle      - Toggle sidebar on/off (default)"
        echo "  left [size] - Launch on left side"
        echo "  right [size] - Launch on right side"
        echo "  kill        - Close sidebar"
        echo ""
        echo "Controls:"
        echo "  q - Quit sidebar"
        echo "  r - Force refresh"
        echo "  l - Clear LLM cache and re-analyze"
        echo "  t - Toggle position"
        echo ""
        echo "Features:"
        echo "  • Real-time session monitoring"
        echo "  • LLM-powered activity summaries"
        echo "  • Command cheatsheet"
        echo "  • Auto-refresh every ${REFRESH_INTERVAL}s"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage"
        exit 1
        ;;
esac