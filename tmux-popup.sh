#!/bin/bash

# Tmux Session Browser - Popup Overlay Version
# Designed to run inside tmux as a popup

# Compact session list for popup
tmux list-sessions -F "#{session_activity}:#{session_name}:#{session_windows}:#{?session_attached,ATTACHED,DETACHED}" | 
sort -n | 
while IFS=: read -r activity name windows attached; do
    # Calculate age
    now=$(date '+%s')
    age=$((now - activity))
    
    # Format time (shorter for popup)
    if [ $age -lt 3600 ]; then
        time_str="$((age/60))m"
    elif [ $age -lt 86400 ]; then
        time_str="$((age/3600))h"
    else
        time_str="$((age/86400))d"
    fi
    
    # Device detection for attached sessions
    if [ "$attached" = "ATTACHED" ]; then
        has_mac=false
        has_ipad=false
        
        while IFS= read -r client_info; do
            [ -z "$client_info" ] && continue
            width="${client_info%x*}"
            height="${client_info#*x}"
            
            if [ "$width" -lt 80 ] || [ "$height" -lt 30 ]; then
                has_ipad=true
            else
                has_mac=true
            fi
        done < <(tmux list-clients -t "$name" -F "#{client_width}x#{client_height}" 2>/dev/null)
        
        if [ "$has_mac" = true ] && [ "$has_ipad" = true ]; then
            att="💻📱"
        elif [ "$has_ipad" = true ]; then
            att="📱 "
        elif [ "$has_mac" = true ]; then
            att="💻 "
        else
            att="A "
        fi
    else
        att="  "
    fi
    
    # Age indicator
    [ $age -lt 300 ] && age_icon="🟢" || { [ $age -lt 3600 ] && age_icon="🟡" || age_icon="🔴"; }
    
    printf "%s%s %-18s %sw %4s\n" "$age_icon" "$att" "$name" "$windows" "$time_str"
done |
fzf --height=100% --border=rounded \
    --header='Tmux Sessions (ESC to close)' \
    --preview='
        line="{}"
        # Extract session name (starts at position 5, length 18, then trim)
        session="${line:5:18}"
        session="${session%% *}"
        
        echo "SESSION: $session"
        echo "══════════════════════════════════════════"
        
        # Quick status
        if tmux list-sessions | grep "^${session}:" | grep -q "attached"; then
            client_count=$(tmux list-clients -t "$session" 2>/dev/null | wc -l)
            echo "Status: ATTACHED ($client_count clients)"
        else
            echo "Status: DETACHED"
        fi
        echo
        
        # Show windows with recent activity
        tmux list-windows -t "$session" 2>/dev/null | while IFS= read -r window; do
            win_num="${window%%:*}"
            win_info="${window#*: }"
            echo "Window $win_num: $win_info"
            
            # Show last few lines of output
            output=$(tmux capture-pane -t "${session}:${win_num}.1" -p -S -10 2>/dev/null)
            if [ -n "$output" ]; then
                echo "$output" | grep -v "^$" | tail -5 | sed "s/^/  /"
            fi
            echo
        done
    ' \
    --preview-window=right:60%:wrap \
    --bind 'enter:execute(
        line="{}"
        session="${line:5:18}"
        session="${session%% *}"
        
        # Ask what to do
        echo "Session: $session"
        echo
        echo "Choose action:"
        echo "1) Attach to session"
        echo "2) Kill session"  
        echo "3) Cancel"
        echo
        read -p "Enter choice (1-3): " choice
        
        case $choice in
            1) tmux attach -t "$session" ;;
            2) 
                read -p "Really kill $session? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    tmux kill-session -t "$session"
                    echo "Killed: $session"
                fi
                ;;
            *) echo "Cancelled" ;;
        esac
        echo
        echo "Press any key to continue..."
        read -n 1
    )+abort' \
    --bind 'ctrl-a:execute(
        line="{}"
        session="${line:5:18}"  
        session="${session%% *}"
        tmux attach -t "$session"
    )+abort' \
    --prompt='Session > '