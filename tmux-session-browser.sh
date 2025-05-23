#!/bin/bash

# Tmux Session Browser - Clean & Readable Version

if ! tmux ls &>/dev/null; then
    echo "No tmux sessions running."
    exit 0
fi

# Create session list with device info
tmux list-sessions -F "#{session_activity}:#{session_name}:#{session_windows}:#{?session_attached,ATTACHED,DETACHED}" | 
sort -n | 
while IFS=: read -r activity name windows attached; do
    # Calculate age
    now=$(date '+%s')
    age=$((now - activity))
    
    # Format time
    if [ $age -lt 3600 ]; then
        time_str="$((age/60))m ago"
    elif [ $age -lt 86400 ]; then
        time_str="$((age/3600))h ago"
    else
        time_str="$((age/86400))d ago"
    fi
    
    # Status indicators
    [ $age -lt 300 ] && status="●" || { [ $age -lt 3600 ] && status="●" || status="●"; }
    
    # Check attachment and device types
    if [ "$attached" = "ATTACHED" ]; then
        # Get all client info for this session
        has_mac=false
        has_ipad=false
        client_count=0
        
        while IFS= read -r client_info; do
            [ -z "$client_info" ] && continue
            client_count=$((client_count + 1))
            
            width="${client_info%x*}"
            height="${client_info#*x}"
            
            # Device detection based on terminal size
            if [ "$width" -lt 80 ] || [ "$height" -lt 30 ]; then
                has_ipad=true
            elif [ "$width" -ge 150 ] || [ "$height" -ge 50 ]; then
                has_mac=true
            else
                has_mac=true  # Default medium size to Mac
            fi
        done < <(tmux list-clients -t "$name" -F "#{client_width}x#{client_height}" 2>/dev/null)
        
        # Show appropriate icon based on connected devices
        if [ "$has_mac" = true ] && [ "$has_ipad" = true ]; then
            att="💻📱" # Both Mac and iPad
        elif [ "$has_ipad" = true ]; then
            att="📱" # iPad only
        elif [ "$has_mac" = true ]; then
            att="💻" # Mac only
        elif [ "$client_count" -gt 0 ]; then
            att="[${client_count}]" # Multiple unknown clients
        else
            att="[A]" # Attached but no client info
        fi
    else
        att="   "
    fi
    
    printf "%s %s %-20s %2s win  %-10s\n" "$status" "$att" "$name" "$windows" "$time_str"
done |
fzf --ansi --height=95% \
    --header=$'Tmux Session Browser\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n↑↓ Navigate │ SPACE Select │ ENTER Kill │ CTRL-A Attach\n' \
    --preview='
        # Parse session name
        line="{}"
        session=$(echo "$line" | awk "{print \$3}")
        
        # Header with session name
        echo ""
        echo "  SESSION: $session"
        echo "  ════════════════════════════════════════════════════════════"
        echo ""
        
        # Attachment status and client info
        if tmux list-sessions 2>/dev/null | grep "^${session}:" | grep -q "attached"; then
            # Count clients and device types
            client_count=$(tmux list-clients -t "$session" 2>/dev/null | wc -l)
            
            echo "  🔗 ATTACHED - Currently in use ($client_count clients)"
            
            # Get client details
            echo ""
            echo "  Connected clients:"
            tmux list-clients -t "$session" -F "#{client_tty}|#{client_width}x#{client_height}|#{client_name}|#{client_session}|#{client_termname}" 2>/dev/null | while IFS="|" read -r tty size name sess term; do
                # Detect device type based on terminal size and characteristics
                width="${size%x*}"
                height="${size#*x}"
                
                # Device detection logic based on terminal characteristics
                device_type="Unknown"
                
                # Check for SSH connections (often from iPad apps)
                if [[ "$tty" == *"pts/"* ]]; then
                    # Pseudo-terminal - likely SSH
                    if [ "$width" -lt 80 ] || [ "$height" -lt 30 ]; then
                        device_type="📱 iPad SSH"
                    else
                        device_type="💻 Remote SSH"
                    fi
                elif [[ "$term" == *"tmux"* ]] || [[ "$term" == *"screen"* ]]; then
                    # Nested tmux/screen session
                    device_type="🔄 Nested Session"
                elif [ "$width" -lt 80 ] || [ "$height" -lt 30 ]; then
                    # Small screen - likely mobile/iPad
                    device_type="📱 iPad/Mobile"
                elif [ "$width" -ge 150 ] && [ "$height" -ge 50 ]; then
                    # Large screen - definitely desktop
                    device_type="💻 Mac/Desktop"
                elif [[ "$tty" == *"ttys"* ]]; then
                    # Local Mac terminal
                    if [ "$width" -ge 120 ]; then
                        device_type="💻 Mac Terminal"
                    else
                        device_type="🖥️ Mac (small window)"
                    fi
                else
                    # Medium size - make educated guess
                    if [ "$width" -le 100 ] && [ "$height" -le 40 ]; then
                        device_type="📱 iPad (probable)"
                    else
                        device_type="💻 Mac (probable)"
                    fi
                fi
                
                echo "    • $device_type - ${width}x${height} ($tty)"
            done
        else
            echo "  ✓  DETACHED - Safe to remove"
        fi
        echo ""
        
        # Process each window
        tmux list-windows -t "$session" 2>/dev/null | while IFS= read -r window; do
            win_num="${window%%:*}"
            win_rest="${window#*: }"
            win_name="${win_rest%% *}"
            
            # Window header
            echo ""
            echo "  ┌─ Window $win_num: $win_name"
            echo "  │"
            
            # Get pane info
            pane_count=$(tmux list-panes -t "${session}:${win_num}" 2>/dev/null | wc -l)
            echo "  │  Panes: $pane_count"
            
            # Show what is running
            tmux list-panes -t "${session}:${win_num}" -F "#{pane_index}:#{pane_current_command}:#{pane_current_path}" 2>/dev/null | while IFS=: read -r pnum pcmd ppath; do
                # Clean path
                clean_path="${ppath/#$HOME/~}"
                echo "  │  └─ Pane $pnum: $pcmd ($clean_path)"
            done
            
            echo "  │"
            echo "  │  Terminal Output:"
            echo "  │  ─────────────────────────────────────────────"
            
            # Capture output from first pane
            output=$(tmux capture-pane -t "${session}:${win_num}.1" -p -S -50 2>/dev/null)
            
            if [ -n "$output" ]; then
                # Process output for better readability
                echo "$output" | tail -30 | while IFS= read -r line; do
                    # Skip empty lines
                    [ -z "$line" ] && continue
                    
                    # Trim to 75 chars if too long
                    if [ ${#line} -gt 75 ]; then
                        line="${line:0:72}..."
                    fi
                    
                    echo "  │  $line"
                done
            else
                echo "  │  [No recent activity]"
            fi
            echo "  │"
            echo "  └────────────────────────────────────────────────────"
        done
        
        # Footer
        echo ""
        echo "  ════════════════════════════════════════════════════════════"
        total_windows=$(tmux list-windows -t "$session" 2>/dev/null | wc -l)
        echo "  Total: $total_windows windows"
    ' \
    --preview-window=right:65%:wrap \
    --multi \
    --bind 'space:toggle' \
    --bind 'ctrl-a:execute-silent(tmux attach -t {3})+abort' \
    --bind 'enter:execute(
        selected={}
        if [ -n "$selected" ]; then
            echo "$selected" | while read line; do 
                session=$(echo "$line" | awk "{print \$3}")
                echo "Killing session: $session"
                tmux kill-session -t "$session" 2>/dev/null && echo "✓ Killed: $session" || echo "✗ Failed: $session"
            done
            echo ""
            echo "Press any key to exit..."
            read -n 1
        fi
    )+abort' \
    --marker='✓' \
    --pointer='▶' \
    --prompt='Select sessions > '