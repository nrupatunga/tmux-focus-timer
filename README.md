# tmux-focus-timer

Pomodoro-style focus timer for tmux with distraction detection and screen time tracking.

## Features

- Multiple timers (up to 3 concurrent)
- Progress bar in status bar: `●●●○○ work`
- Pause/resume/rename support
- Distraction watcher with popup alerts
- Screen time tracking with hourly stats

## Installation

```bash
set -g @plugin 'nrupatunga/tmux-focus-timer'
```

Then `prefix + I` to install, or manually:

```bash
git clone https://github.com/nrupatunga/tmux-focus-timer ~/.tmux/plugins/tmux-focus-timer
~/.tmux/plugins/tmux-focus-timer/setup.sh
```

## Usage

```bash
tt 25m work          # Start 25min timer
tt stop              # Stop all timers
tt pause 1           # Pause timer #1
tt resume 1          # Resume timer #1
tt rename wokr work  # Rename by label
tt list              # List active timers
tt focus 25m         # Timer + distraction watcher

# Screen time tracking
tt monitorme         # Start tracking
tt stopmonitor       # Stop tracking
tt stats             # Show today's stats
tt stats 2026-01-02  # Show specific day
```

## Status Bar

Add `#(~/.local/bin/tmux-status-right)` to your `status-right` configuration:

```bash
set -g status-right "#(~/.local/bin/tmux-status-right)%H:%M"
```

**Note:** If you use a tmux theme (e.g., falcon, dracula, catppuccin), the theme file may override `status-right`. In that case, edit the theme's config file instead of `~/.tmux.conf`. Check which file sets your status-right with:

```bash
tmux show-option -g status-right
```

## Configuration

Edit `~/.config/tmux-timer/distractions.conf` to customize distraction detection:

```bash
# Seconds to wait before showing warning (grace period)
GRACE_PERIOD=30

# Sites to block (matches window title, one per line)
youtube
twitter
reddit
netflix
```

When a timer is running and you visit a blocked site, you get a 30s grace period before the popup warning appears.

## Dependencies

```bash
sudo apt install xdotool x11-utils libnotify-bin
```

## License

MIT
