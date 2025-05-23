# Tmux Session Browser

An interactive tmux session manager with multi-select capabilities, device detection, and terminal output preview.

## Features

- **Multi-select sessions** for batch operations using spacebar
- **Device detection** - shows if sessions are from Mac (💻) or iPad (📱)  
- **Terminal output preview** - see what each session was doing
- **Inactive sessions prioritized** - old/detached sessions shown first for easy cleanup
- **Tmux integration** - launch as popup, side pane, or new window
- **Smart sorting** - inactive sessions first, then by last activity

## Installation

1. Clone this repository:
```bash
git clone https://github.com/your-username/tmux-session-browser.git
cd tmux-session-browser
```

2. Make scripts executable:
```bash
chmod +x tmux-session-browser.sh tmux-popup.sh
```

3. Add to your `~/.tmux.conf`:
```bash
# Tmux session browser shortcuts
bind-key s display-popup -E -w 90% -h 90% '/path/to/tmux-session-browser/tmux-popup.sh'
bind-key S split-window -h -p 40 '/path/to/tmux-session-browser/tmux-session-browser.sh'
bind-key C-s new-window -n "sessions" '/path/to/tmux-session-browser/tmux-session-browser.sh'
```

4. Reload tmux configuration:
```bash
tmux source-file ~/.tmux.conf
```

## Usage

### Standalone
```bash
./tmux-session-browser.sh
```

### Within tmux
- `prefix + s` - Popup overlay (90% screen)
- `prefix + S` - Side pane (40% width)  
- `prefix + Ctrl-s` - New window

### Controls
- **Navigate**: Arrow keys or `j`/`k`
- **Select multiple**: Spacebar to toggle selection
- **Confirm**: Enter to kill selected sessions
- **Quit**: `q` or Escape

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