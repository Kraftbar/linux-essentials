const Applet = imports.ui.applet;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;

const SCRIPT = GLib.get_home_dir() + "/.local/bin/codex-usage";
// The tracked window is 30 days, and each poll spawns a Codex app-server, so
// this stays deliberately slow. The script caches on the same interval.
const REFRESH_SECONDS = 1800;
const USAGE_URL = "https://chatgpt.com/codex/settings/usage";

const AMBER = "#e0a33e";
const RED = "#e05252";
const DIM = "#888888";

class CodexUsageApplet extends Applet.TextIconApplet {
    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);

        this.set_applet_icon_symbolic_name("utilities-terminal");
        this.set_applet_label("…");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);

        this._items = {};
        for (let key of ["usage", "reset", "plan", "note"]) {
            this._items[key] = new PopupMenu.PopupMenuItem("", { reactive: false });
            this.menu.addMenuItem(this._items[key]);
        }
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        let refresh = new PopupMenu.PopupMenuItem("Refresh now");
        refresh.connect("activate", () => this._update(true));
        this.menu.addMenuItem(refresh);

        let open = new PopupMenu.PopupMenuItem("Open Codex usage");
        open.connect("activate", () => Util.spawnCommandLine("xdg-open " + USAGE_URL));
        this.menu.addMenuItem(open);

        this._timeout = null;
        this._update(false);
    }

    on_applet_clicked() {
        this.menu.toggle();
    }

    on_applet_removed_from_panel() {
        if (this._timeout) {
            Mainloop.source_remove(this._timeout);
            this._timeout = null;
        }
    }

    _schedule() {
        if (this._timeout) Mainloop.source_remove(this._timeout);
        this._timeout = Mainloop.timeout_add_seconds(REFRESH_SECONDS, () => {
            this._timeout = null;
            this._update(false);
            return false;
        });
    }

    _update(force) {
        let argv = [SCRIPT, "--json"];
        if (force) argv.push("--force");

        let proc;
        try {
            proc = new Gio.Subprocess({
                argv: argv,
                flags: Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE
            });
            proc.init(null);
        } catch (e) {
            this._render(null);
            this._schedule();
            return;
        }

        proc.communicate_utf8_async(null, null, (source, result) => {
            let payload = null;
            try {
                let [, stdout] = source.communicate_utf8_finish(result);
                payload = JSON.parse(stdout);
            } catch (e) {
                payload = null;
            }
            this._render(payload);
            this._schedule();
        });
    }

    _colour(payload) {
        let p = payload.percent;
        if (p === null || p === undefined) return DIM;
        if (payload.reached) return RED;
        if (p >= 90) return RED;
        if (p >= 75) return AMBER;
        return null;
    }

    _render(payload) {
        if (!payload) {
            this.set_applet_label("cx ?");
            this.set_applet_tooltip("Codex usage unavailable — could not run " + SCRIPT);
            return;
        }

        let p = payload.percent;
        let value = (p === null || p === undefined) ? "--" : p + "%";
        let stale = payload.error ? " ⚠" : "";
        let tail = payload.reset_label ? " " + payload.reset_label : "";

        this.set_applet_label("cx " + value + tail + stale);
        let colour = this._colour(payload);
        if (colour) {
            try {
                this._applet_label.get_clutter_text()
                    .set_markup('<span color="' + colour + '">cx ' + value + tail + stale + "</span>");
            } catch (e) { /* plain label already set */ }
        }

        let windowText = "";
        if (payload.window_minutes) {
            let mins = payload.window_minutes;
            windowText = mins >= 1440 ? Math.round(mins / 1440) + "-day window"
                                      : Math.round(mins / 60) + "-hour window";
        }

        this._items.usage.label.set_text("Used:  " + value + (windowText ? "   (" + windowText + ")" : ""));
        this._items.reset.label.set_text(payload.reset_full
            ? "Resets:  " + payload.reset_full + (payload.reset_in ? "   (in " + payload.reset_in + ")" : "") : "");
        this._items.plan.label.set_text(payload.plan
            ? "Plan:  " + payload.plan + (payload.has_credits ? "   credits available" : "   no credits") : "");

        let note = "";
        if (payload.reached) note = "Limit reached: " + payload.reached;
        else if (payload.error === "token-expiring") note = "Token near expiry — run Codex to refresh";
        else if (payload.error) note = "Last fetch failed; showing cached values";
        this._items.note.label.set_text(note);

        for (let key of ["reset", "plan", "note"]) {
            this._items[key].actor.visible = this._items[key].label.get_text().length > 0;
        }

        let tip = "Codex usage\nUsed:  " + value + (windowText ? "   (" + windowText + ")" : "");
        if (payload.reset_full) tip += "\nResets:  " + payload.reset_full;
        if (payload.plan) tip += "\nPlan:  " + payload.plan;
        if (note) tip += "\n\n" + note;
        this.set_applet_tooltip(tip);
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new CodexUsageApplet(orientation, panelHeight, instanceId);
}
