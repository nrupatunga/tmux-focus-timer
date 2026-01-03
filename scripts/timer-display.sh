#!/usr/bin/env bash

# tmux-timer-display: Show multiple timers - just progress bar + label

TIMER_DIR="/tmp/tmux-timers"
BAR_WIDTH=6

draw_bar() {
    local percent=$1
    local filled=$((percent * BAR_WIDTH / 100))
    local empty=$((BAR_WIDTH - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done

    # Subtle blink
    local blink=$(($(date +%s) % 2))
    if [ "$blink" -eq 0 ]; then
        bar+="·"
    else
        bar+=" "
    fi

    echo "$bar"
}

output=""
now=$(date +%s)

for i in 1 2 3; do
    timer_file="$TIMER_DIR/$i.timer"
    [ ! -f "$timer_file" ] && continue

    source "$timer_file"

    # Handle paused timers
    if [ "$paused" = "1" ]; then
        elapsed=$((duration - remaining))
        percent=$((elapsed * 100 / duration))
        bar=$(draw_bar $percent)
        label="${message:-$i}"
        label="${label:0:8}"
        # Dimmed color + pause icon for paused
        output+="#[fg=#6272a4]$bar⏸$label #[default]"
        continue
    fi

    remaining=$((end_time - now))

    # Timer expired - remove it
    if [ "$remaining" -le 0 ]; then
        rm -f "$timer_file"
        output+="#[bg=#ff5555,fg=#000000,bold] ${message:-done}! #[default] "
        continue
    fi

    # Calculate progress
    elapsed=$((duration - remaining))
    percent=$((elapsed * 100 / duration))
    bar=$(draw_bar $percent)

    # Color based on urgency
    if [ "$remaining" -le 60 ]; then
        color="#ff5555"
    else
        color="#f1fa8c"
    fi

    # Just bar + label
    label="${message:-$i}"
    label="${label:0:8}"

    output+="#[fg=$color]$bar$label #[default]"
done

echo "$output"
