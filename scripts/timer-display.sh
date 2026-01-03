#!/usr/bin/env bash
TIMER_DIR="/tmp/tmux-timers"; now=$(date +%s); output=""
for i in 1 2 3; do
    [ ! -f "$TIMER_DIR/$i.timer" ] && continue; source "$TIMER_DIR/$i.timer"; label="${message:-$i}"; label="${label:0:8}"
    if [ "$paused" = "1" ]; then pct=$((100 * (duration - remaining) / duration))
    else
        remaining=$((end_time - now))
        if [ "$remaining" -le 0 ]; then
            rm -f "$TIMER_DIR/$i.timer"
            notify-send -u normal "🎉 $label complete!" "Take a 10min break if you want" -t 10000 2>/dev/null
            output+="#[bg=#50fa7b,fg=#000000,bold] ✓$label #[default] "
            continue
        fi
        pct=$((100 * (duration - remaining) / duration))
    fi
    filled=$((pct * 5 / 100)); bar=$(printf '●%.0s' $(seq 1 $filled 2>/dev/null))$(printf '○%.0s' $(seq 1 $((5 - filled)) 2>/dev/null))
    colors=("#ffff00" "#00ffff" "#ff79c6"); color="${colors[$((i-1))]}"
    [ -n "$output" ] && output+="#[fg=#555555]│#[default]"
    [ "$paused" = "1" ] && output+="#[fg=#6272a4]$bar⏸$label #[default]" && continue
    [ "$remaining" -le 60 ] && output+="#[fg=#ff5555]$bar $label #[default]" || output+="#[fg=$color]$bar $label #[default]"
done
echo "$output"
