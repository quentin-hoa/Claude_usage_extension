#!/bin/bash
set -e

EXTENSION_UUID="claude-usage-stats@community"
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"
SCRIPT_DIR="$HOME/.local/bin"
SHARED_DIR="$HOME/.local/share/claude-usage-stats"

echo "==> Installing Claude Usage Stats for Ubuntu/GNOME..."

# Check GNOME Shell
if ! command -v gnome-shell &>/dev/null; then
    echo "ERROR: GNOME Shell not found. This extension requires GNOME."
    exit 1
fi

GNOME_VERSION=$(gnome-shell --version | grep -oP '\d+' | head -1)
if [ "$GNOME_VERSION" -lt 45 ]; then
    echo "ERROR: GNOME Shell $GNOME_VERSION not supported. Need >= 45."
    exit 1
fi

# Check Claude CLI credentials
CREDS="$HOME/.claude/.credentials.json"
if [ ! -f "$CREDS" ]; then
    echo "ERROR: Claude credentials not found at $CREDS"
    echo "       Install Claude Code CLI (https://claude.ai/code) and log in first."
    exit 1
fi

# Install shared fetch script
mkdir -p "$SHARED_DIR"
cp "$(dirname "$0")/../shared/fetch_usage.py" "$SHARED_DIR/fetch_usage.py"

# Install stats shell script
mkdir -p "$SCRIPT_DIR"
cat > "$SCRIPT_DIR/claude-usage-stats.sh" <<EOF
#!/bin/bash
python3 "$SHARED_DIR/fetch_usage.py"
EOF
chmod +x "$SCRIPT_DIR/claude-usage-stats.sh"

# Install GNOME extension
mkdir -p "$EXTENSION_DIR"
cp "$(dirname "$0")"/extension/* "$EXTENSION_DIR/"

echo "==> Files installed."
echo ""
echo "==> Next steps:"
echo "    1. Reload GNOME Shell:"
echo "       - On X11:  Press Alt+F2, type 'r', press Enter"
echo "       - On Wayland: Log out and log back in"
echo ""
echo "    2. Enable the extension:"
echo "       gnome-extensions enable $EXTENSION_UUID"
echo ""
echo "    Done! The Claude usage indicator will appear in your top bar."
