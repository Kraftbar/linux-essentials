#!/usr/bin/env bash
# Bound to Ctrl+Super+Left/Right/Up/Down as Cinnamon custom keybindings.
#
# Plain Super+arrows stay on Cinnamon's native push-tile-left/right/up/down -
# custom keybindings can't reliably grab combos starting with bare Super, since
# they lose to the built-in "Super alone opens the menu" overlay-key behavior
# (confirmed: Super+Left just opened the menu once bound as a custom
# keybinding, even though the exact same mechanism worked fine for a
# non-Super combo). So the "restore from any direction" smart behavior lives
# on Ctrl+Super+arrows instead, which isn't affected by that.
#
# Windows-style snap normally lets you push a window to an edge, but restoring
# it to its original floating size only works from specific directions (e.g.
# only the opposite arrow). This makes every arrow direction restore the
# window if it's already tiled/maximized in any way, and only tile in the
# requested direction when it's currently floating.
#
# muffin reports any tiled or maximized state via _NET_WM_STATE
# (MAXIMIZED_VERT and/or MAXIMIZED_HORZ - confirmed empirically: a left/right
# half-tile sets MAXIMIZED_VERT, a top/bottom half-tile sets it too, floating
# has neither), so that's used to detect "already tiled".
#
# The actual tile-in-a-direction action still needs muffin's own
# push-tile-<dir> (on plain Super+<dir>), since re-implementing edge/
# multi-monitor geometry by hand would be fragile. Triggered here via a real
# XTEST keypress - WM-level compositor keybindings react to XTEST same as
# real hardware input (unlike GTK app-level accelerators, which ignore
# XSendEvent-based synthetic events - see smart-close.sh for that distinction).
set -uo pipefail

dir="$1"  # left | right | up | down
keysym="$(tr '[:lower:]' '[:upper:]' <<< "${dir:0:1}")${dir:1}"  # Left | Right | Up | Down

win="$(xdotool getactivewindow)"
state="$(xprop -id "$win" _NET_WM_STATE 2>/dev/null)"

if [[ "$state" == *MAXIMIZED_VERT* || "$state" == *MAXIMIZED_HORZ* ]]; then
    wmctrl -ir "$win" -b remove,maximized_vert,maximized_horz
else
    # Ctrl+Super (the trigger combo) may still be physically held when this
    # fires; a brief wait avoids clashing with the synthetic Super+<dir>.
    sleep 0.08
    xdotool key --clearmodifiers "super+$keysym"
fi
