#!/bin/bash

# Tmux Session Browser Installer
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Tmux Session Browser Installer${NC}"
echo "=================================="

# Check dependencies
echo -e "\n${YELLOW}Checking dependencies...${NC}"

if ! command -v tmux &> /dev/null; then
    echo -e "${RED}Error: tmux is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ tmux found${NC}"

if ! command -v fzf &> /dev/null; then
    echo -e "${RED}Error: fzf is not installed${NC}"
    echo "Install with: brew install fzf"
    exit 1
fi
echo -e "${GREEN}✓ fzf found${NC}"

# Make scripts executable
echo -e "\n${YELLOW}Making scripts executable...${NC}"
chmod +x tmux-session-browser.sh tmux-popup.sh
echo -e "${GREEN}✓ Scripts made executable${NC}"

# Get installation directory
INSTALL_DIR="$(pwd)"
echo -e "\n${YELLOW}Installation directory: ${INSTALL_DIR}${NC}"

# Tmux configuration
TMUX_CONF="$HOME/.tmux.conf"
echo -e "\n${YELLOW}Configuring tmux shortcuts...${NC}"

# Check if tmux.conf exists
if [ ! -f "$TMUX_CONF" ]; then
    echo "# Tmux configuration" > "$TMUX_CONF"
    echo -e "${GREEN}✓ Created ~/.tmux.conf${NC}"
fi

# Add keybindings if not already present
if ! grep -q "tmux-session-browser" "$TMUX_CONF"; then
    cat >> "$TMUX_CONF" << EOF

# Tmux session browser shortcuts
bind-key s display-popup -E -w 90% -h 90% '$INSTALL_DIR/tmux-popup.sh'
bind-key S split-window -h -p 40 '$INSTALL_DIR/tmux-session-browser.sh'
bind-key C-s new-window -n "sessions" '$INSTALL_DIR/tmux-session-browser.sh'
EOF
    echo -e "${GREEN}✓ Added tmux keybindings to ~/.tmux.conf${NC}"
else
    echo -e "${YELLOW}⚠ Tmux keybindings already exist in ~/.tmux.conf${NC}"
fi

# Reload tmux if running
if tmux list-sessions &> /dev/null; then
    echo -e "\n${YELLOW}Reloading tmux configuration...${NC}"
    tmux source-file "$TMUX_CONF"
    echo -e "${GREEN}✓ Tmux configuration reloaded${NC}"
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo ""
echo "Usage:"
echo "  Standalone: ./tmux-session-browser.sh"
echo "  In tmux:"
echo "    prefix + s     - Popup overlay"
echo "    prefix + S     - Side pane"
echo "    prefix + Ctrl-s - New window"
echo ""
echo "Controls:"
echo "  Space  - Select/deselect sessions"
echo "  Enter  - Kill selected sessions"
echo "  q/Esc  - Quit"