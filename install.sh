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

# Check for Ollama (optional for AI features)
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓ Ollama found - AI features available${NC}"
    AI_AVAILABLE=1
else
    echo -e "${YELLOW}⚠ Ollama not found - AI features will be limited${NC}"
    echo -e "  Install with: curl -fsSL https://ollama.ai/install.sh | sh"
    AI_AVAILABLE=0
fi

# Make scripts executable
echo -e "\n${YELLOW}Making scripts executable...${NC}"
chmod +x *.sh
echo -e "${GREEN}✓ All scripts made executable${NC}"

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

# Ultimate mode - smart naming + browsing
bind-key u display-popup -E -w 90% -h 90% '$INSTALL_DIR/tmux-ultimate.sh'

# AI-powered features (if Ollama available)
bind-key i display-popup -E -w 90% -h 90% '$INSTALL_DIR/tmux-ultimate-llm.sh'
bind-key R run-shell '$INSTALL_DIR/tmux-auto-llm-simple.sh'

# Live sidebar
bind-key b run-shell '$INSTALL_DIR/tmux-sidebar-live.sh toggle'
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

# AI Auto-rename setup (optional)
if [ "$AI_AVAILABLE" -eq 1 ]; then
    echo -e "\n${YELLOW}AI Auto-rename Setup${NC}"
    echo "Would you like to enable automatic AI-powered session renaming?"
    echo ""
    echo "Options:"
    echo "  1) Daemon - Background service (renames every 5 minutes)"
    echo "  2) Hooks - Rename on session switches"
    echo "  3) Manual - Use keybindings only (C-a R)"
    echo "  4) Skip - Configure later"
    echo ""
    read -p "Select option (1-4): " ai_choice
    
    case $ai_choice in
        1)
            echo -e "\n${GREEN}Setting up auto-rename daemon...${NC}"
            # Add to shell profile
            SHELL_PROFILE="$HOME/.zshrc"
            if [ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.zshrc" ]; then
                SHELL_PROFILE="$HOME/.bashrc"
            fi
            
            if ! grep -q "tmux-auto-llm-daemon" "$SHELL_PROFILE"; then
                echo "" >> "$SHELL_PROFILE"
                echo "# Auto-start tmux AI rename daemon" >> "$SHELL_PROFILE"
                echo "if command -v tmux &> /dev/null && [ -z \"\$TMUX\" ]; then" >> "$SHELL_PROFILE"
                echo "    $INSTALL_DIR/tmux-auto-llm-daemon.sh start &> /dev/null" >> "$SHELL_PROFILE"
                echo "fi" >> "$SHELL_PROFILE"
                echo -e "${GREEN}✓ Added daemon auto-start to $SHELL_PROFILE${NC}"
            fi
            
            # Start daemon now
            "$INSTALL_DIR/tmux-auto-llm-daemon.sh" start
            ;;
            
        2)
            echo -e "\n${GREEN}Setting up tmux hooks...${NC}"
            if ! grep -q "client-session-changed.*auto-llm" "$TMUX_CONF"; then
                cat >> "$TMUX_CONF" << EOF

# AI Auto-rename hooks
set-hook -g client-session-changed 'run-shell -b "sleep 2 && $INSTALL_DIR/tmux-auto-llm-simple.sh &"'
set-hook -g client-activity 'run-shell -b "( sleep 300 && $INSTALL_DIR/tmux-auto-llm-simple.sh ) &"'
EOF
                echo -e "${GREEN}✓ Added auto-rename hooks to ~/.tmux.conf${NC}"
            fi
            ;;
            
        3)
            echo -e "${GREEN}✓ Manual mode selected - use C-a R to rename sessions${NC}"
            ;;
            
        4)
            echo -e "${YELLOW}Skipping auto-rename setup. Run ./setup-auto-rename.sh later.${NC}"
            ;;
    esac
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo ""
echo "Usage:"
echo "  Standalone: ./tmux-session-browser.sh"
echo "  In tmux:"
echo "    prefix + s     - Popup overlay"
echo "    prefix + S     - Side pane"
echo "    prefix + u     - Ultimate mode (smart naming + browse)"
if [ "$AI_AVAILABLE" -eq 1 ]; then
    echo "    prefix + i     - AI Ultimate mode (LLM analysis + browse)"
    echo "    prefix + R     - Quick AI rename all sessions"
fi
echo "    prefix + b     - Toggle sidebar"
echo "    prefix + Ctrl-s - New window"
echo ""
echo "Controls:"
echo "  Space  - Select/deselect sessions"
echo "  Enter  - Kill selected sessions"
echo "  q/Esc  - Quit"

if [ "$AI_AVAILABLE" -eq 1 ]; then
    echo ""
    echo "AI Features:"
    echo "  - LLM-powered session analysis"
    echo "  - Automatic content-based renaming"
    echo "  - Live sidebar with AI summaries"
    if [ "$ai_choice" -eq 1 ]; then
        echo "  - Auto-rename daemon is running"
    fi
fi