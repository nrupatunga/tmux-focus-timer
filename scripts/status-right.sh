#!/usr/bin/env bash

# tmux-status-right: Show timers with padding

TIMER_DIR="/tmp/tmux-timers"

# Check if any timer is active
has_timers=false
for i in 1 2 3; do
    [ -f "$TIMER_DIR/$i.timer" ] && has_timers=true && break
done

if [ "$has_timers" = true ]; then
    echo "          $(~/.local/bin/tmux-timer-display)          "
else
    echo ""
fi
