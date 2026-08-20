/*
 * Windows Snap - Windows-style Super+arrow window snapping for Cinnamon.
 *
 * WHY AN EXTENSION AND NOT A KEYBINDING + SCRIPT
 *
 * Cinnamon has two different keybinding systems, and only one of them can
 * hold Super+<arrow>:
 *
 *   - Native WM keybindings (org.cinnamon.desktop.keybindings.wm push-tile-*)
 *     register through muffin. Super+Left works fine here.
 *   - Custom keybindings (org.cinnamon.desktop.keybindings custom-list) spawn
 *     a shell command. These lose the bare-Super grab to the "Super alone
 *     opens the menu" overlay key, so Super+Left just opened the menu.
 *
 * Main.keybindingManager.addHotKey() uses the *first* mechanism, so an
 * extension gets a real muffin grab. It then manipulates windows through the
 * Meta.Window API directly - no xdotool, no XTEST key injection, no sleep to
 * dodge a modifier race, and no dependency on the window manager's own
 * push-tile behaviour.
 *
 * BEHAVIOUR
 *
 * Repeated presses of the same arrow cycle through three states, e.g. for
 * Super+Left:  floating -> left half -> right half -> floating -> ...
 * Super+Right mirrors it. Vertical arrows collapse a half into a quarter and
 * back out again, so Super+Left then Super+Down gives the bottom-left quarter
 * (matching Windows), and Super+Up from there returns to the left half.
 */

const Main = imports.ui.main;
const Meta = imports.gi.Meta;

const UUID = 'windows-snap@nybo';

/* Zones as fractions of the monitor work area. */
const ZONES = {
    LEFT:  { x: 0,   y: 0,   w: 0.5, h: 1   },
    RIGHT: { x: 0.5, y: 0,   w: 0.5, h: 1   },
    TL:    { x: 0,   y: 0,   w: 0.5, h: 0.5 },
    TR:    { x: 0.5, y: 0,   w: 0.5, h: 0.5 },
    BL:    { x: 0,   y: 0.5, w: 0.5, h: 0.5 },
    BR:    { x: 0.5, y: 0.5, w: 0.5, h: 0.5 },
};

/*
 * State machine. Keys are the current state, values map an arrow direction to
 * the next state. null means "do nothing".
 *
 * Horizontal arrows always run the same 3-step cycle - move to that side, then
 * across to the other side, then back to floating - which is what produces
 * the Super+Left / Super+Left / Super+Left cycle described above.
 */
const TRANSITIONS = {
    FLOAT: { left: 'LEFT',  right: 'RIGHT', up: 'MAX',   down: 'MIN'   },
    MAX:   { left: 'LEFT',  right: 'RIGHT', up: null,    down: 'FLOAT' },
    LEFT:  { left: 'RIGHT', right: 'FLOAT', up: 'TL',    down: 'BL'    },
    RIGHT: { left: 'FLOAT', right: 'LEFT',  up: 'TR',    down: 'BR'    },
    TL:    { left: 'TR',    right: 'FLOAT', up: null,    down: 'LEFT'  },
    TR:    { left: 'FLOAT', right: 'TL',    up: null,    down: 'RIGHT' },
    BL:    { left: 'BR',    right: 'FLOAT', up: 'LEFT',  down: null    },
    BR:    { left: 'FLOAT', right: 'BL',    up: 'RIGHT', down: null    },
};

const BINDINGS = [
    ['windows-snap-left',  '<Super>Left',  'left'],
    ['windows-snap-right', '<Super>Right', 'right'],
    ['windows-snap-up',    '<Super>Up',    'up'],
    ['windows-snap-down',  '<Super>Down',  'down'],
];

/*
 * Tolerance in px when checking whether a window is still in the zone we put
 * it in. This has to absorb size-increment rounding: a terminal only resizes
 * in whole character cells, so asking for 1720x1412 actually lands on
 * 1718x1411, and a larger font would round further. Zones differ from each
 * other by half a screen, so a generous tolerance costs nothing.
 */
const TOLERANCE = 40;

/*
 * muffin's move_resize_frame() applies the size but silently ignores the x/y
 * it is given (verified against this build: move_resize_frame(0,0,w,h) left
 * the window at 40,40 while correctly resizing it). move_frame() does move it,
 * so every placement is a resize followed by an explicit move.
 */
function moveResize(win, x, y, w, h) {
    win.move_resize_frame(true, x, y, w, h);
    win.move_frame(true, x, y);
}

function rectOf(win) {
    const r = win.get_frame_rect();
    return { x: r.x, y: r.y, width: r.width, height: r.height };
}

function sameRect(a, b) {
    return a && b &&
        Math.abs(a.x - b.x) <= TOLERANCE &&
        Math.abs(a.y - b.y) <= TOLERANCE &&
        Math.abs(a.width - b.width) <= TOLERANCE &&
        Math.abs(a.height - b.height) <= TOLERANCE;
}

/*
 * Work out the state the window is *actually* in, rather than trusting what we
 * recorded last time. If the user has dragged or resized the window since, it
 * is no longer in its zone and we treat it as floating again - otherwise the
 * cycle would continue from a stale state and jump somewhere unexpected.
 */
function currentState(win) {
    if (win._wsState === 'MAX')
        return win.get_maximized() === Meta.MaximizeFlags.BOTH ? 'MAX' : 'FLOAT';

    if (!win._wsState || win._wsState === 'FLOAT')
        return 'FLOAT';

    return sameRect(rectOf(win), win._wsZoneRect) ? win._wsState : 'FLOAT';
}

function applyZone(win, zoneName) {
    if (win.get_maximized())
        win.unmaximize(Meta.MaximizeFlags.BOTH);

    const area = win.get_work_area_for_monitor(win.get_monitor());
    const z = ZONES[zoneName];

    const x = area.x + Math.round(z.x * area.width);
    const y = area.y + Math.round(z.y * area.height);
    const w = Math.round(z.w * area.width);
    const h = Math.round(z.h * area.height);

    moveResize(win, x, y, w, h);

    win._wsState = zoneName;
    /* Remember where we put it so currentState() can tell later whether the
     * window is still there or the user has since moved it. */
    win._wsZoneRect = { x, y, width: w, height: h };
}

function restore(win) {
    if (win.get_maximized())
        win.unmaximize(Meta.MaximizeFlags.BOTH);

    const orig = win._wsFloatRect;
    if (orig)
        moveResize(win, orig.x, orig.y, orig.width, orig.height);

    win._wsState = 'FLOAT';
    win._wsZoneRect = null;
}

function handle(direction) {
    const win = global.display.get_focus_window();
    if (!win || win.get_window_type() !== Meta.WindowType.NORMAL)
        return;
    /*
     * Deliberately not allows_resize(): that reports false while a window is
     * maximized, which would make Super+Down (unmaximize) a no-op - the one
     * case where we most need to act. The `resizeable` property describes the
     * window itself rather than its current state, so it still filters out
     * genuinely fixed-size windows.
     */
    if (!win.allows_move() || !win.resizeable)
        return;

    const state = currentState(win);
    const next = TRANSITIONS[state][direction];
    if (!next)
        return;

    /* Leaving the floating state: remember the geometry to come back to. */
    if (state === 'FLOAT')
        win._wsFloatRect = rectOf(win);

    switch (next) {
        case 'MIN':
            win.minimize();
            break;
        case 'FLOAT':
            restore(win);
            break;
        case 'MAX':
            win.maximize(Meta.MaximizeFlags.BOTH);
            win._wsState = 'MAX';
            win._wsZoneRect = null;
            break;
        default:
            applyZone(win, next);
            break;
    }
}

function init(metadata) {
}

function enable() {
    for (const [name, accel, direction] of BINDINGS) {
        Main.keybindingManager.addHotKey(name, accel, () => {
            /* A throw inside a keybinding callback is otherwise swallowed and
             * the shortcut just appears to do nothing, which is painful to
             * debug. Surface it in ~/.xsession-errors instead. */
            try {
                handle(direction);
            } catch (e) {
                global.logError(`[${UUID}] ${direction}: ${e}\n${e.stack}`);
            }
        });
    }
}

function disable() {
    for (const [name] of BINDINGS)
        Main.keybindingManager.removeHotKey(name);
}
