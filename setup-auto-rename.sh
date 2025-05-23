#!/usr/bin/env bash

# setup-auto-rename.sh - Set up automatic LLM renaming for tmux

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}tmux Auto-LLM Rename Setup${NC}"
echo "==============================="
echo

# Options
echo "Choose your setup method:"
echo
echo "1) Daemon - Runs in background, renames every 5 minutes"
echo "2) Hooks - Renames when switching sessions or after idle time"
echo "3) Cron - Runs at specific intervals via crontab"
echo "4) Manual - Just the keybinding for on-demand renaming"
echo
read -p "Select option (1-4): " choice

case $choice in
    1)
        echo -e "\n${GREEN}Setting up daemon...${NC}"
        
        # Make scripts executable
        chmod +x "$SCRIPT_DIR/tmux-auto-llm-daemon.sh"
        
        # Add to shell profile for auto-start
        echo -e "\n${YELLOW}Add this to your shell profile (.zshrc or .bashrc):${NC}"
        echo "# Auto-start tmux LLM rename daemon"
        echo "if command -v tmux &> /dev/null && [ -z \"\$TMUX\" ]; then"
        echo "    $SCRIPT_DIR/tmux-auto-llm-daemon.sh start &> /dev/null"
        echo "fi"
        echo
        echo -e "${GREEN}Start daemon now with:${NC}"
        echo "$SCRIPT_DIR/tmux-auto-llm-daemon.sh start"
        echo
        echo "Control commands:"
        echo "  Start:   $SCRIPT_DIR/tmux-auto-llm-daemon.sh start"
        echo "  Stop:    $SCRIPT_DIR/tmux-auto-llm-daemon.sh stop"
        echo "  Status:  $SCRIPT_DIR/tmux-auto-llm-daemon.sh status"
        echo
        echo "Set custom interval: TMUX_LLM_INTERVAL=600 (for 10 minutes)"
        ;;
        
    2)
        echo -e "\n${GREEN}Setting up tmux hooks...${NC}"
        
        # Make script executable
        chmod +x "$SCRIPT_DIR/tmux-auto-llm-simple.sh"
        
        # Add hooks to tmux.conf
        echo -e "\n${YELLOW}Add these to your ~/.tmux.conf:${NC}"
        cat << 'EOF'
# Auto-rename with LLM on session switch (with delay)
set-hook -g client-session-changed 'run-shell -b "sleep 2 && /Users/krempovych/tmux-session-browser/tmux-auto-llm-simple.sh &"'

# Auto-rename after idle time (5 minutes)
set-hook -g client-activity 'run-shell -b "( sleep 300 && /Users/krempovych/tmux-session-browser/tmux-auto-llm-simple.sh ) &"'

# Optional: Auto-rename on new window
set-hook -g window-linked 'run-shell -b "sleep 3 && /Users/krempovych/tmux-session-browser/tmux-auto-llm-simple.sh &"'
EOF
        echo
        echo -e "${GREEN}Reload tmux config:${NC} tmux source ~/.tmux.conf"
        ;;
        
    3)
        echo -e "\n${GREEN}Setting up cron job...${NC}"
        
        # Make script executable
        chmod +x "$SCRIPT_DIR/tmux-auto-llm-simple.sh"
        
        # Show crontab entry
        echo -e "\n${YELLOW}Add this to your crontab (crontab -e):${NC}"
        echo "# Run tmux auto-rename every 10 minutes"
        echo "*/10 * * * * /Users/krempovych/tmux-session-browser/tmux-auto-llm-simple.sh > /dev/null 2>&1"
        echo
        echo "Or for every 5 minutes:"
        echo "*/5 * * * * /Users/krempovych/tmux-session-browser/tmux-auto-llm-simple.sh > /dev/null 2>&1"
        ;;
        
    4)
        echo -e "\n${GREEN}Manual mode - use existing keybindings${NC}"
        echo
        echo "Available keybindings:"
        echo "  C-a i - Interactive LLM rename and browse"
        echo "  C-a r - Quick rename current session"
        echo "  C-a R - Rename all sessions"
        ;;
esac

echo
echo -e "${GREEN}Additional keybinding for quick rename:${NC}"
echo -e "${YELLOW}Add to ~/.tmux.conf:${NC}"
echo "# Quick LLM rename all sessions"
echo "bind-key R run-shell '/Users/krempovych/tmux-session-browser/tmux-auto-llm-simple.sh'"
echo
echo -e "${GREEN}Setup complete!${NC}"