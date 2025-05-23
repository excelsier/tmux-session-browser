#!/bin/bash

# Tmux Terminal Title Synchronization Helper
# Forces terminal titles to update after session/window renaming

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to force terminal title update for a specific session
update_session_title() {
    local session="$1"
    
    if [ -z "$session" ]; then
        echo "Usage: update_session_title <session_name>" >&2
        return 1
    fi
    
    # Force terminal title update using OSC escape sequence
    # This works for most modern terminals (iTerm2, Terminal.app, etc.)
    tmux send-keys -t "$session" C-m  # Send Enter to refresh
    tmux run-shell -t "$session" "echo -ne '\033]0;tmux: $session\007'" 2>/dev/null || true
    
    # Alternative method using tmux's built-in title setting
    tmux refresh-client -t "$session" 2>/dev/null || true
}

# Function to update terminal titles for all sessions
update_all_session_titles() {
    echo -e "${BLUE}🔄 Refreshing terminal titles for all sessions...${NC}"
    
    local sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)
    local count=0
    
    for session in $sessions; do
        update_session_title "$session"
        ((count++))
    done
    
    # Force global title refresh
    tmux refresh-client 2>/dev/null || true
    
    echo -e "${GREEN}✅ Updated terminal titles for $count sessions${NC}"
}

# Function to update titles for active/attached sessions only
update_active_session_titles() {
    echo -e "${BLUE}🔄 Refreshing terminal titles for active sessions...${NC}"
    
    local active_sessions=$(tmux list-sessions -F '#{session_name}:#{session_attached}' 2>/dev/null | grep ':1$' | cut -d: -f1)
    local count=0
    
    for session in $active_sessions; do
        update_session_title "$session"
        ((count++))
    done
    
    echo -e "${GREEN}✅ Updated terminal titles for $count active sessions${NC}"
}

# Function to set terminal title for current session
update_current_session_title() {
    local current_session=$(tmux display-message -p '#S' 2>/dev/null)
    
    if [ -n "$current_session" ]; then
        echo -e "${BLUE}🔄 Refreshing terminal title for current session: $current_session${NC}"
        update_session_title "$current_session"
        echo -e "${GREEN}✅ Updated terminal title${NC}"
    else
        echo -e "${YELLOW}⚠ Not in a tmux session${NC}" >&2
        return 1
    fi
}

# Function to force terminal title refresh using multiple methods
force_terminal_title_refresh() {
    local session="${1:-$(tmux display-message -p '#S' 2>/dev/null)}"
    
    if [ -z "$session" ]; then
        echo "No session specified and not in tmux" >&2
        return 1
    fi
    
    # Method 1: OSC escape sequence
    printf '\033]0;tmux: %s\007' "$session"
    
    # Method 2: tmux set-titles refresh
    tmux refresh-client -S 2>/dev/null || true
    
    # Method 3: Force hook trigger
    tmux run-shell "echo -ne '\033]0;tmux: $session\007'" 2>/dev/null || true
    
    # Method 4: Send to all clients
    tmux run-shell -t "$session" "printf '\033]0;tmux: $session\007'" 2>/dev/null || true
}

# Main execution
case "${1:-current}" in
    "all")
        update_all_session_titles
        ;;
    "active")
        update_active_session_titles
        ;;
    "current")
        update_current_session_title
        ;;
    "force")
        if [ -n "$2" ]; then
            force_terminal_title_refresh "$2"
        else
            force_terminal_title_refresh
        fi
        ;;
    "session")
        if [ -n "$2" ]; then
            update_session_title "$2"
        else
            echo "Usage: $0 session <session_name>" >&2
            exit 1
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Tmux Terminal Title Synchronization Helper"
        echo ""
        echo "Usage: $0 [command] [session_name]"
        echo ""
        echo "Commands:"
        echo "  all     - Update titles for all sessions"
        echo "  active  - Update titles for attached sessions only"
        echo "  current - Update title for current session (default)"
        echo "  force   - Force refresh using multiple methods"
        echo "  session <name> - Update specific session"
        echo "  help    - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 all              # Refresh all session titles"
        echo "  $0 session work     # Refresh 'work' session title"
        echo "  $0 force            # Force refresh current session"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac