import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

const CLAUDE_USAGE_URL = 'https://claude.ai/settings/usage';
const REFRESH_SECONDS = 60;

const COLORS = {
    bar_fill:     '#e05c3a',
    bar_bg:       '#2e2e4e',
    text_primary: '#e0e0e0',
    text_dim:     '#888899',
    link:         '#cc8866',
    header:       '#aaaabb',
    bg:           '#1a1a2e',
    border:       '#2e2e4e',
    error:        '#ff5555',
};

function pctColor(pct) {
    if (pct >= 90) return '#ff4444';
    if (pct >= 70) return '#ffaa00';
    return COLORS.bar_fill;
}

function makeProgressBar(pct, width = 264) {
    const fillWidth = Math.max(2, Math.round(width * Math.min(pct, 100) / 100));
    const container = new St.BoxLayout({
        style: `width: ${width}px; height: 6px; background-color: ${COLORS.bar_bg}; border-radius: 3px;`,
    });
    const fill = new St.Widget({
        style: `width: ${fillWidth}px; height: 6px; background-color: ${pctColor(pct)}; border-radius: 3px;`,
    });
    container.add_child(fill);
    return container;
}

function makeUsageBlock(label, pct, resetsIn) {
    const box = new St.BoxLayout({vertical: true, style: 'spacing: 7px; padding: 6px 0;'});

    const topRow = new St.BoxLayout();
    const lbl = new St.Label({
        text: label,
        style: `color: ${COLORS.text_primary}; font-size: 13px; font-weight: bold;`,
    });
    const spacer = new St.Widget({x_expand: true});
    const pctLbl = new St.Label({
        text: `${pct}%`,
        style: `color: ${COLORS.text_primary}; font-size: 13px; font-weight: bold;`,
    });
    topRow.add_child(lbl);
    topRow.add_child(spacer);
    topRow.add_child(pctLbl);

    const resetLbl = new St.Label({
        text: resetsIn ? `Resets in ${resetsIn}` : 'Reset time unknown',
        style: `color: ${COLORS.text_dim}; font-size: 11px;`,
    });

    box.add_child(topRow);
    box.add_child(makeProgressBar(pct));
    box.add_child(resetLbl);
    return box;
}

function makeDivider() {
    return new St.Widget({
        style: `height: 1px; background-color: ${COLORS.border}; margin: 4px 0;`,
    });
}

export default class ClaudeStatsExtension extends Extension {
    enable() {
        this._statsScript = GLib.get_home_dir() + '/.local/bin/claude-usage-stats.sh';

        this._indicator = new PanelMenu.Button(0.0, 'Claude Stats', false);

        const topBox = new St.BoxLayout({
            style: 'spacing: 5px;',
            y_align: Clutter.ActorAlign.CENTER,
        });

        const iconPath = this.path + '/claude-logo.svg';
        const gicon = new Gio.FileIcon({file: Gio.File.new_for_path(iconPath)});
        this._logo = new St.Icon({gicon, icon_size: 14, y_align: Clutter.ActorAlign.CENTER});

        this._topLabel = new St.Label({
            text: '-- | --',
            y_align: Clutter.ActorAlign.CENTER,
            style: `font-size: 11px; font-weight: bold; color: ${COLORS.text_dim};`,
        });

        topBox.add_child(this._logo);
        topBox.add_child(this._topLabel);
        this._indicator.add_child(topBox);

        this._buildMenu();
        Main.panel.addToStatusArea('claude-stats', this._indicator, 0, 'right');

        this._update();
        this._timeout = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, REFRESH_SECONDS, () => {
            this._update();
            return GLib.SOURCE_CONTINUE;
        });
    }

    disable() {
        if (this._timeout) { GLib.source_remove(this._timeout); this._timeout = null; }
        if (this._indicator) { this._indicator.destroy(); this._indicator = null; }
        this._topLabel = null;
        this._logo = null;
        this._sessionContainer = null;
        this._weeklyContainer = null;
    }

    _buildMenu() {
        const menu = this._indicator.menu;
        menu.removeAll();

        menu.box.set_style(`
            background-color: ${COLORS.bg};
            border: 1px solid ${COLORS.border};
            border-radius: 8px;
            padding: 0;
        `);

        const wrapper = new PopupMenu.PopupBaseMenuItem({reactive: false, can_focus: false, style_class: ''});
        wrapper.remove_all_children();
        wrapper.set_style(`background-color: ${COLORS.bg}; padding: 0;`);

        const content = new St.BoxLayout({
            vertical: true,
            style: `background-color: ${COLORS.bg}; padding: 14px 18px; min-width: 300px; spacing: 4px;`,
        });

        content.add_child(new St.Label({
            text: 'USAGE',
            style: `color: ${COLORS.header}; font-size: 11px; font-weight: bold; letter-spacing: 1px; padding-bottom: 4px;`,
        }));

        this._sessionContainer = new St.BoxLayout({vertical: true});
        this._weeklyContainer = new St.BoxLayout({vertical: true});

        content.add_child(this._sessionContainer);
        content.add_child(makeDivider());
        content.add_child(this._weeklyContainer);
        content.add_child(makeDivider());

        const link = new St.Label({
            text: 'Manage usage on claude.ai',
            style: `color: ${COLORS.link}; font-size: 12px;`,
            reactive: true,
            track_hover: true,
        });
        link.connect('button-press-event', () => {
            Gio.AppInfo.launch_default_for_uri_async(CLAUDE_USAGE_URL, null, null, null);
            menu.close();
            return Clutter.EVENT_STOP;
        });
        content.add_child(link);

        wrapper.add_child(content);
        menu.addMenuItem(wrapper);
        this._refreshContainers(null);
    }

    _refreshContainers(data) {
        this._sessionContainer.remove_all_children();
        this._weeklyContainer.remove_all_children();

        if (!data || data.error) {
            const msg = data?.error ? `Error: ${data.error}` : 'Loading...';
            this._sessionContainer.add_child(new St.Label({
                text: msg,
                style: `color: ${COLORS.text_dim}; font-size: 12px; padding: 8px 0;`,
            }));
            return;
        }

        this._sessionContainer.add_child(
            makeUsageBlock('Session (5hr)', data.session_pct, data.session_resets_in)
        );
        this._weeklyContainer.add_child(
            makeUsageBlock('Weekly (7 day)', data.weekly_pct, data.weekly_resets_in)
        );
    }

    _update() {
        try {
            let [ok, stdout, , exitCode] = GLib.spawn_command_line_sync(
                `/bin/bash ${this._statsScript}`
            );
            if (!ok || exitCode !== 0) { this._setError('script failed'); return; }

            const data = JSON.parse(new TextDecoder().decode(stdout).trim());
            if (data.error) { this._setError(data.error); return; }

            const sp = data.session_pct ?? 0;
            const wp = data.weekly_pct ?? 0;

            this._topLabel.set_text(`${sp}% | ${wp}%`);
            this._topLabel.set_style(
                `font-size: 11px; font-weight: bold; color: ${pctColor(Math.max(sp, wp))};`
            );
            this._refreshContainers(data);
        } catch (e) {
            this._setError(String(e));
        }
    }

    _setError(msg) {
        this._topLabel?.set_text('err');
        this._topLabel?.set_style(`font-size: 11px; color: ${COLORS.error};`);
        this._refreshContainers({error: msg});
    }
}
