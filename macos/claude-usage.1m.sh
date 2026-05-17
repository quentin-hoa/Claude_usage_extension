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
    echo "Claude ⚠"
    echo "---"
    echo "fetch_usage.py not found | color=#ff5555"
    echo "Run install.sh first | color=#888888"
    exit 1
fi

OUTPUT=$(python3 "$FETCH_SCRIPT" 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$OUTPUT" ]; then
    echo "Claude ⚠"
    echo "---"
    echo "Error fetching usage | color=#ff5555"
    echo "Check ~/.claude/.credentials.json exists | color=#888888"
    exit 1
fi

SESS_PCT=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['session_pct'])" 2>/dev/null)
WEEK_PCT=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['weekly_pct'])" 2>/dev/null)
SESS_RESET=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['session_resets_in'] or 'unknown')" 2>/dev/null)
WEEK_RESET=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['weekly_resets_in'] or 'unknown')" 2>/dev/null)

# Color based on highest usage
MAX_PCT=$SESS_PCT
if [ "$WEEK_PCT" -gt "$SESS_PCT" ]; then MAX_PCT=$WEEK_PCT; fi

if [ "$MAX_PCT" -ge 90 ]; then
    COLOR="#ff4444"
elif [ "$MAX_PCT" -ge 70 ]; then
    COLOR="#ffaa00"
else
    COLOR="#DA7756"
fi

# --- Menu bar line ---
echo "◆ ${SESS_PCT}% | ${WEEK_PCT}% | color=$COLOR"

# --- Dropdown ---
echo "---"
echo "USAGE | color=#aaaacc size=11"
echo "---"

# Session bar (ASCII progress, 20 chars wide)
SESS_FILLED=$(( SESS_PCT * 20 / 100 ))
SESS_EMPTY=$(( 20 - SESS_FILLED ))
SESS_BAR=$(printf '█%.0s' $(seq 1 $SESS_FILLED 2>/dev/null))$(printf '░%.0s' $(seq 1 $SESS_EMPTY 2>/dev/null))
echo "Session (5hr)                  ${SESS_PCT}% | color=#e0e0e0 size=13"
echo "$SESS_BAR | font=Menlo size=10 color=#e05c3a"
echo "Resets in ${SESS_RESET} | color=#888899 size=11"
echo "---"

# Weekly bar
WEEK_FILLED=$(( WEEK_PCT * 20 / 100 ))
WEEK_EMPTY=$(( 20 - WEEK_FILLED ))
WEEK_BAR=$(printf '█%.0s' $(seq 1 $WEEK_FILLED 2>/dev/null))$(printf '░%.0s' $(seq 1 $WEEK_EMPTY 2>/dev/null))
echo "Weekly (7 day)                 ${WEEK_PCT}% | color=#e0e0e0 size=13"
echo "$WEEK_BAR | font=Menlo size=10 color=#e05c3a"
echo "Resets in ${WEEK_RESET} | color=#888899 size=11"
echo "---"

echo "Manage usage on claude.ai | href=https://claude.ai/settings/usage color=#cc8866"
