#!/usr/bin/env bash
TIMER_DIR="/tmp/tmux-timers"; mkdir -p "$TIMER_DIR"
refresh() { tmux refresh-client -S 2>/dev/null; }
write_timer() {
    local file="$1" msg="$2"
    [ "$paused" = "1" ] && printf 'remaining=%s\nduration=%s\nmessage="%s"\npaused=1\n' "$remaining" "$duration" "$msg" > "$file" \
                        || printf 'end_time=%s\nduration=%s\nmessage="%s"\npaused=0\n' "$end_time" "$duration" "$msg" > "$file"
}
find_timer() {
    local t="$1"; [[ "$t" =~ ^[123]$ ]] && [ -f "$TIMER_DIR/$t.timer" ] && echo "$TIMER_DIR/$t.timer" && return
    for i in 1 2 3; do [ -f "$TIMER_DIR/$i.timer" ] && source "$TIMER_DIR/$i.timer" && [ "$message" = "$t" ] && echo "$TIMER_DIR/$i.timer" && return; done
}
parse_duration() {
    local d="$1" s=0
    [[ $d =~ ([0-9]+)h ]] && s=$((s + ${BASH_REMATCH[1]} * 3600)); [[ $d =~ ([0-9]+)m ]] && s=$((s + ${BASH_REMATCH[1]} * 60))
    [[ $d =~ ([0-9]+)s ]] && s=$((s + ${BASH_REMATCH[1]})); [[ $d =~ ^[0-9]+$ ]] && s=$((d * 60)); echo "$s"
}
case "$1" in
    stop|clear|cancel)
        [ -n "$2" ] && rm -f "$TIMER_DIR/$2.timer" && echo "Timer $2 stopped" \
                    || { rm -f "$TIMER_DIR"/*.timer; ~/.local/bin/tmux-timer-watcher stop 2>/dev/null; echo "All stopped"; }
        refresh; exit 0 ;;
    pause)
        [ -z "$2" ] && echo "Usage: tt pause [1|2|3]" && exit 1; timer_file="$TIMER_DIR/$2.timer"
        [ ! -f "$timer_file" ] && echo "Timer $2 not found" && exit 1; source "$timer_file"
        [ "$paused" = "1" ] && echo "Already paused" && exit 0
        remaining=$((end_time - $(date +%s))); paused=1; write_timer "$timer_file" "$message"; refresh; echo "Paused"; exit 0 ;;
    resume)
        [ -z "$2" ] && echo "Usage: tt resume [1|2|3]" && exit 1; timer_file="$TIMER_DIR/$2.timer"
        [ ! -f "$timer_file" ] && echo "Timer $2 not found" && exit 1; source "$timer_file"
        [ "$paused" != "1" ] && echo "Not paused" && exit 0
        end_time=$(($(date +%s) + remaining)); paused=0; write_timer "$timer_file" "$message"; refresh; echo "Resumed"; exit 0 ;;
    rename)
        [ -z "$2" ] || [ -z "$3" ] && echo "Usage: tt rename <slot|label> <name>" && exit 1
        timer_file=$(find_timer "$2"); [ -z "$timer_file" ] && echo "Not found" && exit 1
        source "$timer_file"; old="$message"; shift 2; write_timer "$timer_file" "$*"; refresh; echo "'$old' -> '$*'"; exit 0 ;;
    focus) shift; "$0" "${1:-25m}" "${*:2:-focus}"; ~/.local/bin/tmux-timer-watcher start; exit 0 ;;
    watcher) shift; ~/.local/bin/tmux-timer-watcher "$@"; exit 0 ;;
    list) for i in 1 2 3; do [ -f "$TIMER_DIR/$i.timer" ] && source "$TIMER_DIR/$i.timer" && r=$((end_time - $(date +%s))) && [ "$r" -gt 0 ] && echo "#$i: ${message:-timer} (${r}s)"; done; exit 0 ;;
    monitorme) ~/.local/bin/tmux-activity-monitor start; exit 0 ;;
    stopmonitor) ~/.local/bin/tmux-activity-monitor stop; exit 0 ;;
    stats) shift; ~/.local/bin/tmux-activity-monitor stats "$@"; exit 0 ;;
    -h|--help|"") echo "tt <dur> [label] | stop [n] | pause/resume [n] | rename | list | monitorme | stats"; exit 0 ;;
    *)
        s=$(parse_duration "$1"); [ "$s" -eq 0 ] && echo "Invalid: $1" && exit 1
        slot=0; for i in 1 2 3; do [ ! -f "$TIMER_DIR/$i.timer" ] && slot=$i && break; done
        [ "$slot" -eq 0 ] && echo "Max 3. tt stop 1" && exit 1; shift
        end_time=$(($(date +%s) + s)); duration=$s; paused=0; write_timer "$TIMER_DIR/$slot.timer" "$*"
        ~/.local/bin/tmux-timer-watcher start 2>/dev/null; refresh; echo "#$slot: ${*:-focus}"; exit 0 ;;
esac
