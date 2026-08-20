#!/usr/bin/env bash
# Bound to Ctrl+Shift+W as a Cinnamon custom keybinding, replacing the plain
# org.cinnamon.desktop.keybindings.wm close binding.
#
# A global (compositor-level) key grab intercepts the keypress before it
# ever reaches the focused app, so gnome-terminal's own Ctrl+Shift+W
# "close tab" accelerator would never fire once we also bind Ctrl+Shift+W
# globally - it would always close the whole window instead.
#
# Fix: if gnome-terminal is focused, re-deliver the keypress directly to
# that window via `xdotool key --window`, which uses XSendEvent instead of
# XTEST - a synthetic event sent straight to the target window, bypassing
# the passive key grab, so gnome-terminal's own close-tab binding runs.
# Closing the last tab already auto-closes the gnome-terminal window, so no
# separate "window close" fallback is needed for that case.
#
# For every other app, just close the window normally.
set -euo pipefail

win="$(xdotool getactivewindow)"
class="$(xprop -id "$win" WM_CLASS 2>/dev/null | sed -n 's/.*"\(.*\)"$/\1/p')"

if [[ "$class" == "Gnome-terminal" ]]; then
    xdotool key --window "$win" ctrl+shift+w
else
    wmctrl -ic "$win"
fi
