#!/bin/bash

# Tmux Ultimate LLM - The most advanced tmux session management
# Combines smart naming, LLM content analysis, and interactive browsing

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}                🧠 TMUX ULTIMATE LLM SESSION MANAGER 🧠${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}         Intelligent session management powered by local LLM${NC}"
    echo ""
}

show_menu() {
    echo -e "${CYAN}Choose your LLM-powered action:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC} 🧠 ${YELLOW}LLM Smart Rename${NC} - AI-analyze Claude sessions for precise naming"
    echo -e "  ${GREEN}2${NC} 🔍 ${YELLOW}Basic Smart Rename${NC} - Pattern-based naming (faster)"
    echo -e "  ${GREEN}3${NC} 📋 ${YELLOW}Browse Sessions${NC} - Interactive session browser"
    echo -e "  ${GREEN}4${NC} ⚡ ${YELLOW}Ultimate LLM Mode${NC} - LLM rename THEN browse (recommended)"
    echo -e "  ${GREEN}5${NC} 🔄 ${YELLOW}Ultimate Basic Mode${NC} - Basic rename THEN browse"
    echo -e "  ${GREEN}6${NC} 👁️ ${YELLOW}Analyze Claude Sessions${NC} - See what Claude is working on"
    echo -e "  ${GREEN}7${NC} 👀 ${YELLOW}Preview LLM Naming${NC} - See LLM analysis without changes"
    echo -e "  ${GREEN}8${NC} 🗑️ ${YELLOW}Clear LLM Cache${NC} - Reset analysis cache"
    echo -e "  ${GREEN}9${NC} 🔄 ${YELLOW}Fix Terminal Titles${NC} - Sync terminal tabs with session names"
    echo ""
    echo -e "  ${GREEN}h${NC} 📖 ${YELLOW}Help${NC} - Show detailed information"
    echo -e "  ${GREEN}q${NC} 🚪 ${YELLOW}Quit${NC}"
    echo ""
}

show_help() {
    echo -e "${PURPLE}=== TMUX ULTIMATE LLM HELP ===${NC}"
    echo ""
    echo -e "${YELLOW}🧠 LLM-Powered Features:${NC}"
    echo "  • Analyzes actual Claude Code conversation content"
    echo "  • Extracts project context from working directories"
    echo "  • Generates precise names like 'debug-react-auth' or 'build-api-endpoints'"
    echo "  • Uses local Ollama models (private, fast)"
    echo "  • 5-minute smart caching to avoid re-analysis"
    echo ""
    echo -e "${YELLOW}🔍 Smart Detection Includes:${NC}"
    echo "  • Current programming task (debugging, building, refactoring)"
    echo "  • Technology stack (React, API, TypeScript, etc.)"
    echo "  • Specific feature being worked on"
    echo "  • Error patterns and solutions being discussed"
    echo ""
    echo -e "${YELLOW}⚡ Ultimate LLM Mode Workflow:${NC}"
    echo "  1. 🧠 AI analyzes all Claude sessions for precise context"
    echo "  2. 🏷️ Renames sessions/windows with specific task descriptions"
    echo "  3. 📋 Opens interactive browser with meaningful names"
    echo "  4. 🎯 Kill old sessions with confidence"
    echo ""
    echo -e "${YELLOW}📋 Session Browser Features:${NC}"
    echo "  • Multi-select with spacebar"
    echo "  • Device detection (💻 Mac, 📱 iPad)"
    echo "  • Terminal output preview"
    echo "  • LLM-generated names for easy identification"
    echo ""
    echo -e "${YELLOW}🔧 Requirements:${NC}"
    echo "  • Ollama installed (https://ollama.ai)"
    echo "  • Model llama3.2:latest (auto-installed if missing)"
    echo "  • fzf for session browsing"
    echo ""
    echo -e "${YELLOW}🎯 Perfect for Claude Code Users:${NC}"
    echo "  See exactly what each Claude session is working on with"
    echo "  AI-generated descriptions instead of generic names!"
    echo ""
}

check_llm_availability() {
    if command -v ollama >/dev/null 2>&1; then
        if ollama list | grep -q "llama3.2:latest"; then
            return 0
        else
            echo -e "${YELLOW}⚠ Installing llama3.2 model for LLM analysis...${NC}"
            ollama pull llama3.2:latest && return 0 || return 1
        fi
    else
        return 1
    fi
}

run_llm_smart_rename() {
    echo -e "${PURPLE}🧠 Running LLM-Powered Smart Rename...${NC}"
    echo ""
    
    if ! check_llm_availability; then
        echo -e "${RED}❌ LLM not available. Install Ollama and llama3.2 model.${NC}"
        echo -e "${YELLOW}Falling back to basic smart rename...${NC}"
        run_basic_smart_rename
        return
    fi
    
    if [ -f "$SCRIPT_DIR/tmux-llm-naming.sh" ]; then
        "$SCRIPT_DIR/tmux-llm-naming.sh" rename
        echo ""
        echo -e "${GREEN}✅ LLM-powered rename completed!${NC}"
    else
        echo -e "${RED}❌ Error: tmux-llm-naming.sh not found${NC}"
        exit 1
    fi
}

run_basic_smart_rename() {
    echo -e "${BLUE}🔍 Running Basic Smart Rename...${NC}"
    echo ""
    if [ -f "$SCRIPT_DIR/tmux-smart-naming.sh" ]; then
        "$SCRIPT_DIR/tmux-smart-naming.sh" rename
        echo ""
        echo -e "${GREEN}✅ Basic smart rename completed!${NC}"
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

run_ultimate_llm() {
    echo -e "${PURPLE}⚡ ULTIMATE LLM MODE ACTIVATED!${NC}"
    echo ""
    run_llm_smart_rename
    echo ""
    echo -e "${CYAN}Now launching session browser with LLM-generated names...${NC}"
    sleep 1
    run_browser
}

run_ultimate_basic() {
    echo -e "${BLUE}⚡ ULTIMATE BASIC MODE ACTIVATED!${NC}"
    echo ""
    run_basic_smart_rename
    echo ""
    echo -e "${CYAN}Now launching session browser with smart names...${NC}"
    sleep 1
    run_browser
}

analyze_claude_sessions() {
    echo -e "${PURPLE}🧠 Analyzing Claude Sessions with LLM...${NC}"
    echo ""
    
    if ! check_llm_availability; then
        echo -e "${RED}❌ LLM not available. Install Ollama and llama3.2 model.${NC}"
        return 1
    fi
    
    if [ -f "$SCRIPT_DIR/tmux-llm-naming.sh" ]; then
        "$SCRIPT_DIR/tmux-llm-naming.sh" analyze
    else
        echo -e "${RED}❌ Error: tmux-llm-naming.sh not found${NC}"
        exit 1
    fi
}

preview_llm_naming() {
    echo -e "${PURPLE}👀 LLM Preview Mode...${NC}"
    echo ""
    
    if ! check_llm_availability; then
        echo -e "${RED}❌ LLM not available. Install Ollama and llama3.2 model.${NC}"
        echo -e "${YELLOW}Showing basic smart naming preview instead...${NC}"
        if [ -f "$SCRIPT_DIR/tmux-smart-naming.sh" ]; then
            "$SCRIPT_DIR/tmux-smart-naming.sh" dry-run
        fi
        return
    fi
    
    if [ -f "$SCRIPT_DIR/tmux-llm-naming.sh" ]; then
        "$SCRIPT_DIR/tmux-llm-naming.sh" dry-run
    else
        echo -e "${RED}❌ Error: tmux-llm-naming.sh not found${NC}"
        exit 1
    fi
}

clear_llm_cache() {
    echo -e "${BLUE}🗑️ Clearing LLM analysis cache...${NC}"
    if [ -f "$SCRIPT_DIR/tmux-llm-naming.sh" ]; then
        "$SCRIPT_DIR/tmux-llm-naming.sh" clear-cache
    else
        echo -e "${RED}❌ Error: tmux-llm-naming.sh not found${NC}"
        exit 1
    fi
}

fix_terminal_titles() {
    echo -e "${BLUE}🔄 Fixing Terminal Titles...${NC}"
    if [ -f "$SCRIPT_DIR/fix-terminal-titles.sh" ]; then
        "$SCRIPT_DIR/fix-terminal-titles.sh"
    else
        echo -e "${RED}❌ Error: fix-terminal-titles.sh not found${NC}"
        exit 1
    fi
}

# Main interactive loop
main() {
    # If run with arguments, execute directly
    case "${1:-}" in
        "llm"|"llm-rename")
            run_llm_smart_rename
            exit 0
            ;;
        "basic"|"basic-rename")
            run_basic_smart_rename
            exit 0
            ;;
        "browse"|"browser")
            run_browser
            exit 0
            ;;
        "ultimate-llm"|"llm-ultimate")
            run_ultimate_llm
            exit 0
            ;;
        "ultimate-basic"|"ultimate")
            run_ultimate_basic
            exit 0
            ;;
        "analyze")
            analyze_claude_sessions
            exit 0
            ;;
        "preview"|"dry-run")
            preview_llm_naming
            exit 0
            ;;
        "clear-cache")
            clear_llm_cache
            exit 0
            ;;
        "fix-titles"|"fix-terminal-titles")
            fix_terminal_titles
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
                run_llm_smart_rename
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "2")
                run_basic_smart_rename
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "3")
                run_browser
                break
                ;;
            "4")
                run_ultimate_llm
                break
                ;;
            "5")
                run_ultimate_basic
                break
                ;;
            "6")
                analyze_claude_sessions
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "7")
                preview_llm_naming
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "8")
                clear_llm_cache
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "9")
                fix_terminal_titles
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "h"|"help")
                show_help
                echo ""
                read -p "Press Enter to continue..."
                ;;
            "q"|"quit"|"exit")
                echo -e "${GREEN}👋 Thanks for using Tmux Ultimate LLM!${NC}"
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
    
    # Check LLM availability (non-fatal)
    if ! check_llm_availability; then
        echo -e "${YELLOW}⚠ LLM features require Ollama with llama3.2 model${NC}"
        echo -e "${YELLOW}  Install from: https://ollama.ai${NC}"
        echo -e "${YELLOW}  Basic features will still work${NC}"
        echo ""
        sleep 2
    fi
}

# Startup
check_dependencies
main "$@"