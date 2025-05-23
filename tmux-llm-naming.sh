#!/bin/bash

# Tmux LLM-Powered Smart Naming
# Uses Ollama to analyze Claude Code session content for intelligent naming

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration
OLLAMA_MODEL="llama3.2:latest"  # Fast and good for text analysis
MAX_CONTENT_LENGTH=4000         # Limit content to avoid token limits
CACHE_DIR="$HOME/.cache/tmux-llm-naming"
CACHE_TTL=300                   # Cache results for 5 minutes

# Create cache directory
mkdir -p "$CACHE_DIR"

# Function to check if Ollama is available
check_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        echo -e "${RED}❌ Ollama not found. Please install: https://ollama.ai${NC}" >&2
        return 1
    fi
    
    if ! ollama list | grep -q "$OLLAMA_MODEL"; then
        echo -e "${YELLOW}⚠ Model $OLLAMA_MODEL not found. Installing...${NC}" >&2
        ollama pull "$OLLAMA_MODEL" || {
            echo -e "${RED}❌ Failed to install model $OLLAMA_MODEL${NC}" >&2
            return 1
        }
    fi
    
    return 0
}

# Function to extract Claude session content
extract_claude_content() {
    local session="$1"
    local window="$2"
    local pane="$3"
    
    # Get pane history (terminal output)
    local terminal_history=$(tmux capture-pane -t "$session:$window.$pane" -p -S -2000 2>/dev/null | tail -100)
    
    # Try to get current working directory and recent files
    local pane_path=$(tmux display -t "$session:$window.$pane" -p '#{pane_current_path}' 2>/dev/null)
    local recent_files=""
    
    if [ -n "$pane_path" ] && [ -d "$pane_path" ]; then
        # Get recently modified files that might be relevant
        recent_files=$(find "$pane_path" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.rs" -o -name "*.go" -o -name "*.md" -o -name "*.json" -o -name "*.toml" -o -name "*.yaml" \) -mtime -1 2>/dev/null | head -10)
        
        # Get project context
        local project_context=""
        if [ -f "$pane_path/package.json" ]; then
            project_context+="Package.json: $(head -10 "$pane_path/package.json" 2>/dev/null)\n"
        fi
        if [ -f "$pane_path/README.md" ]; then
            project_context+="README: $(head -5 "$pane_path/README.md" 2>/dev/null)\n"
        fi
        if [ -f "$pane_path/Cargo.toml" ]; then
            project_context+="Cargo.toml: $(head -10 "$pane_path/Cargo.toml" 2>/dev/null)\n"
        fi
    fi
    
    # Combine all context
    local content="TERMINAL OUTPUT:\n$terminal_history\n\nWORKING DIRECTORY: $pane_path\n"
    
    if [ -n "$project_context" ]; then
        content+="\nPROJECT CONTEXT:\n$project_context"
    fi
    
    if [ -n "$recent_files" ]; then
        content+="\nRECENT FILES:\n$recent_files\n"
    fi
    
    # Limit content length
    echo "$content" | head -c $MAX_CONTENT_LENGTH
}

# Function to get cache key
get_cache_key() {
    local session="$1"
    local window="$2"
    local pane="$3"
    echo "${session}_${window}_${pane}"
}

# Function to check cache
check_cache() {
    local cache_key="$1"
    local cache_file="$CACHE_DIR/$cache_key"
    
    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [ $cache_age -lt $CACHE_TTL ]; then
            cat "$cache_file"
            return 0
        fi
    fi
    
    return 1
}

# Function to save to cache
save_cache() {
    local cache_key="$1"
    local content="$2"
    local cache_file="$CACHE_DIR/$cache_key"
    
    echo "$content" > "$cache_file"
}

# Function to analyze content with Ollama
analyze_with_ollama() {
    local content="$1"
    
    if [ -z "$content" ]; then
        echo "unknown"
        return 1
    fi
    
    local prompt="You are analyzing terminal output and project context from a Claude Code AI assistant session. Based on the content below, generate a short, descriptive name (2-4 words max) that captures what the user and Claude are working on.

Focus on:
- Programming language or framework being used
- Type of task (debugging, building, refactoring, etc.)
- Project/feature being developed
- Specific technology or tool

Return ONLY the name, no explanations. Use format: action-project or tech-feature

Examples of good names:
- debug-auth-system
- build-react-app
- refactor-database
- fix-typescript-errors
- setup-docker-config
- analyze-performance

Content to analyze:
$content"

    local result=$(echo "$prompt" | ollama run "$OLLAMA_MODEL" 2>/dev/null | tr -d '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    # Clean up result - remove quotes, limit length, ensure safe characters
    result=$(echo "$result" | sed 's/["'\'']//g' | cut -c1-20 | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    
    if [ -n "$result" ] && [ "$result" != "unknown" ]; then
        echo "$result"
    else
        echo "claude-session"
    fi
}

# Function to get LLM-powered activity description
get_llm_activity_description() {
    local session="$1"
    local window="$2"
    local pane="$3"
    
    echo -e "${PURPLE}🧠 Analyzing Claude session with LLM...${NC}" >&2
    
    # Check cache first
    local cache_key=$(get_cache_key "$session" "$window" "$pane")
    local cached_result=$(check_cache "$cache_key")
    
    if [ $? -eq 0 ] && [ -n "$cached_result" ]; then
        echo -e "${GREEN}📱 Using cached analysis${NC}" >&2
        echo "$cached_result"
        return 0
    fi
    
    # Extract content from Claude session
    local content=$(extract_claude_content "$session" "$window" "$pane")
    
    if [ -z "$content" ]; then
        echo "claude-empty"
        return 1
    fi
    
    # Analyze with Ollama
    local analysis=$(analyze_with_ollama "$content")
    
    if [ -n "$analysis" ]; then
        # Cache the result
        save_cache "$cache_key" "$analysis"
        echo "♦$analysis"
    else
        echo "claude-unknown"
    fi
}

# Function to detect if this is a Claude session with LLM analysis
detect_claude_with_llm() {
    local session="$1"
    local window="$2"
    local pane="$3"
    
    # First check if it's actually a Claude session
    local pane_info=$(tmux display -t "$session:$window.$pane" -p '#{pane_pid}:#{pane_current_path}')
    local pane_pid=$(echo "$pane_info" | cut -d: -f1)
    
    # Check if Claude Code is running
    local all_pids=""
    if command -v pstree >/dev/null 2>&1; then
        all_pids=$(pstree -p "$pane_pid" 2>/dev/null | grep -o '([0-9]*)' | tr -d '()' 2>/dev/null || true)
    fi
    
    if [ -z "$all_pids" ]; then
        all_pids="$pane_pid $(pgrep -P "$pane_pid" 2>/dev/null || true)"
    fi
    
    for pid in $all_pids; do
        local cmd=$(ps -p "$pid" -o command= 2>/dev/null)
        if [[ "$cmd" == *"claude"* ]] && [[ "$cmd" != *"grep"* ]]; then
            # Found Claude - now analyze with LLM
            get_llm_activity_description "$session" "$window" "$pane"
            return 0
        fi
    done
    
    return 1
}

# Function for interactive mode
interactive_mode() {
    echo -e "${BLUE}🧠 LLM-Powered Claude Session Analyzer${NC}"
    echo "===================================="
    echo ""
    
    if ! check_ollama; then
        exit 1
    fi
    
    echo -e "${GREEN}✅ Ollama ready with model: $OLLAMA_MODEL${NC}"
    echo ""
    
    # Get all sessions
    local sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)
    
    if [ -z "$sessions" ]; then
        echo -e "${RED}❌ No tmux sessions found${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Analyzing Claude sessions...${NC}"
    echo ""
    
    local found_claude=false
    
    for session in $sessions; do
        local windows=$(tmux list-windows -t "$session" -F '#{window_index}' 2>/dev/null)
        
        for window in $windows; do
            local panes=$(tmux list-panes -t "$session:$window" -F '#{pane_index}' 2>/dev/null)
            
            for pane in $panes; do
                local result=$(detect_claude_with_llm "$session" "$window" "$pane" 2>/dev/null)
                
                if [ $? -eq 0 ] && [ -n "$result" ]; then
                    found_claude=true
                    echo -e "${GREEN}🎯 Found Claude session:${NC} $session:$window.$pane"
                    echo -e "${CYAN}   Analysis: $result${NC}"
                    echo ""
                fi
            done
        done
    done
    
    if [ "$found_claude" = false ]; then
        echo -e "${YELLOW}⚠ No active Claude sessions detected${NC}"
    fi
    
    echo -e "${BLUE}Analysis complete!${NC}"
}

# Function to integrate with existing smart naming
llm_enhanced_naming() {
    echo -e "${PURPLE}🧠 Running LLM-enhanced smart naming...${NC}"
    
    if ! check_ollama; then
        echo -e "${YELLOW}⚠ Falling back to basic smart naming${NC}"
        exec "$(dirname "$0")/tmux-smart-naming.sh" "${@}"
        return
    fi
    
    # Source the existing smart naming functions
    source "$(dirname "$0")/tmux-smart-naming.sh"
    
    # Override the detect_claude_activity function
    detect_claude_activity() {
        detect_claude_with_llm "$@"
    }
    
    # Run the smart naming with LLM enhancement
    case "${1:-rename}" in
        "dry-run")
            echo -e "${YELLOW}=== LLM-ENHANCED DRY RUN ===${NC}"
            sessions=$(tmux list-sessions -F '#{session_name}')
            for session in $sessions; do
                smart_rename_session "$session" true
                echo ""
            done
            ;;
        "rename")
            sessions=$(tmux list-sessions -F '#{session_name}')
            for session in $sessions; do
                smart_rename_session "$session" false
                echo ""
            done
            ;;
        *)
            interactive_mode
            ;;
    esac
}

# Main execution
case "${1:-interactive}" in
    "analyze"|"interactive")
        interactive_mode
        ;;
    "dry-run"|"rename")
        llm_enhanced_naming "$@"
        ;;
    "clear-cache")
        echo -e "${BLUE}🗑️ Clearing LLM analysis cache...${NC}"
        rm -rf "$CACHE_DIR"
        mkdir -p "$CACHE_DIR"
        echo -e "${GREEN}✅ Cache cleared${NC}"
        ;;
    "help"|"-h"|"--help")
        echo "Tmux LLM-Powered Smart Naming"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  analyze     - Analyze Claude sessions interactively (default)"
        echo "  dry-run     - Preview LLM-enhanced naming"
        echo "  rename      - Apply LLM-enhanced naming"
        echo "  clear-cache - Clear analysis cache"
        echo "  help        - Show this help"
        echo ""
        echo "Features:"
        echo "  • Uses Ollama to analyze Claude session content"
        echo "  • Generates intelligent names based on actual work"
        echo "  • Caches analysis for 5 minutes"
        echo "  • Falls back to basic naming if LLM unavailable"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac