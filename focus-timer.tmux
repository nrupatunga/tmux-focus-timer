#!/usr/bin/env bash

# tmux-focus-timer: A Pomodoro-style focus timer plugin for tmux
# https://github.com/yourusername/tmux-focus-timer

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default options
default_key="T"
default_status_position="right"

# Get tmux option or default
get_tmux_option() {
    local option="$1"
    local default_value="$2"
    local option_value
    option_value=$(tmux show-option -gqv "$option")
    if [ -z "$option_value" ]; then
        echo "$default_value"
    else
        echo "$option_value"
    fi
}

# Set up key bindings
setup_bindings() {
    local key
    key=$(get_tmux_option "@focus-timer-key" "$default_key")

    # Bind key to start 25m timer
    tmux bind-key "$key" run-shell "$CURRENT_DIR/scripts/timer.sh 25m focus"
}

# Set up status bar integration
setup_status() {
    local position
    position=$(get_tmux_option "@focus-timer-position" "$default_status_position")

    # Make scripts available in PATH
    tmux set-environment -g TMUX_FOCUS_TIMER_DIR "$CURRENT_DIR"
}

# Create config directory if needed
setup_config() {
    local config_dir="$HOME/.config/tmux-timer"
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
    fi

    if [ ! -f "$config_dir/distractions.conf" ]; then
        cat > "$config_dir/distractions.conf" << 'EOF'
# Tmux Focus Timer Config

# Grace period in seconds - how long on a distraction before warning
GRACE_PERIOD=30

# Add one distraction per line (matches window title, case insensitive)
youtube
x.com
twitter
netflix
reddit
instagram
facebook
tiktok
twitch
EOF
    fi
}

# Create symlinks to scripts in ~/.local/bin
setup_scripts() {
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    # Symlink scripts
    ln -sf "$CURRENT_DIR/scripts/timer.sh" "$bin_dir/tmux-timer"
    ln -sf "$CURRENT_DIR/scripts/timer-display.sh" "$bin_dir/tmux-timer-display"
    ln -sf "$CURRENT_DIR/scripts/timer-watcher.sh" "$bin_dir/tmux-timer-watcher"
    ln -sf "$CURRENT_DIR/scripts/status-right.sh" "$bin_dir/tmux-status-right"
    ln -sf "$CURRENT_DIR/scripts/activity-monitor.sh" "$bin_dir/tmux-activity-monitor"
}

main() {
    setup_config
    setup_scripts
    setup_bindings
    setup_status
}

main
