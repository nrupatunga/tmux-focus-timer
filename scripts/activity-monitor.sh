#!/usr/bin/env bash
DATA_DIR="$HOME/.local/share/tmux-timer"; mkdir -p "$DATA_DIR"
PID_FILE="/tmp/tmux-activity-monitor.pid"; LOG_FILE="$DATA_DIR/activity-$(date +%Y-%m-%d).log"
get_window() { command -v xdotool &>/dev/null && id=$(xdotool getwindowfocus 2>/dev/null) && [ -n "$id" ] && echo "$(xprop -id "$id" WM_CLASS 2>/dev/null | sed 's/.*= "//;s/".*$//')|$(xprop -id "$id" WM_NAME 2>/dev/null | sed 's/.*= "//;s/"$//')"; }
parse_app() {
    case "$1" in
        *firefox*|*chrom*|*brave*) echo "browser:$(echo "$2" | sed 's/.* - //;s/.* — //' | cut -c1-30)" ;;
        *term*|*kitty*|*alacritty*|*wezterm*) echo "terminal" ;;
        *code*|*nvim*|*vim*) echo "editor" ;;
        *slack*|*discord*|*telegram*) echo "chat" ;;
        *) echo "other:${1:0:20}" ;;
    esac
}
case "$1" in
    start) [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null && echo "Already running" && exit 0; nohup "$0" watch >/dev/null 2>&1 & echo $! > "$PID_FILE"; echo "Monitoring started" ;;
    stop) [ -f "$PID_FILE" ] && kill "$(cat $PID_FILE)" 2>/dev/null && rm -f "$PID_FILE" && echo "Stopped" || echo "Not running" ;;
    status) [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null && echo "Running" || echo "Not running" ;;
    watch) last=""; while true; do win=$(get_window); [ -n "$win" ] && app=$(parse_app "${win%%|*}" "${win#*|}") && [ "$app" != "$last" ] && echo "$(date +%s) $app" >> "$LOG_FILE" && last="$app"; sleep 5; done ;;
    stats)
        day="${2:-today}"; [ "$day" = "today" ] && f="$LOG_FILE" || f="$DATA_DIR/activity-$day.log"
        [ ! -f "$f" ] && echo "No data" && exit 1
        declare -A t h; tot=0; pts=0; papp=""
        while read ts app; do [ -n "$papp" ] && [ "$pts" -gt 0 ] && { d=$((ts-pts)); [ "$d" -gt 300 ] && d=300; t[$papp]=$((${t[$papp]:-0}+d)); tot=$((tot+d)); hr=$(date -d @$pts +%H 2>/dev/null || date -r $pts +%H); h[$hr]=$((${h[$hr]:-0}+d)); }; pts=$ts; papp=$app; done < "$f"
        [ -n "$papp" ] && { d=$(($(date +%s)-pts)); [ "$d" -gt 300 ] && d=300; t[$papp]=$((${t[$papp]:-0}+d)); tot=$((tot+d)); hr=$(date -d @$pts +%H 2>/dev/null || date -r $pts +%H); h[$hr]=$((${h[$hr]:-0}+d)); }
        [ "$tot" -eq 0 ] && echo "No activity" && exit 0
        printf "\n  \e[1mScreen Time: %dh %dm\e[0m\n\n  \e[1mHourly:\e[0m\n" $((tot/3600)) $((tot%3600/60))
        max=1; for x in "${!h[@]}"; do [ "${h[$x]}" -gt "$max" ] && max="${h[$x]}"; done
        for x in 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 00; do b=$((${h[$x]:-0}*20/max)); [ "$b" -eq 0 ] && [ "${h[$x]:-0}" -gt 0 ] && b=1; bar=""; for ((i=0;i<b;i++)); do bar+="▓"; done; printf "  %s \e[32m%-20s\e[0m %2dm\n" "$x" "$bar" $((${h[$x]:-0}/60)); done
        printf "\n  \e[1mApps:\e[0m\n"
        for a in "${!t[@]}"; do echo "${t[$a]} $a"; done | sort -rn | head -10 | while read s a; do p=$((s*100/tot)); bar=""; for ((i=0;i<p/5;i++)); do bar+="█"; done; printf "  %-25s %3d%% \e[36m%-20s\e[0m %dm\n" "$a" "$p" "$bar" $((s/60)); done; echo "" ;;
    *) echo "Usage: activity-monitor [start|stop|status|stats [YYYY-MM-DD]]" ;;
esac
