# Tmux LLM-Powered Session Naming

Revolutionary tmux session management using **local LLM analysis** to understand what Claude Code is actually working on and generate precise, meaningful session names.

## 🧠 What Makes This Special

Instead of generic names like "session1" or even "bookeper-accounting", the LLM analyzer reads the actual conversation content and generates specific descriptions like:

- `♦debug-react-auth` - Debugging React authentication issues
- `♦build-api-endpoints` - Building REST API endpoints  
- `♦fix-typescript-errors` - Fixing TypeScript compilation errors
- `♦refactor-database-schema` - Database schema refactoring
- `♦optimize-performance` - Performance optimization work

## 🎯 Perfect for Claude Code Users

### The Problem
When you have multiple Claude Code sessions open, they all look the same:
```
Sessions: work, dev, accounting, session1
Windows: zsh, code, git, files
```

**Which one was working on the React bug? Which one had the API discussion?**

### The Solution
LLM-powered analysis gives you crystal clear context:
```
Sessions: ♦debug-react-auth, ♦build-user-api, ♦fix-db-migration
Windows: ♦debug-react-auth, 🔀git-rebase, 📦npm-install
```

**Now you know exactly what each session is doing!**

## 🏗️ How It Works

### 1. Content Extraction
- **Terminal output** - Last 100 lines of Claude conversation
- **Working directory** - Current project context
- **Recent files** - Recently modified files in the project
- **Project metadata** - package.json, README.md, Cargo.toml, etc.

### 2. LLM Analysis
- **Local Ollama** model (llama3.2) analyzes the content
- **Privacy-first** - all analysis happens locally
- **Smart caching** - results cached for 5 minutes
- **Fallback** - uses basic naming if LLM unavailable

### 3. Intelligent Naming
- **Task-focused** - "debug", "build", "refactor", "fix"
- **Tech-specific** - "react", "api", "typescript", "database"
- **Concise** - 2-4 words maximum
- **Consistent** - follows kebab-case format

## 🚀 Usage

### Quick Start
```bash
# Analyze what Claude is working on
./tmux-llm-naming.sh analyze

# Preview LLM-enhanced naming
./tmux-llm-naming.sh dry-run

# Apply LLM-powered smart naming
./tmux-llm-naming.sh rename
```

### Ultimate LLM Mode
```bash
# Interactive menu with all LLM features
./tmux-ultimate-llm.sh

# Or direct commands:
./tmux-ultimate-llm.sh ultimate-llm    # LLM rename + browse
./tmux-ultimate-llm.sh analyze         # Just analyze
./tmux-ultimate-llm.sh preview         # Preview changes
```

### Tmux Integration
Add to your `~/.tmux.conf`:
```bash
# LLM-powered session management
bind-key U display-popup -E -w 90% -h 90% '/path/to/tmux-ultimate-llm.sh'

# Or mix and match:
bind-key u display-popup -E -w 90% -h 90% '/path/to/tmux-ultimate-llm.sh ultimate-llm'
bind-key a display-popup -E -w 90% -h 90% '/path/to/tmux-ultimate-llm.sh analyze'
```

## 📊 Comparison

| Approach | Example Names | Specificity | Speed | Requirements |
|----------|---------------|-------------|-------|--------------|
| **Manual** | `work`, `dev`, `session1` | ❌ Generic | ⚡ Instant | None |
| **Basic Smart** | `♦bookeper-accounting`, `🏠home` | ⚠️ Project-level | ⚡ Fast | tmux, fzf |
| **LLM-Powered** | `♦debug-react-auth`, `♦build-user-api` | ✅ Task-specific | 🔄 2-3 seconds | + Ollama |

## 🛠️ Setup

### Requirements
- **tmux** - Terminal multiplexer
- **fzf** - Fuzzy finder for session browser
- **Ollama** - Local LLM runtime ([ollama.ai](https://ollama.ai))
- **llama3.2** model - Auto-installed on first use

### Installation
```bash
# 1. Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# 2. Clone the repository
git clone https://github.com/excelsier/tmux-session-browser.git
cd tmux-session-browser

# 3. Run the installer
./install.sh

# 4. Test LLM features
./tmux-llm-naming.sh analyze
```

## 🎨 Example Analysis Results

### React Development Session
```
🎯 Found Claude session: dev:1.0
   Analysis: ♦debug-react-auth
```
*Based on conversation about authentication errors and React component fixes*

### API Development Session  
```
🎯 Found Claude session: backend:2.1
   Analysis: ♦build-user-endpoints
```
*Based on discussion about creating REST API endpoints for user management*

### Bug Fixing Session
```
🎯 Found Claude session: hotfix:0.0
   Analysis: ♦fix-typescript-errors
```
*Based on TypeScript compilation errors and type fixes*

## ⚡ Performance & Caching

- **First analysis**: 2-3 seconds per session
- **Cached results**: Instant (5-minute TTL)
- **Fallback**: Basic smart naming if LLM unavailable
- **Local processing**: All analysis happens on your machine

## 🔧 Customization

### Adjust Analysis Depth
Edit `MAX_CONTENT_LENGTH` in `tmux-llm-naming.sh`:
```bash
MAX_CONTENT_LENGTH=8000  # More context, slower analysis
MAX_CONTENT_LENGTH=2000  # Less context, faster analysis
```

### Change LLM Model
```bash
OLLAMA_MODEL="llama3.1:latest"  # Larger, more accurate
OLLAMA_MODEL="phi3:latest"      # Smaller, faster
```

### Custom Cache Duration
```bash
CACHE_TTL=600   # 10 minutes
CACHE_TTL=60    # 1 minute
```

## 🎯 Best Practices

### For Claude Code Users
1. **Let sessions accumulate context** - LLM gets better with more conversation
2. **Use descriptive file names** - helps LLM understand project structure  
3. **Work in focused sessions** - one main task per session for clearest naming
4. **Regularly clean up** - use the browser to kill old sessions after LLM naming

### For Performance
1. **Cache awareness** - results are cached for 5 minutes
2. **Batch analysis** - analyze all sessions at once rather than individually
3. **Fallback ready** - system works without LLM, just less specific

## 🔮 Future Enhancements

- **Context continuity** - remember project context across sessions
- **Task tracking** - detect when tasks are completed vs ongoing
- **Integration suggestions** - recommend which sessions to merge/split
- **Workflow analysis** - understand your development patterns

## 🎉 The Ultimate Claude Code Workflow

1. **Work normally** - use Claude Code as usual across multiple sessions
2. **Analyze occasionally** - run LLM analysis when sessions accumulate
3. **Browse with context** - see exactly what each session is doing
4. **Clean up confidently** - kill old sessions knowing their purpose
5. **Stay organized** - maintain clarity across all your development work

This is tmux session management evolved for the AI-assisted development era! 🚀