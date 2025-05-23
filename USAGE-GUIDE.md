# 🚀 Quick Usage Guide

## 🎯 How to Use LLM-Powered Session Management

### **Within tmux (Recommended):**

| Key Combo | Action | Description |
|-----------|--------|-------------|
| `Ctrl+a` then `i` | 🧠 **LLM Ultimate** | AI analysis + smart naming + browsing |
| `Ctrl+a` then `u` | ⚡ **Basic Ultimate** | Pattern-based naming + browsing |
| `Ctrl+a` then `s` | 📋 **Session Browser** | Just browse/kill sessions |
| `Ctrl+a` then `S` | 📋 **Side Pane** | Browser in side pane |

### **Command Line:**

```bash
# Navigate to the tool directory
cd /Users/krempovych/tmux-session-browser

# LLM-powered analysis and management
./tmux-ultimate-llm.sh          # Interactive menu
./tmux-llm-naming.sh analyze     # Just analyze Claude sessions
./tmux-llm-naming.sh dry-run     # Preview LLM naming
./tmux-llm-naming.sh rename      # Apply LLM naming

# Basic smart naming
./tmux-ultimate.sh               # Basic interactive menu
./tmux-smart-naming.sh           # Apply pattern-based naming

# Just session browsing
./tmux-session-browser.sh        # Browser only
```

## 🧠 LLM Features

### **What LLM Analysis Does:**
1. **Finds Claude Code sessions** automatically
2. **Reads conversation content** (last 100 lines)
3. **Analyzes project context** (working directory, recent files)
4. **Generates specific names** like:
   - `♦debug-react-auth` - Debugging React authentication
   - `♦build-api-endpoints` - Building REST API endpoints  
   - `♦fix-typescript-errors` - Fixing TypeScript compilation
   - `♦refactor-database` - Database schema work

### **Caching:**
- Results cached for **5 minutes**
- First analysis: **2-3 seconds**
- Cached results: **Instant**

### **Requirements:**
- ✅ Ollama installed
- ✅ llama3.2 model (auto-installs)
- ✅ Active Claude Code sessions

## 🎮 Step-by-Step Usage

### **First Time Setup:**
1. Install Ollama: `curl -fsSL https://ollama.ai/install.sh | sh`
2. Test: `cd /Users/krempovych/tmux-session-browser && ./tmux-llm-naming.sh analyze`
3. Use in tmux: `Ctrl+a` then `i`

### **Daily Workflow:**
1. **Work normally** with Claude Code across multiple tmux sessions
2. **When sessions accumulate**, press `Ctrl+a` then `i`
3. **Choose option 4** (Ultimate LLM Mode) for full workflow
4. **See AI-generated names** that tell you exactly what each session is doing
5. **Kill old sessions** with confidence using the browser

### **Troubleshooting:**
- **"Model not found"**: Wait for auto-install or run `ollama pull llama3.2`
- **"No Claude sessions"**: Make sure Claude Code is running in tmux
- **Binding not working**: Try `tmux source-file ~/.tmux.conf` to reload

## 🎯 Pro Tips

### **For Best LLM Results:**
- Let Claude conversations build up context (more content = better analysis)
- Work on focused tasks per session (one main topic per session)
- Use descriptive file names in your projects

### **Performance:**
- Use caching - don't re-analyze the same session repeatedly
- LLM mode is slower but much more accurate
- Basic mode is instant but less specific

### **Integration:**
- The tools work together - you can mix LLM and basic naming
- Session browser works with any naming approach
- All tools respect your existing tmux setup

## 🔧 Key Bindings Summary

Your tmux prefix is `Ctrl+a`, so:

- `Ctrl+a i` = 🧠 **LLM Ultimate Mode** (recommended for Claude users)
- `Ctrl+a u` = ⚡ **Basic Ultimate Mode** (fast, pattern-based)
- `Ctrl+a s` = 📋 **Session Browser** (browse/kill only)
- `Ctrl+a S` = 📋 **Side Pane Browser**

**Remember:** `i` = **i**ntelligent (LLM), `u` = **u**ltimate (basic)