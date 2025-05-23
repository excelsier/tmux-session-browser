# Tmux Session Browser

An intelligent tmux session management suite with **smart auto-naming**, **multi-select browsing**, **device detection**, and **terminal output preview**. The ultimate solution for organizing and managing tmux sessions, especially with **Claude Code integration**.

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

## Usage

### 🚀 Ultimate Mode (Recommended)
```bash
./tmux-ultimate.sh
# or within tmux: prefix + u
```
Interactive menu with smart renaming + session browsing combined.

### Individual Tools

#### Smart Auto-Naming
```bash
./tmux-smart-naming.sh          # Rename all sessions/windows
./tmux-smart-naming.sh dry-run  # Preview changes
./tmux-smart-naming.sh watch    # Auto-rename every 30s
```

#### Session Browser
```bash
./tmux-session-browser.sh       # Standalone browser
```

#### Within tmux
- `prefix + u` - **Ultimate mode** (recommended)
- `prefix + s` - Popup overlay (90% screen)
- `prefix + S` - Side pane (40% width)  
- `prefix + Ctrl-s` - New window

### Controls
- **Navigate**: Arrow keys or `j`/`k`
- **Select multiple**: Spacebar to toggle selection
- **Confirm**: Enter to kill selected sessions
- **Quit**: `q` or Escape

## Smart Naming Examples

### Before
```
Sessions: work, dev, testing, 20
Windows: zsh, code, git, files
```

### After Smart Renaming
```
Sessions: ♦bookeper-accounting, ♦my-app, 🏠home
Windows: ♦bookeper-accounting, 🔀my-app, 📦frontend, 🏠home
```

**Legend:**
- ♦ = Claude Code sessions
- 📝 = Editors (vim, nvim, etc.)
- 🔀 = Git operations  
- 📦 = Package managers (npm, yarn)
- 🐍 = Python, 🟢 = Node.js, 🦀 = Rust, 🐹 = Go
- 🏠 = Home directory/shell sessions

## Requirements

- tmux
- fzf (fuzzy finder)
- Basic Unix utilities (awk, sed, sort)

## Device Detection

The browser detects connection sources:
- 💻 Mac connections (wide terminals)
- 📱 iPad connections (narrow terminals)  
- 💻📱 Multiple device connections

Detection is based on terminal dimensions and client count.

## License

MIT License - see LICENSE file for details

## Contributing

Pull requests welcome! Please ensure scripts are tested with various tmux configurations.