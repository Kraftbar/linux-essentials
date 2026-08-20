#!/usr/bin/env bash
# Bound to Ctrl+Shift+W as a Cinnamon custom keybinding, replacing the plain
# org.cinnamon.desktop.keybindings.wm close binding.
#
# A global (compositor-level) key grab intercepts the keypress before it
# ever reaches the focused app, so gnome-terminal's own Ctrl+Shift+W
# "close tab" accelerator would never fire once we also bind Ctrl+Shift+W
# globally - it would always close the whole window instead.
#
# Fix: if gnome-terminal is focused, trigger its own close-tab action
# instead. `xdotool key --window` (XSendEvent) doesn't work here - GTK
# ignores synthetic events for shortcut activation as a security measure -
# so instead gnome-terminal's close-tab accelerator is rebound (see
# keybinding-additions.tsv) to the obscure, otherwise-unused Ctrl+Alt+W, and
# this script fires that combo for real via XTEST (indistinguishable from
# genuine hardware input, so GTK accepts it) while the terminal window has
# focus. Since it's not the combo Cinnamon has globally grabbed, it doesn't
# re-trigger this script. Closing the last tab already auto-closes the
# gnome-terminal window, so no separate "window close" fallback is needed.
#
# For every other app, just close the window normally.
set -uo pipefail

win="$(xdotool getactivewindow)"
class="$(xprop -id "$win" WM_CLASS 2>/dev/null | sed -n 's/.*"\(.*\)"$/\1/p')"

if [[ "$class" == "Gnome-terminal" ]]; then
    # Let the physically-held Ctrl+Shift (from triggering this hotkey)
    # release before injecting the synthetic Ctrl+Alt+W, otherwise the
    # real and synthetic modifier state can clash.
    sleep 0.15
    xdotool key --clearmodifiers ctrl+alt+w
else
    wmctrl -ic "$win"
fi
