/*
 * Smart Close - make Ctrl+Shift+W close any window, without stealing the
 * shortcut from apps that already use it for something better.
 *
 * THE PROBLEM
 *
 * Ctrl+Shift+W only works in apps that implement it themselves - gnome-terminal
 * closes a tab with it, a settings dialog does nothing at all. Binding it
 * globally to "close window" fixes the dialogs but breaks the terminal: an X
 * key grab is taken by whoever grabs it, so the window manager wins and the
 * terminal never sees the key. It would close the whole terminal window,
 * tabs and all.
 *
 * THE USUAL WORKAROUND, AND WHY IT IS NOT USED HERE
 *
 * The common trick is to keep the global grab, then re-inject a *different*
 * accelerator (one the terminal has been rebound to) with XTEST so the app
 * acts on that instead. It works, but the physical Ctrl+Shift is still held
 * down while the synthetic keypress goes out, so it needs a sleep to dodge the
 * modifier race - which makes the shortcut feel laggy, and still misfires.
 *
 * WHAT THIS DOES INSTEAD
 *
 * muffin keybindings can be added and removed at runtime, so the grab itself
 * is made conditional. On every focus change:
 *
 *   - focused app handles Ctrl+Shift+W itself -> release the grab, and the key
 *     reaches the app untouched, exactly as if nothing were installed
 *   - anything else -> hold the grab and close the window on press
 *
 * No key injection, no timing workaround. Verified directly: with the grab
 * held, a Ctrl+Shift+W press ran our callback and the terminal was untouched;
 * with it released, the callback did not run and the terminal closed its tab.
 */

const Main = imports.ui.main;
const Meta = imports.gi.Meta;

const UUID = 'smart-close@nybo';
const HOTKEY_NAME = 'smart-close-window';
const ACCELERATOR = '<Control><Shift>w';

/*
 * WM_CLASS values of apps that already do something useful with Ctrl+Shift+W
 * and should keep receiving it. Terminals are the real case - they close a tab.
 *
 * Browsers are deliberately absent: Ctrl+Shift+W closes the window there too,
 * so letting this extension handle it produces the same result, and keeping
 * the grab means it also works on their dialogs and popups.
 *
 * Matched case-insensitively against both WM_CLASS and its instance name.
 */
const PASSTHROUGH_CLASSES = [
    'gnome-terminal',
    'gnome-terminal-server',
    'xfce4-terminal',
    'konsole',
    'terminator',
    'alacritty',
    'kitty',
    'tilix',
    'x-terminal-emulator',
];

let focusSignalId = 0;
let grabbed = false;

function appHandlesShortcut(win) {
    if (!win)
        return false;

    const names = [win.get_wm_class(), win.get_wm_class_instance()];
    return names.some(n => n && PASSTHROUGH_CLASSES.includes(n.toLowerCase()));
}

function closeFocusedWindow() {
    const win = global.display.get_focus_window();
    if (!win)
        return;

    /* delete() is the polite close - same as clicking the titlebar X, so the
     * app still gets to prompt about unsaved work. */
    win.delete(global.get_current_time());
}

function grab() {
    if (grabbed)
        return;
    Main.keybindingManager.addHotKey(HOTKEY_NAME, ACCELERATOR, () => {
        /* Errors thrown inside a keybinding callback are otherwise swallowed
         * and the shortcut just silently does nothing. */
        try {
            closeFocusedWindow();
        } catch (e) {
            global.logError(`[${UUID}] ${e}\n${e.stack}`);
        }
    });
    grabbed = true;
}

function ungrab() {
    if (!grabbed)
        return;
    Main.keybindingManager.removeHotKey(HOTKEY_NAME);
    grabbed = false;
}

function onFocusChanged() {
    try {
        if (appHandlesShortcut(global.display.get_focus_window()))
            ungrab();
        else
            grab();
    } catch (e) {
        global.logError(`[${UUID}] focus handler: ${e}\n${e.stack}`);
    }
}

function init(metadata) {
}

function enable() {
    focusSignalId = global.display.connect('notify::focus-window', onFocusChanged);
    /* Set the initial grab state to match whatever is focused right now,
     * rather than waiting for the first focus change. */
    onFocusChanged();
}

function disable() {
    if (focusSignalId) {
        global.display.disconnect(focusSignalId);
        focusSignalId = 0;
    }
    ungrab();
}
