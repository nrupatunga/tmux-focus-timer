#!/usr/bin/env bash
TIMER_DIR="/tmp/tmux-timers"
for i in 1 2 3; do [ -f "$TIMER_DIR/$i.timer" ] && echo "          $(~/.local/bin/tmux-timer-display)          " && exit; done
