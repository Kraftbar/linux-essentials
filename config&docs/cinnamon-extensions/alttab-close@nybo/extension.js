/*
 * Alt-Tab Close - press Q while the Alt+Tab switcher is open to close the
 * highlighted window, like Cmd+Tab then Q on a Mac.
 *
 * Cinnamon's switcher already reacts to a few extra keys in
 * AppSwitcher._keyPressEvent (Esc, Enter, D for the desktop), and it already
 * copes with a window going away while it is open: _windowDestroyed drops the
 * window from the list and moves the selection. So the only missing piece is
 * the key. This wraps _keyPressEvent, asks the highlighted window to close on
 * Q, and hands every other key to the original handler.
 *
 * The close is the polite kind, the same as clicking the X, so an app can
 * still ask about unsaved work. The switcher stays open while Alt is held, so
 * Q can be pressed again for the next window.
 *
 * Every Alt+Tab creates a new switcher and binds the handler from the
 * prototype at that moment, so replacing it on the prototype is enough and
 * covers all switcher styles (they inherit it).
 */

const Clutter = imports.gi.Clutter;
const AppSwitcher = imports.ui.appSwitcher.appSwitcher.AppSwitcher;

let originalKeyPress = null;

function keyPress(actor, event) {
    const symbol = event.get_key_symbol();
    if (symbol === Clutter.KEY_q || symbol === Clutter.KEY_Q) {
        const win = this._windows && this._windows[this._currentIndex];
        if (win)
            win.delete(global.get_current_time());
        return true;
    }
    return originalKeyPress.call(this, actor, event);
}

function init(metadata) {
}

function enable() {
    originalKeyPress = AppSwitcher.prototype._keyPressEvent;
    AppSwitcher.prototype._keyPressEvent = keyPress;
}

function disable() {
    if (originalKeyPress) {
        AppSwitcher.prototype._keyPressEvent = originalKeyPress;
        originalKeyPress = null;
    }
}
