#!/usr/bin/env bash

# tmux-timer-watcher: Detect distracting sites and prompt to work

TIMER_DIR="/tmp/tmux-timers"
PID_FILE="/tmp/tmux-timer-watcher.pid"
CHECK_INTERVAL=5  # seconds

# Load config
CONFIG_FILE="$HOME/.config/tmux-timer/distractions.conf"
DISTRACTIONS=()
GRACE_PERIOD=0

if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        # Parse GRACE_PERIOD setting
        if [[ "$line" =~ ^GRACE_PERIOD= ]]; then
            GRACE_PERIOD="${line#GRACE_PERIOD=}"
            continue
        fi
        DISTRACTIONS+=("$line")
    done < "$CONFIG_FILE"
else
    DISTRACTIONS=("youtube" "x.com" "twitter" "netflix" "reddit" "instagram" "facebook" "tiktok" "twitch")
fi

DISTRACTION_START_FILE="/tmp/tmux-timer-distraction-start"

get_active_window_title() {
    # Use xdotool getwindowfocus (works with xmonad)
    if command -v xdotool &>/dev/null; then
        local win_id
        win_id=$(xdotool getwindowfocus 2>/dev/null)
        if [ -n "$win_id" ]; then
            xprop -id "$win_id" WM_NAME 2>/dev/null | sed 's/.*= "//;s/"$//'
        fi
    fi
}

has_active_timer() {
    for i in 1 2 3; do
        if [ -f "$TIMER_DIR/$i.timer" ]; then
            source "$TIMER_DIR/$i.timer"
            # Skip paused timers
            [ "$paused" = "1" ] && continue
            local remaining=$((end_time - $(date +%s)))
            [ "$remaining" -gt 0 ] && return 0
        fi
    done
    return 1
}

is_distracted() {
    local title=$(get_active_window_title | tr '[:upper:]' '[:lower:]')
    [ -z "$title" ] && return 1

    for site in "${DISTRACTIONS[@]}"; do
        if [[ "$title" == *"$site"* ]]; then
            echo "$site"
            return 0
        fi
    done
    return 1
}

send_notification() {
    local site="$1"
    # Flash the status bar
    for i in 1 2 3; do
        tmux set -g status-style "bg=#ff0000,fg=#ffffff,bold" 2>/dev/null
        sleep 0.3
        tmux set -g status-style "bg=#020221,fg=#ffffff" 2>/dev/null
        sleep 0.3
    done
    # Center popup
    tmux display-popup -w 50% -h 25% -E "echo ''; echo '   ⚠️  FOCUS!'; echo ''; echo '   You have a timer running.'; echo '   Stop browsing $site!'; echo ''; echo '   Press ENTER to close'; read"
    notify-send -u critical "Focus!" "Stop browsing $site!" -t 5000 2>/dev/null
}

# Commands
case "$1" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
            echo "Watcher already running"
            exit 0
        fi

        # Start in background
        nohup "$0" watch > /dev/null 2>&1 &
        echo $! > "$PID_FILE"
        echo "Distraction watcher started"
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            kill "$(cat $PID_FILE)" 2>/dev/null
            rm -f "$PID_FILE"
            echo "Watcher stopped"
        else
            echo "Watcher not running"
        fi
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
            echo "Watcher running (PID: $(cat $PID_FILE))"
        else
            echo "Watcher not running"
        fi
        ;;
    watch)
        # Main watch loop (called internally)
        last_notify=0
        no_timer_count=0
        while true; do
            if has_active_timer; then
                no_timer_count=0
                site=$(is_distracted)
                now=$(date +%s)

                if [ -n "$site" ]; then
                    # Track when distraction started
                    if [ ! -f "$DISTRACTION_START_FILE" ]; then
                        echo "$now" > "$DISTRACTION_START_FILE"
                    fi

                    distraction_start=$(cat "$DISTRACTION_START_FILE")
                    elapsed=$((now - distraction_start))

                    # Only warn after grace period
                    if [ "$elapsed" -ge "$GRACE_PERIOD" ]; then
                        # Don't spam - notify max once per 30 seconds
                        if [ $((now - last_notify)) -gt 30 ]; then
                            send_notification "$site"
                            last_notify=$now
                        fi
                    fi
                else
                    # Not distracted - reset timer
                    rm -f "$DISTRACTION_START_FILE"
                fi
            else
                # No active timers - exit after a few checks
                no_timer_count=$((no_timer_count + 1))
                rm -f "$DISTRACTION_START_FILE"
                if [ "$no_timer_count" -ge 3 ]; then
                    rm -f "$PID_FILE"
                    exit 0
                fi
            fi
            sleep $CHECK_INTERVAL
        done
        ;;
    *)
        echo "Usage: tmux-timer-watcher [start|stop|status]"
        ;;
esac
