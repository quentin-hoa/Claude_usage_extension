#!/bin/bash
# <xbar.title>Claude Usage Stats</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Community</xbar.author>
# <xbar.author.github>YOUR_GITHUB_USERNAME</xbar.author.github>
# <xbar.desc>Shows Claude AI session and weekly usage in the macOS menu bar</xbar.desc>
# <xbar.dependencies>python3</xbar.dependencies>
# <xbar.refreshTime>1m</xbar.refreshTime>

SHARED_DIR="$HOME/.local/share/claude-usage-stats"
FETCH_SCRIPT="$SHARED_DIR/fetch_usage.py"

if [ ! -f "$FETCH_SCRIPT" ]; then
    echo "Claude ⚠ | color=#ff5555"
    echo "---"
    echo "fetch_usage.py not found. Run install.sh first. | color=#ff5555"
    exit 1
fi

# Parse all 4 values in one python call (one value per line for safe space handling)
PARSED=$(python3 - <<PYEOF 2>/dev/null
import sys, os
sys.path.insert(0, "$SHARED_DIR")
from fetch_usage import get_stats
try:
    s = get_stats()
    print(int(round(s.get("session_pct", 0))))
    print(int(round(s.get("weekly_pct", 0))))
    print(s.get("session_resets_in") or "unknown")
    print(s.get("weekly_resets_in") or "unknown")
except Exception as e:
    sys.exit(1)
PYEOF
)

if [ $? -ne 0 ] || [ -z "$PARSED" ]; then
    echo "Claude ⚠ | color=#ff5555"
    echo "---"
    echo "Error fetching usage | color=#ff5555"
    echo "Check that Claude CLI is installed and logged in | color=#888899 size=11"
    echo "Test: python3 $FETCH_SCRIPT | color=#888899 size=11"
    exit 1
fi

SESS_PCT=$(echo "$PARSED" | sed -n '1p')
WEEK_PCT=$(echo "$PARSED" | sed -n '2p')
SESS_RESET=$(echo "$PARSED" | sed -n '3p')
WEEK_RESET=$(echo "$PARSED" | sed -n '4p')

# Defaults in case parsing produced empty lines
SESS_PCT=${SESS_PCT:-0}
WEEK_PCT=${WEEK_PCT:-0}
SESS_RESET=${SESS_RESET:-unknown}
WEEK_RESET=${WEEK_RESET:-unknown}

# Color based on highest usage
MAX_PCT=$SESS_PCT
[ "$WEEK_PCT" -gt "$SESS_PCT" ] 2>/dev/null && MAX_PCT=$WEEK_PCT

if [ "$MAX_PCT" -ge 90 ] 2>/dev/null; then
    COLOR="#ff4444"
elif [ "$MAX_PCT" -ge 70 ] 2>/dev/null; then
    COLOR="#ffaa00"
else
    COLOR="#DA7756"
fi

# Build ASCII progress bars using a loop (avoids seq incompatibility)
make_bar() {
    local pct=$1
    local filled=$(( pct * 20 / 100 ))
    local empty=$(( 20 - filled ))
    local bar="" i
    for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
    for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done
    echo "$bar"
}

SESS_BAR=$(make_bar "$SESS_PCT")
WEEK_BAR=$(make_bar "$WEEK_PCT")

# Menu bar: use · instead of | (xbar uses | as attribute separator)
echo "◆ ${SESS_PCT}% · ${WEEK_PCT}% | color=$COLOR"

echo "---"
echo "USAGE | color=#aaaacc size=11"
echo "---"
echo "Session (5hr)              ${SESS_PCT}% | color=#e0e0e0 size=13"
echo "$SESS_BAR | font=Menlo size=10 color=#e05c3a"
echo "Resets in ${SESS_RESET} | color=#888899 size=11"
echo "---"
echo "Weekly (7 day)             ${WEEK_PCT}% | color=#e0e0e0 size=13"
echo "$WEEK_BAR | font=Menlo size=10 color=#e05c3a"
echo "Resets in ${WEEK_RESET} | color=#888899 size=11"
echo "---"
echo "Manage usage on claude.ai | href=https://claude.ai/settings/usage color=#cc8866"
