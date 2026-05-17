#!/bin/bash
set -e

SHARED_DIR="$HOME/.local/share/claude-usage-stats"
XBAR_PLUGIN_DIR="$HOME/Library/Application Support/xbar/plugins"

echo "==> Installing Claude Usage Stats for macOS..."

# Check Python 3
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Install it via: brew install python"
    exit 1
fi

# Check Claude credentials
CREDS="$HOME/.claude/.credentials.json"
if [ ! -f "$CREDS" ]; then
    echo "ERROR: Claude credentials not found at $CREDS"
    echo "       Install Claude Code CLI (https://claude.ai/code) and log in first."
    exit 1
fi

# Install shared fetch script
mkdir -p "$SHARED_DIR"
cp "$(dirname "$0")/../shared/fetch_usage.py" "$SHARED_DIR/fetch_usage.py"

# Check xbar is installed
if [ ! -d "$XBAR_PLUGIN_DIR" ]; then
    echo ""
    echo "  xbar not found. Install it first:"
    echo "  brew install --cask xbar"
    echo "  Then open xbar once to create the plugins folder, and re-run this script."
    echo ""
    exit 1
fi

# Install xbar plugin
cp "$(dirname "$0")/claude-usage.1m.sh" "$XBAR_PLUGIN_DIR/claude-usage.1m.sh"
chmod +x "$XBAR_PLUGIN_DIR/claude-usage.1m.sh"

echo ""
echo "==> Installed! Refresh xbar (click any plugin > Refresh All) or restart it."
echo "    The Claude ◆ indicator will appear in your macOS menu bar."
