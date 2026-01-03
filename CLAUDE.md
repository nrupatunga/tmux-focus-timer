# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

tmux-focus-timer is a Pomodoro-style focus timer plugin for tmux with distraction detection. It supports up to 3 concurrent timers with pause/resume, displays progress bars in the tmux status bar, and can monitor for distracting websites.

## Architecture

### Entry Point
- `focus-timer.tmux` - TPM plugin entry point, sets up key bindings, creates config directory, and symlinks scripts to `~/.local/bin/`

### Core Scripts (in `scripts/`)
- `timer.sh` - Main timer management (start/stop/pause/resume/list). Timer state stored in `/tmp/tmux-timers/*.timer` files
- `timer-display.sh` - Renders progress bars for status bar display. Uses Unicode block characters (█░) with color coding
- `timer-watcher.sh` - Background daemon that detects distracting sites via `xdotool`/`xprop` window titles. Shows tmux popup + flashes status bar on distraction
- `status-right.sh` - Wrapper for status-right integration

### Data Flow
1. User runs `tt 25m work` → `timer.sh` creates `/tmp/tmux-timers/1.timer` with end_time, duration, message
2. tmux status bar calls `tmux-status-right` → `timer-display.sh` reads timer files, renders progress
3. If focus mode active, `timer-watcher.sh` runs in background checking window titles against `~/.config/tmux-timer/distractions.conf`

### Timer State Format
Timer files (`/tmp/tmux-timers/{1,2,3}.timer`) contain sourced bash variables:
```bash
end_time=1234567890
duration=1500
message="work"
paused=0
```

## Commands

Install plugin (creates symlinks):
```bash
./focus-timer.tmux
```

Timer commands (via `tt` alias or `tmux-timer`):
```bash
tt 25m work       # Start timer with label
tt focus 25m      # Start timer + distraction watcher
tt pause 1        # Pause timer #1
tt resume 1       # Resume timer #1
tt stop           # Stop all timers
tt list           # List active timers
```

## Dependencies
- `xdotool` - Required for distraction detection (reads active window)
- `xprop` - Used with xdotool to get window names
- `notify-send` - Optional desktop notifications

## Code Updates
- Make sure to update readme always when new functionality or notifications are added
- always keep the code simple and number of lines less
