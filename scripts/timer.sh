#!/usr/bin/env bash

# tmux-timer: Multiple timer support (max 3)
# Usage: tmux-timer 5m water    - Start timer with label
#        tmux-timer stop        - Stop all timers
#        tmux-timer stop 1      - Stop timer #1
#        tmux-timer list        - List active timers

TIMER_DIR="/tmp/tmux-timers"
MAX_TIMERS=3

mkdir -p "$TIMER_DIR"

show_usage() {
    echo "Usage: tmux-timer <duration> [message]  Start a timer"
    echo "       tmux-timer stop [1|2|3]          Stop timer(s)"
    echo "       tmux-timer list                  List active timers"
}

parse_duration() {
    local duration="$1"
    local seconds=0

    if [[ $duration =~ ([0-9]+)h ]]; then
        seconds=$((seconds + ${BASH_REMATCH[1]} * 3600))
    fi
    if [[ $duration =~ ([0-9]+)m ]]; then
        seconds=$((seconds + ${BASH_REMATCH[1]} * 60))
    fi
    if [[ $duration =~ ([0-9]+)s ]]; then
        seconds=$((seconds + ${BASH_REMATCH[1]}))
    fi
    if [[ $duration =~ ^[0-9]+$ ]]; then
        seconds=$((duration * 60))
    fi
    echo "$seconds"
}

get_free_slot() {
    for i in 1 2 3; do
        if [ ! -f "$TIMER_DIR/$i.timer" ]; then
            echo "$i"
            return
        fi
    done
    echo "0"
}

count_timers() {
    local count=0
    for i in 1 2 3; do
        [ -f "$TIMER_DIR/$i.timer" ] && count=$((count + 1))
    done
    echo "$count"
}

case "$1" in
    stop|clear|cancel)
        if [ -n "$2" ]; then
            rm -f "$TIMER_DIR/$2.timer"
            echo "Timer $2 stopped"
        else
            rm -f "$TIMER_DIR"/*.timer
            # Stop watcher when all timers stopped
            ~/.local/bin/tmux-timer-watcher stop >/dev/null 2>&1
            echo "All timers stopped"
        fi
        tmux refresh-client -S 2>/dev/null
        exit 0
        ;;
    pause)
        if [ -z "$2" ]; then
            echo "Usage: tt pause [1|2|3]"
            exit 1
        fi
        timer_file="$TIMER_DIR/$2.timer"
        if [ ! -f "$timer_file" ]; then
            echo "Timer $2 not found"
            exit 1
        fi
        source "$timer_file"
        if [ "$paused" = "1" ]; then
            echo "Timer $2 already paused"
            exit 0
        fi
        remaining=$((end_time - $(date +%s)))
        cat > "$timer_file" << EOF
remaining=$remaining
duration=$duration
message="$message"
paused=1
EOF
        tmux refresh-client -S 2>/dev/null
        echo "Timer $2 paused"
        exit 0
        ;;
    resume)
        if [ -z "$2" ]; then
            echo "Usage: tt resume [1|2|3]"
            exit 1
        fi
        timer_file="$TIMER_DIR/$2.timer"
        if [ ! -f "$timer_file" ]; then
            echo "Timer $2 not found"
            exit 1
        fi
        source "$timer_file"
        if [ "$paused" != "1" ]; then
            echo "Timer $2 not paused"
            exit 0
        fi
        end_time=$(($(date +%s) + remaining))
        cat > "$timer_file" << EOF
end_time=$end_time
duration=$duration
message="$message"
paused=0
EOF
        tmux refresh-client -S 2>/dev/null
        echo "Timer $2 resumed"
        exit 0
        ;;
    focus)
        # Start timer + distraction watcher
        shift
        duration="${1:-25m}"
        shift
        message="${*:-focus}"
        "$0" "$duration" "$message"
        ~/.local/bin/tmux-timer-watcher start
        exit 0
        ;;
    watcher)
        # Control the watcher
        shift
        ~/.local/bin/tmux-timer-watcher "$@"
        exit 0
        ;;
    list)
        for i in 1 2 3; do
            if [ -f "$TIMER_DIR/$i.timer" ]; then
                source "$TIMER_DIR/$i.timer"
                remaining=$((end_time - $(date +%s)))
                if [ "$remaining" -gt 0 ]; then
                    echo "#$i: ${message:-timer} ($remaining s left)"
                fi
            fi
        done
        exit 0
        ;;
    -h|--help)
        show_usage
        exit 0
        ;;
    "")
        show_usage
        exit 1
        ;;
    *)
        seconds=$(parse_duration "$1")
        if [ "$seconds" -eq 0 ]; then
            echo "Invalid duration: $1"
            exit 1
        fi

        slot=$(get_free_slot)
        if [ "$slot" -eq 0 ]; then
            echo "Max 3 timers. Stop one first: tt stop 1"
            exit 1
        fi

        shift
        message="$*"

        end_time=$(($(date +%s) + seconds))

        cat > "$TIMER_DIR/$slot.timer" << EOF
end_time=$end_time
duration=$seconds
message="$message"
paused=0
EOF

        # Auto-start watcher
        ~/.local/bin/tmux-timer-watcher start >/dev/null 2>&1

        tmux refresh-client -S 2>/dev/null
        echo "Timer #$slot started: ${message:-focus}"
        exit 0
        ;;
esac
