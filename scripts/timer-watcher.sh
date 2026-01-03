#!/usr/bin/env bash
TIMER_DIR="/tmp/tmux-timers"; PID_FILE="/tmp/tmux-timer-watcher.pid"; CHECK_INTERVAL=5
CONFIG_FILE="$HOME/.config/tmux-timer/distractions.conf"; DISTRACTIONS=(); GRACE_PERIOD=0
if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        [[ "$line" =~ ^GRACE_PERIOD= ]] && GRACE_PERIOD="${line#GRACE_PERIOD=}" && continue
        DISTRACTIONS+=("$line")
    done < "$CONFIG_FILE"
else DISTRACTIONS=("youtube" "x.com" "twitter" "netflix" "reddit" "instagram" "facebook" "tiktok" "twitch"); fi
DISTRACTION_START="/tmp/tmux-timer-distraction-start"
get_window_title() { command -v xdotool &>/dev/null && xprop -id "$(xdotool getwindowfocus 2>/dev/null)" WM_NAME 2>/dev/null | sed 's/.*= "//;s/"$//'; }
has_active_timer() { for i in 1 2 3; do [ -f "$TIMER_DIR/$i.timer" ] && source "$TIMER_DIR/$i.timer" && [ "$paused" != "1" ] && [ $((end_time - $(date +%s))) -gt 0 ] && return 0; done; return 1; }
is_distracted() { local title=$(get_window_title | tr '[:upper:]' '[:lower:]'); [ -z "$title" ] && return 1; for s in "${DISTRACTIONS[@]}"; do [[ "$title" == *"$s"* ]] && echo "$s" && return 0; done; return 1; }
notify() {
    for i in 1 2 3; do tmux set -g status-style "bg=#ff0000,fg=#ffffff,bold" 2>/dev/null; sleep 0.2; tmux set -g status-style "bg=#020221,fg=#ffffff" 2>/dev/null; sleep 0.2; done
    tmux display-popup -w 40 -h 10 -S "fg=#ff5555,bold" -b rounded -E "
        printf '\n\e[1;31m       ╔══════════════════════╗\e[0m\n'
        printf '\e[1;31m       ║   \e[5m⚠️  FOCUS! ⚠️\e[25m     ║\e[0m\n'
        printf '\e[1;31m       ╠══════════════════════╣\e[0m\n'
        printf '\e[1;37m       ║  Stop browsing \e[33m$1\e[37m   ║\e[0m\n'
        printf '\e[1;31m       ╚══════════════════════╝\e[0m\n\n'
        printf '\e[2m         [Press ENTER]\e[0m'; read"
    notify-send -u critical "Focus!" "Stop browsing $1!" -t 5000 2>/dev/null
}
case "$1" in
    start)
        [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null && echo "Already running" && exit 0
        nohup "$0" watch >/dev/null 2>&1 & echo $! > "$PID_FILE"; echo "Watcher started" ;;
    stop) [ -f "$PID_FILE" ] && kill "$(cat $PID_FILE)" 2>/dev/null && rm -f "$PID_FILE" && echo "Stopped" || echo "Not running" ;;
    status) [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null && echo "Running ($(cat $PID_FILE))" || echo "Not running" ;;
    watch)
        last_notify=0; no_timer=0
        while true; do
            if has_active_timer; then
                no_timer=0; site=$(is_distracted); now=$(date +%s)
                if [ -n "$site" ]; then
                    [ ! -f "$DISTRACTION_START" ] && echo "$now" > "$DISTRACTION_START"
                    elapsed=$((now - $(cat "$DISTRACTION_START")))
                    [ "$elapsed" -ge "$GRACE_PERIOD" ] && [ $((now - last_notify)) -gt 30 ] && notify "$site" && last_notify=$now
                else rm -f "$DISTRACTION_START"; fi
            else
                no_timer=$((no_timer + 1)); rm -f "$DISTRACTION_START"
                [ "$no_timer" -ge 3 ] && rm -f "$PID_FILE" && exit 0
            fi; sleep $CHECK_INTERVAL
        done ;;
    *) echo "Usage: tmux-timer-watcher [start|stop|status]" ;;
esac
