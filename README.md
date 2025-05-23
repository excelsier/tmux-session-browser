# Tmux Session Browser

🚀 **Revolutionary tmux session management** with **LLM-powered content analysis**, **smart auto-naming**, **multi-select browsing**, and **device detection**. The first tmux tool that actually understands what your Claude Code sessions are working on!

## 🧠 NEW: LLM-Powered Analysis

**Finally know what each Claude session is doing!** Instead of generic names like "session1", get specific descriptions based on actual conversation content:

- `♦debug-react-auth` - Debugging React authentication 
- `♦build-api-endpoints` - Building REST API endpoints
- `♦fix-typescript-errors` - Fixing TypeScript issues
- `♦refactor-database` - Database refactoring work

**Powered by local Ollama** - private, fast, and incredibly accurate.

## Features

### 🔍 Smart Auto-Naming
- **♦ Claude Code detection** - automatically identifies and names Claude sessions with project context
- **📝 Activity recognition** - detects editors, git operations, package managers, and more
- **🏗️ Project identification** - recognizes Node.js, Rust, Python, Go projects from their files
- **🎯 Intelligent session naming** - prioritizes Claude projects for session-level naming

### 📋 Interactive Session Browser
- **Multi-select sessions** for batch operations using spacebar
- **Device detection** - shows if sessions are from Mac (💻) or iPad (📱)  
- **Terminal output preview** - see what each session was doing
- **Inactive sessions prioritized** - old/detached sessions shown first for easy cleanup
- **Tmux integration** - launch as popup, side pane, or new window
- **Smart sorting** - inactive sessions first, then by last activity

### ⚡ Ultimate Mode
- **Combined workflow** - smart rename followed by interactive browsing
- **One-click session management** - see meaningful names, then clean up efficiently
- **Perfect for Claude Code users** - easily identify which sessions are working on which projects

## Installation

1. Clone this repository:
```bash
git clone https://github.com/your-username/tmux-session-browser.git
cd tmux-session-browser
```

2. Run the installer:
```bash
./install.sh
```

Or manually configure:

3. Make scripts executable:
```bash
chmod +x *.sh
```

4. Add to your `~/.tmux.conf`:
```bash
# Ultimate tmux session management
bind-key u display-popup -E -w 90% -h 90% '/path/to/tmux-session-browser/tmux-ultimate.sh'

# Individual components
bind-key s display-popup -E -w 90% -h 90% '/path/to/tmux-session-browser/tmux-popup.sh'
bind-key S split-window -h -p 40 '/path/to/tmux-session-browser/tmux-session-browser.sh'
bind-key C-s new-window -n "sessions" '/path/to/tmux-session-browser/tmux-session-browser.sh'
```

5. Reload tmux configuration:
```bash
tmux source-file ~/.tmux.conf
```

## 🔄 NEW: Automatic LLM Renaming

Keep your sessions automatically named based on their content! Multiple options available:

### Quick Setup
```bash
./setup-auto-rename.sh
```

Choose from:
- **Daemon** - Background service, renames every 5 minutes
- **Hooks** - Automatic renaming on session switches
- **Cron** - Scheduled intervals
- **Manual** - On-demand with keybindings

### Daemon Control
```bash
# Start auto-renaming daemon
./tmux-auto-llm-daemon.sh start

# Check status
./tmux-auto-llm-daemon.sh status

# Stop daemon
./tmux-auto-llm-daemon.sh stop

# Custom interval (10 minutes)
TMUX_LLM_INTERVAL=600 ./tmux-auto-llm-daemon.sh start
```

## Usage

### 🧠 LLM Ultimate Mode (Revolutionary!)
```bash
./tmux-ultimate-llm.sh
# or within tmux: prefix + i (changed from U)
```
**AI-powered session analysis** + smart renaming + browsing. See exactly what each Claude session is working on!

### 🚀 Basic Ultimate Mode
```bash
./tmux-ultimate.sh
# or within tmux: prefix + u
```
Smart renaming + session browsing combined (no LLM required).

### Individual Tools

#### LLM-Powered Naming
```bash
./tmux-llm-naming.sh analyze    # Analyze Claude sessions with AI
./tmux-llm-naming.sh dry-run    # Preview LLM-enhanced naming  
./tmux-llm-naming.sh rename     # Apply LLM-powered names
```

#### Basic Smart Naming
```bash
./tmux-smart-naming.sh          # Pattern-based naming
./tmux-smart-naming.sh dry-run  # Preview changes
./tmux-smart-naming.sh watch    # Auto-rename every 30s
```

#### Session Browser
```bash
./tmux-session-browser.sh       # Standalone browser
```

#### Within tmux
- `prefix + i` - **LLM Ultimate mode** (revolutionary!)
- `prefix + u` - **Basic Ultimate mode** (recommended)
- `prefix + s` - Popup overlay (90% screen)
- `prefix + S` - Side pane (40% width)  
- `prefix + Ctrl-s` - New window
- `prefix + b` - **Toggle sidebar** with LLM summaries
- `prefix + R` - **Quick LLM rename** all sessions

### Controls
- **Navigate**: Arrow keys or `j`/`k`
- **Select multiple**: Spacebar to toggle selection
- **Confirm**: Enter to kill selected sessions
- **Quit**: `q` or Escape

## LLM vs Basic Naming Examples

### Before (Generic)
```
Sessions: work, dev, testing, 20
Windows: zsh, code, git, files
```

### After Basic Smart Naming
```
Sessions: ♦bookeper-accounting, ♦my-app, 🏠home
Windows: ♦bookeper-accounting, 🔀my-app, 📦frontend, 🏠home
```

### After LLM-Powered Naming 🧠
```
Sessions: ♦debug-react-auth, ♦build-user-api, ♦fix-db-migration
Windows: ♦debug-react-auth, 🔀git-rebase, 📦npm-install
```

**The LLM difference:** Instead of just knowing it's a "bookeper-accounting" project, you know you're specifically "debugging React authentication issues"!

**Legend:**
- ♦ = Claude Code sessions (with specific task context via LLM)
- 📝 = Editors, 🔀 = Git, 📦 = Package managers
- 🐍 = Python, 🟢 = Node.js, 🦀 = Rust, 🐹 = Go  
- 🏠 = Home directory/shell sessions

## Requirements

### Core
- **tmux** - Terminal multiplexer
- **fzf** - Fuzzy finder for interactive browsing
- **Basic Unix utilities** (awk, sed, sort)

### For LLM Features  
- **Ollama** - Local LLM runtime ([ollama.ai](https://ollama.ai))
- **llama3.2 model** - Auto-installed on first use
- **2GB+ RAM** recommended for LLM analysis

### Optional
- **jq** - Better JSON parsing (graceful fallback if missing)

## Device Detection

The browser detects connection sources:
- 💻 Mac connections (wide terminals)
- 📱 iPad connections (narrow terminals)  
- 💻📱 Multiple device connections

Detection is based on terminal dimensions and client count.

## License

MIT License - see LICENSE file for details

## 🧠 LLM Features Deep Dive

The LLM-powered analysis is a game-changer for Claude Code users. See **[README-LLM.md](README-LLM.md)** for comprehensive documentation including:

- How content analysis works
- Performance and caching details  
- Customization options
- Comparison with basic naming
- Best practices for Claude Code workflows

**Quick start with LLM:**
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Test LLM analysis  
./tmux-llm-naming.sh analyze

# Use LLM Ultimate mode
./tmux-ultimate-llm.sh
```

## Contributing

Pull requests welcome! Please ensure scripts are tested with various tmux configurations.

**Areas for contribution:**
- Additional LLM models support
- Better project type detection
- Enhanced terminal content extraction  
- Performance optimizations