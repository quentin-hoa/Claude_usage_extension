"""
Fetches Claude usage stats from claude.ai/api/oauth/usage
Reads OAuth token from ~/.claude/.credentials.json (never hardcoded)
"""
import json
import os
import sys
import urllib.request
from datetime import datetime, timezone


CREDENTIALS_PATH = os.path.expanduser("~/.claude/.credentials.json")
API_URL = "https://claude.ai/api/oauth/usage"
CLAUDE_USAGE_PAGE = "https://claude.ai/settings/usage"


def load_token():
    try:
        with open(CREDENTIALS_PATH) as f:
            creds = json.load(f)
        token = creds["claudeAiOauth"]["accessToken"]
        if not token:
            raise ValueError("Empty token")
        return token
    except FileNotFoundError:
        raise RuntimeError(
            f"Credentials not found at {CREDENTIALS_PATH}. "
            "Make sure Claude Code CLI is installed and you are logged in."
        )
    except KeyError:
        raise RuntimeError(
            "Unexpected credentials format. "
            "Re-run 'claude' CLI and log in again."
        )


def fetch_usage(token):
    req = urllib.request.Request(
        API_URL,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "anthropic-client-name": "claude-code",
            "anthropic-client-version": "2.1.0",
            "User-Agent": "claude-code/2.1.0",
        },
    )
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())


def time_until(iso_str):
    if not iso_str:
        return None
    try:
        dt = datetime.fromisoformat(iso_str)
        delta = dt - datetime.now(timezone.utc)
        total_seconds = int(delta.total_seconds())
        if total_seconds <= 0:
            return "now"
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        days = hours // 24
        if days >= 1:
            remaining_hours = hours % 24
            return f"{days}d {remaining_hours}h" if remaining_hours else f"{days}d"
        if hours >= 1:
            return f"{hours}h {minutes}m"
        return f"{minutes}m"
    except Exception:
        return None


def get_stats():
    """Returns dict with session_pct, session_resets_in, weekly_pct, weekly_resets_in."""
    token = load_token()
    data = fetch_usage(token)

    fh = data.get("five_hour") or {}
    sd = data.get("seven_day") or {}

    return {
        "session_pct": round(fh.get("utilization", 0)),
        "session_resets_in": time_until(fh.get("resets_at")),
        "weekly_pct": round(sd.get("utilization", 0)),
        "weekly_resets_in": time_until(sd.get("resets_at")),
    }


if __name__ == "__main__":
    try:
        stats = get_stats()
        print(json.dumps(stats, indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)
