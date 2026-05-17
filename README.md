# Claude Usage Stats

A lightweight system bar overlay that shows your **Claude AI session and weekly usage** in real time — for Ubuntu, macOS, and Windows.

Inspired by the usage panel in the Claude Code VS Code extension.

---

## Preview

> Screenshots coming soon — contributions welcome!

| Platform | Bar indicator | Popup / Menu |
|----------|--------------|--------------|
| Ubuntu (GNOME) | *(placeholder)* | *(placeholder)* |
| macOS (xbar) | *(placeholder)* | *(placeholder)* |
| Windows (tray) | *(placeholder)* | *(placeholder)* |

The popup shows:

```
USAGE
─────────────────────────────────────
Session (5hr)                      50%
████████████░░░░░░░░░░░░░░░░░░░░
Resets in 3h 0m

─────────────────────────────────────
Weekly (7 day)                      5%
██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Resets in 1d 6h

─────────────────────────────────────
Manage usage on claude.ai
```

---

## How it works

1. Reads your **OAuth access token** from `~/.claude/.credentials.json`  
   (created automatically by the Claude Code CLI when you log in)
2. Calls `https://claude.ai/api/oauth/usage` — the same endpoint used by the VS Code extension
3. Displays the returned `five_hour` (session) and `seven_day` (weekly) utilisation percentages

**Your token never leaves your machine.** No data is sent anywhere except the official `claude.ai` API.

---

## Security

| What | Detail |
|------|--------|
| Token storage | `~/.claude/.credentials.json` — on your disk only, never in this repo |
| Network calls | Only to `claude.ai` (Anthropic's own servers) |
| `.gitignore` | Blocks any `*.credentials.json` file from being committed |
| Open source | All fetch logic is in `shared/fetch_usage.py` — readable in 60 lines |

> **Never share your `~/.claude/.credentials.json` file.** This repo contains no credentials.

---

## Prerequisites (all platforms)

- **Claude Code CLI** installed and logged in  
  → [https://claude.ai/code](https://claude.ai/code)  
  After install, run `claude` once to authenticate. This creates `~/.claude/.credentials.json`.

- **Python 3.8+** (`python3 --version` to check)

---

## Installation

### Ubuntu / GNOME (GNOME Shell 45+)

**Requirements:** Ubuntu 22.04+ with GNOME Shell 45 or 46

```bash
git clone https://github.com/YOUR_USERNAME/Claude_usage_extension_Ubuntu.git
cd Claude_usage_extension_Ubuntu
bash ubuntu/install.sh
```

Then reload GNOME Shell:

- **X11 session:** Press `Alt + F2`, type `r`, press `Enter`
- **Wayland session:** Log out and log back in

Enable the extension:

```bash
gnome-extensions enable claude-usage-stats@community
```

The `◆ 50% | 5%` indicator will appear in the top-right of your panel. Click it to open the usage popup.

---

### macOS (via xbar)

**Requirements:** macOS 11+ · [xbar](https://xbarapp.com/) installed

```bash
# Install xbar (if not already installed)
brew install --cask xbar

# Open xbar once to initialise the plugins folder, then:
git clone https://github.com/YOUR_USERNAME/Claude_usage_extension_Ubuntu.git
cd Claude_usage_extension_Ubuntu
bash macos/install.sh
```

Refresh xbar: click any menu bar plugin → **Refresh All**.

The `◆ 50% | 5%` indicator will appear in your macOS menu bar.

---

### Windows (system tray)

**Requirements:** Windows 10/11 · Python 3.8+

```batch
git clone https://github.com/YOUR_USERNAME/Claude_usage_extension_Ubuntu.git
cd Claude_usage_extension_Ubuntu
windows\install.bat
```

The install script:
1. Installs `pystray` and `Pillow` via pip
2. Creates a startup entry so the tray icon launches automatically on login

To start immediately without rebooting:

```batch
pythonw windows\claude_usage_tray.py
```

Right-click the tray icon to see your usage or open `claude.ai/settings/usage`.

---

## Uninstall

### Ubuntu
```bash
gnome-extensions disable claude-usage-stats@community
rm -rf ~/.local/share/gnome-shell/extensions/claude-usage-stats@community
rm ~/.local/bin/claude-usage-stats.sh
rm -rf ~/.local/share/claude-usage-stats
```

### macOS
```bash
rm "$HOME/Library/Application Support/xbar/plugins/claude-usage.1m.sh"
rm -rf ~/.local/share/claude-usage-stats
```

### Windows
Delete `claude-usage-tray.vbs` from `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`  
and optionally `pip uninstall pystray Pillow`.

---

## Configuration

The refresh interval and icon behaviour are configurable:

| File | Variable | Default |
|------|----------|---------|
| `ubuntu/extension/extension.js` | `REFRESH_SECONDS` | `60` |
| `macos/claude-usage.1m.sh` | filename (`1m`) | 1 minute |
| `windows/claude_usage_tray.py` | `REFRESH_SECONDS` | `60` |

For macOS, rename the plugin file to change the refresh interval:  
`claude-usage.30s.sh` = every 30 seconds, `claude-usage.5m.sh` = every 5 minutes.

---

## Troubleshooting

**"Credentials not found"**  
→ Run `claude` in your terminal and complete the login flow. The file `~/.claude/.credentials.json` must exist.

**Extension doesn't appear (Ubuntu)**  
→ Make sure you reloaded GNOME Shell after install, then ran `gnome-extensions enable claude-usage-stats@community`.

**Error / spinner that never resolves**  
→ Test the fetch script directly:
```bash
python3 shared/fetch_usage.py
# Should print JSON like: {"session_pct": 50, "weekly_pct": 5, ...}
```
If it errors, your token may be expired. Re-run `claude` to refresh it.

**Token expired**  
→ Simply open and use `claude` CLI once. It auto-refreshes the token.

---

## File structure

```
Claude_usage_extension_Ubuntu/
├── shared/
│   └── fetch_usage.py          # Core API fetch logic (used by all platforms)
├── ubuntu/
│   ├── extension/              # GNOME Shell extension files
│   │   ├── extension.js
│   │   ├── metadata.json
│   │   ├── stylesheet.css
│   │   └── claude-logo.svg
│   ├── claude-usage-stats.sh   # Wrapper script called by the extension
│   └── install.sh
├── macos/
│   ├── claude-usage.1m.sh      # xbar plugin
│   └── install.sh
├── windows/
│   ├── claude_usage_tray.py    # Python system tray app
│   ├── requirements.txt
│   └── install.bat
├── .gitignore                  # Blocks credentials from being committed
└── README.md
```

---

## Contributing

PRs welcome — especially:
- Screenshots for the preview table
- Support for other desktop environments (KDE Plasma, etc.)
- A SwiftBar variant for macOS

---

## License

MIT
