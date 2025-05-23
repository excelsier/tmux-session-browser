#!/bin/bash

# Quick fix for terminal title synchronization
# Use this after renaming sessions to update terminal tabs

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔄 Fixing terminal titles for all tmux sessions...${NC}"

# Method 1: Force refresh all clients
tmux refresh-client -S 2>/dev/null && echo -e "${GREEN}✓ Refreshed all tmux clients${NC}"

# Method 2: Update current session title immediately
current_session=$(tmux display-message -p '#S' 2>/dev/null)
if [ -n "$current_session" ]; then
    printf '\033]0;tmux: %s\007' "$current_session"
    echo -e "${GREEN}✓ Updated current session title: $current_session${NC}"
fi

# Method 3: Trigger hooks for all sessions
sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)
count=0

for session in $sessions; do
    # Send escape sequence to update terminal title
    tmux run-shell -t "$session" "printf '\033]0;tmux: $session\007'" 2>/dev/null || true
    ((count++))
done

echo -e "${GREEN}✅ Fixed terminal titles for $count sessions${NC}"
echo -e "${YELLOW}💡 Terminal tabs should now show the correct session names${NC}"

# If run from within tmux, offer to refresh current terminal
if [ -n "$TMUX" ]; then
    echo ""
    echo -e "${BLUE}🔄 Refreshing current terminal title...${NC}"
    # Force immediate update of current terminal
    printf '\033]0;tmux: %s\007' "$(tmux display-message -p '#S')"
    echo -e "${GREEN}✅ Current terminal title updated${NC}"
fi