const Applet = imports.ui.applet;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;

const SCRIPT = GLib.get_home_dir() + "/.local/bin/oslo-weather";
const REFRESH_SECONDS = 600;          // the script itself caches for 15 minutes
const FORECAST_URL = "https://www.yr.no/en/forecast/daily-table/2-3143244/Norway/Oslo";

class OsloWeatherApplet extends Applet.TextIconApplet {
    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);

        this.hide_applet_icon();          // the glyph in the label is the icon
        this.set_applet_label("…");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);

        this._items = {};
        for (let key of ["now", "range", "wind", "rain"]) {
            this._items[key] = new PopupMenu.PopupMenuItem("", { reactive: false });
            this.menu.addMenuItem(this._items[key]);
        }
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        let refresh = new PopupMenu.PopupMenuItem("Refresh now");
        refresh.connect("activate", () => this._update(true));
        this.menu.addMenuItem(refresh);

        let open = new PopupMenu.PopupMenuItem("Open forecast on yr.no");
        open.connect("activate", () => Util.spawnCommandLine("xdg-open " + FORECAST_URL));
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

    _render(payload) {
        if (!payload || payload.temp === null || payload.temp === undefined) {
            this.set_applet_label("Oslo --");
            this.set_applet_tooltip("Oslo weather unavailable");
            return;
        }

        let temp = Math.round(payload.temp);
        this.set_applet_label(payload.glyph + " " + temp + "°" + (payload.error ? " ⚠" : ""));

        let nowText = payload.glyph + "  " + temp + "°C, " + payload.text;
        let rangeText = (payload.high != null && payload.low != null)
            ? "Today:  " + Math.round(payload.high) + "° / " + Math.round(payload.low) + "°" : "";
        let windText = payload.wind != null
            ? "Wind:  " + payload.wind.toFixed(1) + " m/s" +
              (payload.humidity != null ? "    Humidity:  " + Math.round(payload.humidity) + "%" : "") : "";
        let rainText = (payload.rain_next_hour != null && payload.rain_next_hour > 0)
            ? "Rain next hour:  " + payload.rain_next_hour.toFixed(1) + " mm" : "";

        this._items.now.label.set_text(nowText);
        this._items.range.label.set_text(rangeText);
        this._items.wind.label.set_text(windText);
        this._items.rain.label.set_text(rainText);
        for (let key of ["range", "wind", "rain"]) {
            this._items[key].actor.visible = this._items[key].label.get_text().length > 0;
        }

        let tip = "Oslo — " + nowText;
        if (rangeText) tip += "\n" + rangeText;
        if (windText) tip += "\n" + windText;
        if (rainText) tip += "\n" + rainText;
        if (payload.error) tip += "\n\nLast fetch failed (" + payload.error + "); showing cached data.";
        this.set_applet_tooltip(tip);
    }
}

function main(metadata, orientation, panelHeight, instanceId) {
    return new OsloWeatherApplet(orientation, panelHeight, instanceId);
}
