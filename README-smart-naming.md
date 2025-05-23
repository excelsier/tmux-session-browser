# Tmux Smart Naming

Intelligent auto-naming for tmux sessions and windows based on detected activity and project context.

## Features

### 🔍 Activity Detection
- **♦ Claude Code** sessions with project identification
- **📝 Editors** (vim, nvim, nano, emacs)  
- **🔀 Git** operations
- **📦 Package managers** (npm, yarn, pnpm)
- **🐍 Python** scripts
- **🟢 Node.js** applications
- **🦀 Rust** (Cargo)
- **🐹 Go** applications
- **🏠 Home** directory fallback

### 🏗️ Project Type Detection
- **Node.js** projects (package.json → project name)
- **Rust** projects (Cargo.toml → project name)
- **Python** projects (pyproject.toml, setup.py, requirements.txt)
- **Go** projects (go.mod → module name)
- **Git** repositories (repo directory name)

### 🎯 Smart Session Naming
- **Claude projects** take priority for session names
- **Most common project** across windows determines session name
- **Fallback** to original name if no clear project detected

## Usage

### Dry Run (Preview Changes)
```bash
./tmux-smart-naming.sh dry-run
```
Shows what would be renamed without making changes.

### One-Time Rename
```bash
./tmux-smart-naming.sh rename
# or simply
./tmux-smart-naming.sh
```

### Auto-Watch Mode
```bash
./tmux-smart-naming.sh watch
```
Continuously monitors and renames every 30 seconds. Press Ctrl+C to stop.

## Examples

### Before Renaming
```
Sessions: work, dev, testing
Windows: zsh, code, git, files
```

### After Smart Renaming  
```
Sessions: ♦bookeper-accounting, ♦my-app, 🏠home
Windows: ♦bookeper-accounting, 🔀my-app, 📦frontend, 🏠home
```

## Integration with Session Browser

The smart naming can be combined with the session browser for the ultimate tmux experience:

1. **Auto-rename** sessions to see project context
2. **Browse sessions** with meaningful names  
3. **Kill old sessions** easily identified by their activity

### Quick Integration
```bash
# Auto-rename all sessions
./tmux-smart-naming.sh

# Then browse with context
./tmux-session-browser.sh
```

## Claude Code Detection

The system detects Claude Code sessions by:
1. **Process inspection** - Looking for `claude` in command line
2. **Working directory** - Detecting project type from current path
3. **Priority naming** - Claude sessions get ♦ prefix and project name

This makes it easy to identify which sessions are actively working on which projects with Claude Code.

## Customization

Edit the `tmux-smart-naming.sh` script to:
- Add new project types in `detect_project_type()`
- Add new activity patterns in `get_activity_description()`
- Modify emoji/symbols for different activities
- Adjust session naming priority logic