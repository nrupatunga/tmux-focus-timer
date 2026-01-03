#!/usr/bin/env bash

# tmux-focus-timer setup script
# Installs dependencies and configures aliases

set -e

echo "Installing dependencies..."
sudo apt install -y xdotool x11-utils libnotify-bin

echo "Setting up tt alias..."
SHELL_RC=""
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "alias tt=" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# tmux-focus-timer" >> "$SHELL_RC"
        echo "alias tt='~/.local/bin/tmux-timer'" >> "$SHELL_RC"
        echo "Added tt alias to $SHELL_RC"
    else
        echo "tt alias already exists in $SHELL_RC"
    fi
fi

echo "Running plugin setup..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/focus-timer.tmux"

echo ""
echo "Setup complete! Restart your shell or run: source $SHELL_RC"
echo "Then use: tt 25m work"
