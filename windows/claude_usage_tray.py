"""
Claude Usage Stats — Windows System Tray
Reads OAuth token from %USERPROFILE%\\.claude\\.credentials.json
Run: pythonw claude_usage_tray.py  (or python claude_usage_tray.py)
"""
import json
import os
import sys
import threading
import time
import webbrowser
from pathlib import Path

try:
    import pystray
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Missing dependencies. Run: pip install pystray pillow")
    sys.exit(1)

# Add shared fetch_usage module
sys.path.insert(0, str(Path(__file__).parent.parent / "shared"))
try:
    from fetch_usage import get_stats
except ImportError:
    print("Cannot find shared/fetch_usage.py. Run from the repo root or install correctly.")
    sys.exit(1)

CLAUDE_USAGE_URL = "https://claude.ai/settings/usage"
REFRESH_SECONDS = 60
ICON_SIZE = 64


def make_icon(sess_pct: int, week_pct: int) -> Image.Image:
    """Draw a small icon with the session % shown."""
    img = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background circle
    draw.ellipse([2, 2, ICON_SIZE - 2, ICON_SIZE - 2], fill="#1a1a2e")

    # Pick color based on highest usage
    max_pct = max(sess_pct, week_pct)
    if max_pct >= 90:
        color = "#ff4444"
    elif max_pct >= 70:
        color = "#ffaa00"
    else:
        color = "#DA7756"

    # Arc showing session usage
    if sess_pct > 0:
        angle = int(360 * min(sess_pct, 100) / 100)
        draw.arc([6, 6, ICON_SIZE - 6, ICON_SIZE - 6], start=-90, end=-90 + angle,
                 fill=color, width=6)

    # Text: session %
    text = f"{sess_pct}%"
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except Exception:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text(
        ((ICON_SIZE - tw) // 2, (ICON_SIZE - th) // 2),
        text,
        fill="#e0e0e0",
        font=font,
    )
    return img


class ClaudeUsageTray:
    def __init__(self):
        self._stats = None
        self._error = None
        self._icon = None

    def _fetch(self):
        try:
            self._stats = get_stats()
            self._error = None
        except Exception as e:
            self._error = str(e)
            self._stats = None

    def _build_menu(self):
        items = []

        if self._error:
            items.append(pystray.MenuItem(f"Error: {self._error}", None, enabled=False))
        elif self._stats:
            s = self._stats
            items += [
                pystray.MenuItem("USAGE", None, enabled=False),
                pystray.MenuItem(
                    f"Session (5hr):  {s['session_pct']}%  — resets in {s['session_resets_in'] or '?'}",
                    None, enabled=False
                ),
                pystray.MenuItem(
                    f"Weekly (7 day): {s['weekly_pct']}%  — resets in {s['weekly_resets_in'] or '?'}",
                    None, enabled=False
                ),
            ]
        else:
            items.append(pystray.MenuItem("Loading...", None, enabled=False))

        items += [
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Manage usage on claude.ai", self._open_browser),
            pystray.MenuItem("Refresh now", self._refresh),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Quit", self._quit),
        ]
        return pystray.Menu(*items)

    def _open_browser(self, icon=None, item=None):
        webbrowser.open(CLAUDE_USAGE_URL)

    def _refresh(self, icon=None, item=None):
        self._fetch()
        self._update_icon()

    def _quit(self, icon=None, item=None):
        self._icon.stop()

    def _update_icon(self):
        if self._stats:
            img = make_icon(self._stats["session_pct"], self._stats["weekly_pct"])
            sp = self._stats["session_pct"]
            wp = self._stats["weekly_pct"]
            title = f"Claude Usage — Session: {sp}%  Weekly: {wp}%"
        else:
            img = make_icon(0, 0)
            title = "Claude Usage — Error"

        self._icon.icon = img
        self._icon.title = title
        self._icon.menu = self._build_menu()

    def _refresh_loop(self):
        while True:
            time.sleep(REFRESH_SECONDS)
            self._fetch()
            self._update_icon()

    def run(self):
        self._fetch()
        img = make_icon(
            self._stats["session_pct"] if self._stats else 0,
            self._stats["weekly_pct"] if self._stats else 0,
        )
        self._icon = pystray.Icon(
            "claude-usage",
            img,
            title="Claude Usage Stats",
            menu=self._build_menu(),
        )
        t = threading.Thread(target=self._refresh_loop, daemon=True)
        t.start()
        self._icon.run()


if __name__ == "__main__":
    ClaudeUsageTray().run()
