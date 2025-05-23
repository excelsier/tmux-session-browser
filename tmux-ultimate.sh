#!/bin/bash

# Tmux Ultimate - Combined smart naming and session browser
# The ultimate tmux session management experience

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}                    🚀 TMUX ULTIMATE SESSION MANAGER 🚀${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

show_menu() {
    echo -e "${CYAN}Choose your action:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC} 🔍 ${YELLOW}Smart Rename${NC} - Auto-name sessions/windows based on activity"
    echo -e "  ${GREEN}2${NC} 📋 ${YELLOW}Browse Sessions${NC} - Interactive session browser with multi-select"
    echo -e "  ${GREEN}3${NC} ⚡ ${YELLOW}Ultimate Mode${NC} - Smart rename THEN browse (recommended)"
    echo -e "  ${GREEN}4${NC} 👀 ${YELLOW}Preview Renames${NC} - See what would be renamed (dry run)"
    echo -e "  ${GREEN}5${NC} 🔄 ${YELLOW}Auto-Watch${NC} - Continuously monitor and rename every 30s"
    echo ""
    echo -e "  ${GREEN}h${NC} 📖 ${YELLOW}Help${NC} - Show detailed usage information"
    echo -e "  ${GREEN}q${NC} 🚪 ${YELLOW}Quit${NC}"
    echo ""
}

show_help() {
    echo -e "${BLUE}=== TMUX ULTIMATE HELP ===${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Smart Rename Features:${NC}"
    echo "  • ♦ Claude Code sessions with project names"
    echo "  • 📝 Editor sessions (vim, nvim, nano, emacs)"
    echo "  • 🔀 Git operations"
    echo "  • 📦 Package managers (npm, yarn, pnpm)"
    echo "  • 🐍 Python, 🟢 Node.js, 🦀 Rust, 🐹 Go projects"
    echo "  • 🏠 Home directory fallback"
    echo ""
    echo -e "${YELLOW}📋 Session Browser Features:${NC}"
    echo "  • Multi-select sessions with spacebar"
    echo "  • Device detection (💻 Mac, 📱 iPad)"
    echo "  • Terminal output preview"
    echo "  • Inactive sessions prioritized for cleanup"
    echo ""
    echo -e "${YELLOW}⚡ Ultimate Mode:${NC}"
    echo "  Combines smart renaming with interactive browsing for the"
    echo "  best tmux experience - see exactly what each session is"
    echo "  doing and clean up with confidence!"
    echo ""
    echo -e "${YELLOW}🎯 Claude Code Integration:${NC}"
    echo "  Automatically detects Claude Code sessions and names them"
    echo "  with ♦ symbol plus the project you're working on."
    echo ""
    echo -e "${YELLOW}Tmux Integration:${NC}"
    echo "  Add to ~/.tmux.conf for instant access:"
    echo "  ${CYAN}bind-key u display-popup -E -w 90% -h 90% '$SCRIPT_DIR/tmux-ultimate.sh'${NC}"
    echo ""
}

run_smart_rename() {
    echo -e "${BLUE}🔍 Running Smart Rename...${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/tmux-smart-naming.sh" ]; then
        "$SCRIPT_DIR/tmux-smart-naming.sh" rename
        echo ""
        echo -e "${GREEN}✅ Smart rename completed!${NC}"
    else
        echo -e "${RED}❌ Error: tmux-smart-naming.sh not found${NC}"
        exit 1
    fi
}

run_browser() {
    echo -e "${BLUE}📋 Launching Session Browser...${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/tmux-session-browser.sh" ]; then
        "$SCRIPT_DIR/tmux-session-browser.sh"
    else
        echo -e "${RED}❌ Error: tmux-session-browser.sh not found${NC}"
        exit 1
    fi
}

run_ultimate() {
    echo -e "${BLUE}⚡ ULTIMATE MODE ACTIVATED!${NC}"
    echo ""
    run_smart_rename
    echo ""
    echo -e "${CYAN}Now launching session browser with smart names...${NC}"
    sleep 1
    run_browser
}

run_dry_run() {
    echo -e "${BLUE}👀 Preview Mode - Showing what would be renamed:${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/tmux-smart-naming.sh" ]; then
        "$SCRIPT_DIR/tmux-smart-naming.sh" dry-run
    else
        echo -e "${RED}❌ Error: tmux-smart-naming.sh not found${NC}"
        exit 1
    fi
}

run_watch() {
    echo -e "${BLUE}🔄 Starting Auto-Watch Mode...${NC}"
    echo -e "${YELLOW}Will check and rename every 30 seconds. Press Ctrl+C to stop.${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/tmux-smart-naming.sh" ]; then
        "$SCRIPT_DIR/tmux-smart-naming.sh" watch
    else
        echo -e "${RED}❌ Error: tmux-smart-naming.sh not found${NC}"
        exit 1
    fi
}

# Main interactive loop
main() {
    # If run with arguments, execute directly
    case "${1:-}" in
        "rename"|"smart")
            run_smart_rename
            exit 0
            ;;
        "browse"|"browser")
            run_browser
            exit 0
            ;;
        "ultimate"|"all")
            run_ultimate
            exit 0
            ;;
        "dry-run"|"preview")
            run_dry_run
            exit 0
            ;;
        "watch"|"auto")
            run_watch
            exit 0
            ;;
        "help"|"-h"|"--help")
            show_help
            exit 0
            ;;
    esac
    
    # Interactive mode
    while true; do
        clear
        print_header
        show_menu
        
        read -p "$(echo -e "${CYAN}Enter your choice:${NC} ")" choice
        echo ""
        
        case "$choice" in
            "1")
                run_smart_rename
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "2")
                run_browser
                break
                ;;
            "3")
                run_ultimate
                break
                ;;
            "4")
                run_dry_run
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "5")
                run_watch
                break
                ;;
            "h"|"help")
                show_help
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "q"|"quit"|"exit")
                echo -e "${GREEN}👋 Thanks for using Tmux Ultimate!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check dependencies
check_dependencies() {
    local missing=()
    
    command -v tmux >/dev/null 2>&1 || missing+=("tmux")
    command -v fzf >/dev/null 2>&1 || missing+=("fzf")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing dependencies: ${missing[*]}${NC}"
        echo "Please install them first."
        exit 1
    fi
}

# Startup
check_dependencies
main "$@"