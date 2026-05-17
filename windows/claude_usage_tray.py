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

# Locate fetch_usage.py:
# 1. Installed location (preferred): %USERPROFILE%\.local\share\claude-usage-stats\
# 2. Fallback: sibling shared/ folder in the repo (for running directly from repo)
_INSTALLED = Path.home() / ".local" / "share" / "claude-usage-stats"
_REPO_SHARED = Path(__file__).parent.parent / "shared"

if (_INSTALLED / "fetch_usage.py").exists():
    sys.path.insert(0, str(_INSTALLED))
elif (_REPO_SHARED / "fetch_usage.py").exists():
    sys.path.insert(0, str(_REPO_SHARED))
else:
    print("Cannot find fetch_usage.py. Run install.bat first.")
    sys.exit(1)

try:
    from fetch_usage import get_stats
except ImportError as e:
    print(f"Import error: {e}")
    sys.exit(1)

CLAUDE_USAGE_URL = "https://claude.ai/settings/usage"
REFRESH_SECONDS = 60
ICON_SIZE = 64


def make_icon(sess_pct: int, week_pct: int) -> Image.Image:
    img = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    draw.ellipse([2, 2, ICON_SIZE - 2, ICON_SIZE - 2], fill="#1a1a2e")

    max_pct = max(sess_pct, week_pct)
    if max_pct >= 90:
        color = "#ff4444"
    elif max_pct >= 70:
        color = "#ffaa00"
    else:
        color = "#DA7756"

    if sess_pct > 0:
        angle = int(360 * min(sess_pct, 100) / 100)
        draw.arc(
            [6, 6, ICON_SIZE - 6, ICON_SIZE - 6],
            start=-90, end=-90 + angle,
            fill=color, width=6,
        )

    text = f"{sess_pct}%"
    font = None
    for font_name in ("arial.ttf", "Arial.ttf", "segoeui.ttf", "calibri.ttf"):
        try:
            font = ImageFont.truetype(font_name, 16)
            break
        except Exception:
            continue
    if font is None:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((ICON_SIZE - tw) // 2, (ICON_SIZE - th) // 2), text, fill="#e0e0e0", font=font)
    return img


class ClaudeUsageTray:
    def __init__(self):
        self._stats = None
        self._error = None
        self._icon = None
        self._lock = threading.Lock()

    def _fetch(self):
        try:
            stats = get_stats()
            with self._lock:
                self._stats = stats
                self._error = None
        except Exception as e:
            with self._lock:
                self._error = str(e)
                self._stats = None

    def _build_menu(self):
        with self._lock:
            stats = self._stats
            error = self._error

        items = []
        if error:
            items.append(pystray.MenuItem(f"Error: {error}", None, enabled=False))
        elif stats:
            sp = stats["session_pct"]
            wp = stats["weekly_pct"]
            sr = stats["session_resets_in"] or "?"
            wr = stats["weekly_resets_in"] or "?"
            items += [
                pystray.MenuItem("── USAGE ──", None, enabled=False),
                pystray.MenuItem(f"Session (5hr):   {sp}%  —  resets in {sr}", None, enabled=False),
                pystray.MenuItem(f"Weekly (7 day):  {wp}%  —  resets in {wr}", None, enabled=False),
            ]
        else:
            items.append(pystray.MenuItem("Loading...", None, enabled=False))

        items += [
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Manage usage on claude.ai", self._open_browser),
            pystray.MenuItem("Refresh now", self._on_refresh),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem("Quit", self._quit),
        ]
        return pystray.Menu(*items)

    def _open_browser(self, icon=None, item=None):
        webbrowser.open(CLAUDE_USAGE_URL)

    def _on_refresh(self, icon=None, item=None):
        threading.Thread(target=self._fetch_and_update, daemon=True).start()

    def _fetch_and_update(self):
        self._fetch()
        self._apply_to_icon()

    def _quit(self, icon=None, item=None):
        self._icon.stop()

    def _apply_to_icon(self):
        if self._icon is None:
            return
        with self._lock:
            stats = self._stats
        if stats:
            img = make_icon(stats["session_pct"], stats["weekly_pct"])
            title = f"Claude — Session: {stats['session_pct']}%  Weekly: {stats['weekly_pct']}%"
        else:
            img = make_icon(0, 0)
            title = "Claude Usage — Error (hover for details)"
        self._icon.icon = img
        self._icon.title = title
        self._icon.menu = self._build_menu()

    def _refresh_loop(self):
        while True:
            time.sleep(REFRESH_SECONDS)
            self._fetch_and_update()

    def run(self):
        self._fetch()
        with self._lock:
            stats = self._stats
        sp = stats["session_pct"] if stats else 0
        wp = stats["weekly_pct"] if stats else 0

        self._icon = pystray.Icon(
            "claude-usage",
            make_icon(sp, wp),
            title="Claude Usage Stats",
            menu=self._build_menu(),
        )
        threading.Thread(target=self._refresh_loop, daemon=True).start()
        self._icon.run()


if __name__ == "__main__":
    ClaudeUsageTray().run()
