/*
 * Alt-Tab Instant - show the window thumbnail in the Alt+Tab switcher right
 * away, like Windows does.
 *
 * The "icons+thumbnails" switcher waits THUMBNAIL_POPUP_TIME (300 ms, a
 * hard-coded constant) after every selection change before it builds the
 * thumbnail, and then fades it in over another 100 ms. Together with the
 * popup delay (the alttab-switcher-delay setting, set that to 0) that is
 * about half a second before the preview shows.
 *
 * The constant can't be reached from outside the module, so this wraps
 * _setCurrentWindow: let the original queue its timeout, then cancel it and
 * build the thumbnail now. _createThumbnails is wrapped to drop the fade.
 */

const Mainloop = imports.mainloop;
const Tweener = imports.ui.tweener;
const ClassicSwitcher = imports.ui.appSwitcher.classicSwitcher.ClassicSwitcher;

let originalSetCurrent = null;
let originalCreate = null;

function setCurrentWindow(window) {
    originalSetCurrent.call(this, window);
    if (this._thumbnailTimeoutId) {
        Mainloop.source_remove(this._thumbnailTimeoutId);
        this._thumbnailTimeoutId = 0;
        if (!this._thumbnails)
            this._createThumbnails();
        this._thumbnails.highlight(0, false);
    }
}

function createThumbnails() {
    originalCreate.call(this);
    Tweener.removeTweens(this._thumbnails.actor);
    this._thumbnails.actor.opacity = 255;
    this.thumbnailsVisible = true;
}

function init(metadata) {
}

function enable() {
    originalSetCurrent = ClassicSwitcher.prototype._setCurrentWindow;
    originalCreate = ClassicSwitcher.prototype._createThumbnails;
    ClassicSwitcher.prototype._setCurrentWindow = setCurrentWindow;
    ClassicSwitcher.prototype._createThumbnails = createThumbnails;
}

function disable() {
    if (originalSetCurrent) {
        ClassicSwitcher.prototype._setCurrentWindow = originalSetCurrent;
        ClassicSwitcher.prototype._createThumbnails = originalCreate;
        originalSetCurrent = originalCreate = null;
    }
}
