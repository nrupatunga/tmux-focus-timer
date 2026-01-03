# tmux-focus-timer

A Pomodoro-style focus timer plugin for tmux with distraction detection.

## Features

- Multiple timers (up to 3 concurrent)
- Progress bar in status bar
- Pause/resume support
- Distraction watcher (detects YouTube, Twitter, Netflix, etc.)
- Configurable grace period before warning
- Flash + popup notification when distracted

## Installation

### With TPM (recommended)

Add to your `~/.tmux.conf`:

```bash
set -g @plugin 'yourusername/tmux-focus-timer'
```

Then press `prefix + I` to install.

### Manual

```bash
git clone https://github.com/yourusername/tmux-focus-timer ~/.tmux/plugins/tmux-focus-timer
```

Add to `~/.tmux.conf`:

```bash
run-shell ~/.tmux/plugins/tmux-focus-timer/focus-timer.tmux
```

## Usage

### Commands

```bash
tt 25m work       # Start 25min timer with label "work"
tt 10m            # Start 10min timer
tt stop           # Stop all timers
tt stop 1         # Stop timer #1
tt pause 1        # Pause timer #1
tt resume 1       # Resume timer #1
tt list           # List active timers
tt focus 25m      # Start timer + distraction watcher
```

### Status Bar

Add to your status-right in tmux.conf:

```bash
set -g status-right "#(~/.local/bin/tmux-status-right)#[fg=#787882]| #[fg=white]%H:%M"
```

### Key Binding

Default: `prefix + T` starts a 25m focus timer.

Customize in tmux.conf:

```bash
set -g @focus-timer-key "F"  # Use prefix + F instead
```

## Configuration

Edit `~/.config/tmux-timer/distractions.conf`:

```bash
# Grace period before warning (seconds)
GRACE_PERIOD=30

# Distracting sites (one per line)
youtube
x.com
twitter
netflix
reddit
```

## Dependencies

- `xdotool` (for distraction detection)
- `dunst` or notification daemon (optional, for desktop notifications)

```bash
sudo apt install xdotool dunst
```

## License

MIT
