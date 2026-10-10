const Applet = imports.ui.applet;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Mainloop = imports.mainloop;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;
const ByteArray = imports.byteArray;

const SCRIPT = GLib.get_home_dir() + "/.local/bin/claude-usage";
const CODEX_SCRIPT = GLib.get_home_dir() + "/.local/bin/codex-usage";
const REFRESH_SECONDS = 60;
const USAGE_URL = "https://claude.ai/settings/usage";
// Local machine readouts rendered next to the quota numbers.
const CLK_TCK = 100;             // getconf CLK_TCK; /proc/<pid>/stat is in these ticks
const BUSY_CPU_PERCENT = 5;      // a Claude Code session above this is "working"
const CPU_AMBER = 70;            // 1-min load as % of cores
const CPU_RED = 90;

const AMBER = "#e0a33e";
const RED = "#e05252";
const DIM = "#888888";

class ClaudeUsageApplet extends Applet.TextIconApplet {
    constructor(orientation, panelHeight, instanceId) {
        super(orientation, panelHeight, instanceId);

        this.set_applet_icon_symbolic_name("utilities-system-monitor");
        this.set_applet_label("…");

        this.menuManager = new PopupMenu.PopupMenuManager(this);
        this.menu = new Applet.AppletPopupMenu(this, orientation);
        this.menuManager.addMenu(this.menu);

        this._items = {};
        for (let key of ["five", "week", "codex", "sessions", "cpu", "burn", "models", "credits"]) {
            this._items[key] = new PopupMenu.PopupMenuItem("", { reactive: false });
            this.menu.addMenuItem(this._items[key]);
        }
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        let refresh = new PopupMenu.PopupMenuItem("Refresh now");
        refresh.connect("activate", () => this._update(true));
        this.menu.addMenuItem(refresh);

        let open = new PopupMenu.PopupMenuItem("Open usage settings");
        open.connect("activate", () => Util.spawnCommandLine("xdg-open " + USAGE_URL));
        this.menu.addMenuItem(open);

        this._timeout = null;
        this._cpuPrev = {};   // pid -> [ticks, monotonic seconds] from the last poll
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
            this._render(null, null);
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
            this._updateCodex(payload, force);
        });
    }

    _updateCodex(claude, force) {
        let argv = [CODEX_SCRIPT, "--json"];
        if (force) argv.push("--force");
        let proc;
        try {
            proc = new Gio.Subprocess({
                argv: argv,
                flags: Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE
            });
            proc.init(null);
        } catch (e) {
            this._render(claude, null);
            this._schedule();
            return;
        }
        proc.communicate_utf8_async(null, null, (source, result) => {
            let codex = null;
            try {
                let [, stdout] = source.communicate_utf8_finish(result);
                codex = JSON.parse(stdout);
            } catch (e) { /* Claude still renders if Codex is unavailable. */ }
            this._render(claude, codex);
            this._schedule();
        });
    }

    _readFile(path) {
        try {
            let [ok, bytes] = GLib.file_get_contents(path);
            return ok ? ByteArray.toString(bytes) : null;
        } catch (e) {
            return null;
        }
    }

    // Running Claude Code sessions: one `claude` process each. A session waiting
    // at the prompt sits near 0% CPU, so per-process CPU between two polls tells
    // idle chats from working ones.
    _sessions() {
        let pids = [];
        try {
            let [ok, out] = GLib.spawn_command_line_sync("pgrep -x claude");
            if (ok && out) {
                pids = ByteArray.toString(out).trim().split("\n")
                    .filter(x => x.length > 0).map(Number);
            }
        } catch (e) { /* pgrep missing: report nothing rather than fail the applet */ }

        let now = GLib.get_monotonic_time() / 1e6;
        let next = {};
        let rows = [];
        for (let pid of pids) {
            let stat = this._readFile("/proc/" + pid + "/stat");
            if (!stat) continue;
            // Everything after "comm)" starts at field 3 (state); utime/stime are fields 14/15.
            let rest = stat.slice(stat.lastIndexOf(")") + 2).trim().split(" ");
            let ticks = parseInt(rest[11], 10) + parseInt(rest[12], 10);
            let cpu = null;
            let prev = this._cpuPrev[pid];
            if (prev && now > prev[1]) {
                cpu = Math.round((ticks - prev[0]) / CLK_TCK / (now - prev[1]) * 100);
            }
            next[pid] = [ticks, now];
            let cwd = "";
            try {
                cwd = GLib.file_read_link("/proc/" + pid + "/cwd")
                    .replace(GLib.get_home_dir(), "~");
            } catch (e) { /* cwd unreadable; leave blank */ }
            rows.push({ pid: pid, cpu: cpu, cwd: cwd, busy: cpu !== null && cpu >= BUSY_CPU_PERCENT });
        }
        this._cpuPrev = next;
        return { total: rows.length, busy: rows.filter(r => r.busy).length, rows: rows };
    }

    // 1-minute load average as a percentage of cores. Load counts runnable and
    // uninterruptible tasks, so it is "how busy is the box", not strict CPU time.
    _cpu() {
        let s = this._readFile("/proc/loadavg");
        if (!s) return null;
        let f = s.trim().split(/\s+/);
        let cores = GLib.get_num_processors();
        let load1 = parseFloat(f[0]);
        return {
            load1: load1, load5: parseFloat(f[1]), load15: parseFloat(f[2]),
            cores: cores, percent: Math.round(load1 / cores * 100)
        };
    }

    // "ch" = chats: Claude Code sessions, working/running.
    _localMarkup(sess, cpu) {
        let cl = "ch " + sess.busy + "/" + sess.total;
        let clMarkup = sess.total === 0 ? '<span color="' + DIM + '">' + cl + "</span>"
                     : (sess.busy > 0 ? "<b>" + cl + "</b>" : cl);
        let cpuText = "cpu " + (cpu ? cpu.percent + "%" : "--");
        let cpuMarkup = cpuText;
        if (cpu && cpu.percent >= CPU_RED) cpuMarkup = '<span color="' + RED + '">' + cpuText + "</span>";
        else if (cpu && cpu.percent >= CPU_AMBER) cpuMarkup = '<span color="' + AMBER + '">' + cpuText + "</span>";
        return { plain: cl + "  " + cpuText, markup: clMarkup + "  " + cpuMarkup };
    }

    // Colour comes from the server's own severity, escalated when our burn-rate
    // projection says the window runs dry before it resets.
    _colour(win) {
        if (!win || win.percent === null || win.percent === undefined) return DIM;
        if (win.projected) return RED;
        let sev = win.severity || "normal";
        if (sev !== "normal" && sev !== "warning") return RED;
        if (win.percent >= 95) return RED;
        if (sev === "warning") return AMBER;
        return null;
    }

    _seg(label, win, tail) {
        let value = (!win || win.percent === null || win.percent === undefined)
            ? "--" : win.percent + "%";
        let body = label + " " + value + (tail ? " " + tail : "");
        let colour = this._colour(win);
        if (win && win.is_active) body = "<b>" + body + "</b>";
        return colour ? '<span color="' + colour + '">' + body + "</span>" : body;
    }

    // Just the number, coloured and bolded like _seg, for the compact label.
    _num(win) {
        let value = (!win || win.percent === null || win.percent === undefined)
            ? "--" : String(win.percent);
        let colour = this._colour(win);
        if (win && win.is_active) value = "<b>" + value + "</b>";
        return colour ? '<span color="' + colour + '">' + value + "</span>" : value;
    }

    _render(payload, codex) {
        let sess = this._sessions();
        let cpu = this._cpu();
        let local = this._localMarkup(sess, cpu);
        this._renderLocalMenu(sess, cpu);

        if (!payload) {
            this.set_applet_label("claude ?  " + local.plain);
            this.set_applet_tooltip("Claude usage unavailable — could not run " + SCRIPT);
            return;
        }

        let five = payload.five_hour || {};
        let week = payload.seven_day || {};
        let stale = payload.error ? " ⚠" : "";
        // Codex has no server-side severity, and its window is 30 days rather
        // than 5 hours, so 95% is far too late to start warning. Synthesise a
        // severity here and let the shared colour logic do the rest.
        if (codex && codex.percent !== null && codex.percent !== undefined) {
            codex.severity = (codex.reached || codex.percent >= 90) ? "critical"
                           : (codex.percent >= 75 ? "warning" : "normal");
        }
        let codexTail = codex && codex.reset_label ? codex.reset_label : "";

        // Compact: "cl 5h/wk%  cx %  ch busy/total  cpu %". Reset times live in
        // the dropdown and tooltip; the active Claude window is bold.
        let markup = "cl " + this._num(five) + "/" + this._num(week) + "%" + stale +
                     "  cx " + this._num(codex) + "%  " + local.markup;

        let pct = w => (!w || w.percent == null) ? "--" : String(w.percent);
        let plain = "cl " + pct(five) + "/" + pct(week) + "%" + stale +
                    "  cx " + pct(codex) + "%  " + local.plain;

        this.set_applet_label(plain);
        try {
            this._applet_label.get_clutter_text().set_markup(markup);
        } catch (e) { /* fall back to the plain label already set */ }

        let fiveText = (five.percent == null ? "--" : five.percent + "%") +
            (five.resets_clock ? "  resets " + five.resets_clock : "") +
            (five.resets_in ? " (in " + five.resets_in + ")" : "");
        let weekText = (week.percent == null ? "--" : week.percent + "%") +
            (week.resets_day ? "  resets " + week.resets_day +
                (week.resets_clock ? " " + week.resets_clock : "") : "") +
            (week.resets_in ? " (in " + week.resets_in + ")" : "");

        this._items.five.label.set_text("5-hour:  " + fiveText);
        this._items.week.label.set_text("Weekly:  " + weekText);

        let codexText = !codex || codex.percent == null ? "unavailable" :
            codex.percent + "% used" + (codex.reset_full ? "  resets " + codex.reset_full : "") +
            (codex.window_minutes ? "  (" + Math.round(codex.window_minutes / 1440) + "-day window)" : "") +
            (codex.plan ? "  [" + codex.plan + "]" : "") +
            (codex.error ? "  ⚠ cached" : "");
        this._items.codex.label.set_text("Codex:  " + codexText);

        let burn = "";
        if (five.projected) burn = "5-hour window hits 100% around " + five.projected[0];
        else if (week.projected) burn = "Weekly window hits 100% around " + week.projected[0];
        this._items.burn.label.set_text(burn);
        this._items.burn.actor.visible = burn.length > 0;

        let models = [];
        for (let name in (payload.by_model || {})) models.push(name + " " + payload.by_model[name] + "%");
        this._items.models.label.set_text(models.length ? "Weekly by model:  " + models.join("   ") : "");
        this._items.models.actor.visible = models.length > 0;

        // Never render "used / cap" as a balance: the cap is a ceiling, not money
        // held. While extra usage is off, say plainly that nothing can be billed.
        let c = payload.credits;
        let creditText = "";
        if (c && c.billable) {
            creditText = "Extra usage:  ON — " + c.used.toFixed(2) + " " + c.currency +
                " billed this month (cap " + c.cap.toFixed(2) + ")";
        } else if (c) {
            creditText = "Extra usage:  off (" + c.reason + ") — nothing can be billed";
        }
        this._items.credits.label.set_text(creditText);
        this._items.credits.actor.visible = creditText.length > 0;

        let tip = "Claude usage\n5-hour:  " + fiveText + "\nWeekly:  " + weekText +
            "\n\nCodex:  " + codexText + "\n\n" + this._localText(sess, cpu);
        if (burn) tip += "\n\n" + burn;
        if (payload.error === "auth") {
            tip += "\n\nToken expired — run any Claude Code command to refresh it.";
        } else if (payload.error) {
            tip += "\n\nLast fetch failed (" + payload.error + "); showing cached values.";
        }
        this.set_applet_tooltip(tip);
    }
}

ClaudeUsageApplet.prototype._localText = function(sess, cpu) {
    let lines = ["Claude Code sessions:  " + sess.busy + " working / " + sess.total + " running"];
    for (let r of sess.rows) {
        lines.push("   " + (r.busy ? "▶" : "·") + " " + (r.cpu === null ? " --" : String(r.cpu).padStart(3)) +
            "%  " + r.cwd + "  (pid " + r.pid + ")");
    }
    lines.push("CPU:  " + (cpu ? cpu.percent + "% of " + cpu.cores + " cores (load " +
        cpu.load1.toFixed(2) + " / " + cpu.load5.toFixed(2) + " / " + cpu.load15.toFixed(2) + ")" : "--"));
    return lines.join("\n");
};

ClaudeUsageApplet.prototype._renderLocalMenu = function(sess, cpu) {
    this._items.sessions.label.set_text("Sessions:  " + sess.busy + " working / " + sess.total + " running" +
        (sess.rows.length ? "   " + sess.rows.map(r => (r.busy ? "▶" : "·") + r.cwd).join("  ") : ""));
    this._items.cpu.label.set_text("CPU:  " + (cpu ? cpu.percent + "%  (load " + cpu.load1.toFixed(2) +
        " on " + cpu.cores + " cores)" : "--"));
};

function main(metadata, orientation, panelHeight, instanceId) {
    return new ClaudeUsageApplet(orientation, panelHeight, instanceId);
}
