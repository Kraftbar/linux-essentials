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
 *
 * From a floating window the vertical arrows instead climb and drop:
 * Super+Up goes floating -> maximized -> top half and stops, while Super+Down
 * returns any expanded window straight to floating, then minimizes it.
 */

const Main = imports.ui.main;
const Meta = imports.gi.Meta;
const Mainloop = imports.mainloop;

const UUID = 'windows-snap@nybo';

/* Zones as fractions of the monitor work area. */
const ZONES = {
    LEFT:  { x: 0,   y: 0,   w: 0.5, h: 1   },
    RIGHT: { x: 0.5, y: 0,   w: 0.5, h: 1   },
    TOP:   { x: 0,   y: 0,   w: 1,   h: 0.5 },
    TL:    { x: 0,   y: 0,   w: 0.5, h: 0.5 },
    TR:    { x: 0.5, y: 0,   w: 0.5, h: 0.5 },
    BL:    { x: 0,   y: 0.5, w: 0.5, h: 0.5 },
    BR:    { x: 0.5, y: 0.5, w: 0.5, h: 0.5 },
};

/*
 * muffin's own tile_mode, mapped onto the zones above. Dragging a window to a
 * screen edge tiles it through muffin rather than through this extension, so
 * without consulting tile_mode the window would look "floating" here and
 * Super+Left would re-snap it left instead of continuing the cycle.
 *
 * BOTTOM has no equivalent zone - Super+Down minimizes rather than snapping to
 * a bottom half - so it is deliberately absent and falls through to floating.
 */
const TILE_MODE_ZONES = {
    [Meta.TileMode.LEFT]:  'LEFT',
    [Meta.TileMode.RIGHT]: 'RIGHT',
    [Meta.TileMode.TOP]:   'TOP',
    [Meta.TileMode.ULC]:   'TL',
    [Meta.TileMode.URC]:   'TR',
    [Meta.TileMode.LLC]:   'BL',
    [Meta.TileMode.LRC]:   'BR',
};

/*
 * State machine. Keys are the current state, values map an arrow direction to
 * the next state. null means "do nothing".
 *
 * Halves run a 3-step cycle - move that way, then across to the other side,
 * then back to floating.
 *
 * Quarters follow Windows instead and never float: a horizontal arrow just
 * flips to the other quarter in the same row, and the way out is the vertical
 * arrow pointing back at the half the quarter came from. Pressing up again
 * from a top quarter - already against the top edge - maximizes, the same as
 * pressing up from a floating window.
 *
 * The vertical arrows are deliberately not mirror images of each other, again
 * matching Windows. Up climbs a ladder, floating -> maximized -> top half, and
 * stops there. Down does not walk back down that ladder: from any expanded
 * state it drops straight to floating, and from floating it minimizes.
 */
const TRANSITIONS = {
    FLOAT: { left: 'LEFT',  right: 'RIGHT', up: 'MAX',   down: 'MIN'   },
    MAX:   { left: 'LEFT',  right: 'RIGHT', up: 'TOP',   down: 'FLOAT' },
    TOP:   { left: 'LEFT',  right: 'RIGHT', up: null,    down: 'FLOAT' },
    LEFT:  { left: 'RIGHT', right: 'FLOAT', up: 'TL',    down: 'BL'    },
    RIGHT: { left: 'FLOAT', right: 'LEFT',  up: 'TR',    down: 'BR'    },
    TL:    { left: 'TR',    right: 'TR',    up: 'MAX',   down: 'LEFT'  },
    TR:    { left: 'TL',    right: 'TL',    up: 'MAX',   down: 'RIGHT' },
    BL:    { left: 'BR',    right: 'BR',    up: 'LEFT',  down: null    },
    BR:    { left: 'BL',    right: 'BL',    up: 'RIGHT', down: null    },
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

/* Pixel geometry of a zone on the monitor the window is currently on. */
function zoneRect(win, zoneName) {
    const area = win.get_work_area_for_monitor(win.get_monitor());
    const z = ZONES[zoneName];
    return {
        x: area.x + Math.round(z.x * area.width),
        y: area.y + Math.round(z.y * area.height),
        width:  Math.round(z.w * area.width),
        height: Math.round(z.h * area.height),
    };
}

/*
 * Which zone, if any, a rectangle is sitting on.
 *
 * This matters because the extension cannot rely on its own bookkeeping: the
 * per-window state lives on the Meta.Window JS wrapper and is lost whenever
 * Cinnamon reloads, and a window can be put on a zone by other means entirely.
 * Without this, such a window looks like it is floating even though it visibly
 * is not, and the first arrow press would both re-snap it to where it already
 * is and record the zone geometry as the place to "restore" to later.
 */
function zoneOfRect(win, rect) {
    return Object.keys(ZONES).find(name => sameRect(rect, zoneRect(win, name))) || null;
}

/*
 * True when muffin is managing the window's geometry - maximized in either
 * axis, or tiled by dragging it to a screen edge. muffin saves the pre-snap
 * geometry in that case and unmaximize() puts it back, which is how a window
 * snapped by mouse can still be restored even though this extension never saw
 * it float.
 */
function isMuffinManaged(win) {
    return win.get_maximized() !== 0 || win.tile_mode !== Meta.TileMode.NONE;
}

/* Fallback for a window that needs to float but has no trustworthy geometry
 * to go back to - centred, and small enough to clearly read as un-snapped. */
function defaultFloatRect(win) {
    const area = win.get_work_area_for_monitor(win.get_monitor());
    const width  = Math.round(area.width  * 0.6);
    const height = Math.round(area.height * 0.6);
    return {
        x: area.x + Math.round((area.width  - width)  / 2),
        y: area.y + Math.round((area.height - height) / 2),
        width,
        height,
    };
}

/*
 * Work out the state the window is *actually* in, rather than trusting what we
 * recorded last time - it may have been dragged, resized or edge-snapped since,
 * and our record may simply be gone after a Cinnamon reload.
 *
 * Order matters: muffin's own view (tile_mode, get_maximized) is authoritative
 * and covers snapping done with the mouse; then our own record, but only if the
 * window is still where we put it; and finally the geometry itself, so a window
 * sitting on a zone is treated as being in that zone no matter how it got there.
 */
function currentState(win) {
    if (win.get_maximized() === Meta.MaximizeFlags.BOTH ||
        win.tile_mode === Meta.TileMode.MAXIMIZED)
        return 'MAX';

    const tiled = TILE_MODE_ZONES[win.tile_mode];
    if (tiled)
        return tiled;

    const rect = rectOf(win);

    if (win._wsState && win._wsState !== 'FLOAT' && win._wsState !== 'MAX' &&
        sameRect(rect, win._wsZoneRect))
        return win._wsState;

    return zoneOfRect(win, rect) || 'FLOAT';
}

/*
 * Where the window should go when it next floats.
 *
 * A stored rect that is itself a zone is discarded rather than used. That
 * happens when a window was already sitting on a zone the first time an arrow
 * was pressed - the geometry got recorded as "floating", and restoring to it
 * would just put the window back on the zone it is trying to leave.
 */
function floatTarget(win) {
    const stored = win._wsFloatRect;
    if (stored && !zoneOfRect(win, stored))
        return stored;
    return defaultFloatRect(win);
}

/*
 * Remember where the window should return to, before it gets moved anywhere.
 *
 * When muffin is managing the window it holds the real pre-snap geometry, so
 * ask it: unmaximize() drops the window back to the rect muffin saved, and
 * get_frame_rect() reflects that immediately (verified - updated synchronously,
 * not on the next repaint), so it can be read back in the same handler.
 */
function ensureFloatRect(win, state) {
    if (isMuffinManaged(win)) {
        win.unmaximize(Meta.MaximizeFlags.BOTH);
        win._wsFloatRect = rectOf(win);
        return;
    }

    /* Only a genuinely floating window can describe its own float geometry,
     * and only if it is not parked on a zone - see floatTarget(). */
    if (state === 'FLOAT') {
        const rect = rectOf(win);
        if (!zoneOfRect(win, rect))
            win._wsFloatRect = rect;
    }
}

function applyZone(win, zoneName) {
    if (win.get_maximized())
        win.unmaximize(Meta.MaximizeFlags.BOTH);

    const r = zoneRect(win, zoneName);
    moveResize(win, r.x, r.y, r.width, r.height);

    win._wsState = zoneName;
    /* Remember where we put it so currentState() can tell later whether the
     * window is still there or the user has since moved it. */
    win._wsZoneRect = r;
}

function restore(win) {
    win._wsState = 'FLOAT';
    win._wsZoneRect = null;

    /* If muffin tiled or maximized this window it already knows the geometry
     * to go back to, and unmaximize() restores it exactly. */
    if (isMuffinManaged(win)) {
        win.unmaximize(Meta.MaximizeFlags.BOTH);
        if (!zoneOfRect(win, rectOf(win)))
            return;
        /* Some windows are left on a zone by unmaximize (a vertical-only
         * maximize of an already half-width window, say); fall through and
         * place it properly. */
    }

    const target = floatTarget(win);
    moveResize(win, target.x, target.y, target.width, target.height);
    win._wsFloatRect = target;
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

    /* Remember where to come back to before we move the window anywhere. */
    if (next !== 'FLOAT' && next !== 'MIN')
        ensureFloatRect(win, state);

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

/*
 * Dragging a snapped window with the mouse should hand back its floating size,
 * the way Windows does.
 *
 * muffin does this by itself for windows *it* tiled, but the zones here are
 * applied with move_resize_frame(), so as far as muffin is concerned those
 * windows are just ordinary windows that happen to be half-screen sized - it
 * has no pre-snap geometry for them and drags them at full snapped size.
 *
 * Resizing alone is not enough. muffin captures the drag anchor when the grab
 * starts, before this runs, and then tracks pointer motion against that, so
 * simply moving the window here is ignored for the rest of the drag. Measured
 * on this build, grabbing a left-snapped window near its right edge and
 * dragging left the window a few hundred px from the pointer - far enough that
 * the cursor was not over the window at all.
 *
 * Ending the grab and immediately restarting it makes muffin re-anchor to the
 * new geometry. That also decides the position: begin_grab_op() centres the
 * window on the pointer in both axes (verified - the pointer ends up at
 * exactly half the new width and height regardless of where the window was
 * grabbed), which is what Windows does too. So only the size is set below;
 * any position given here would be discarded.
 */
let regrabbing = false;

function onGrabBegin(display, unused, win, op) {
    /* begin_grab_op() below re-emits this signal; without this the handler
     * would recurse into itself. */
    if (regrabbing)
        return;

    if (op !== Meta.GrabOp.MOVING || !win)
        return;
    if (win.get_window_type() !== Meta.WindowType.NORMAL || !win.resizeable)
        return;

    if (currentState(win) === 'FLOAT')
        return;

    const frame = rectOf(win);
    const target = floatTarget(win);
    if (sameRect(frame, target))
        return;

    if (win.get_maximized())
        win.unmaximize(Meta.MaximizeFlags.BOTH);

    moveResize(win, frame.x, frame.y, target.width, target.height);

    win._wsState = 'FLOAT';
    win._wsZoneRect = null;

    /* Deferred: the grab cannot be torn down and rebuilt from inside the
     * signal muffin is still dispatching. */
    regrabbing = true;
    Mainloop.idle_add(() => {
        try {
            const time = global.get_current_time();
            global.display.end_grab_op(time);
            win.begin_grab_op(Meta.GrabOp.MOVING, true, time);
        } catch (e) {
            global.logError(`[${UUID}] regrab: ${e}\n${e.stack}`);
        }
        regrabbing = false;
        return false;
    });
}

let grabBeginId = 0;

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

    grabBeginId = global.display.connect('grab-op-begin', (...args) => {
        try {
            onGrabBegin(...args);
        } catch (e) {
            global.logError(`[${UUID}] grab-op-begin: ${e}\n${e.stack}`);
        }
    });
}

function disable() {
    for (const [name] of BINDINGS)
        Main.keybindingManager.removeHotKey(name);

    if (grabBeginId) {
        global.display.disconnect(grabBeginId);
        grabBeginId = 0;
    }
}
