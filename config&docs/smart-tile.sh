#!/usr/bin/env bash
# Bound to Super+Left/Right/Up/Down as Cinnamon custom keybindings, replacing
# the plain push-tile-left/right/up/down actions.
#
# Windows-style snap normally lets you push a window to an edge, but restoring
# it to its original floating size only works from specific directions (e.g.
# only the opposite arrow, or only Down). This makes every arrow direction
# restore the window if it's already tiled/maximized in any way, and only
# tile in the requested direction when it's currently floating.
#
# muffin reports any tiled or maximized state via _NET_WM_STATE
# (MAXIMIZED_VERT and/or MAXIMIZED_HORZ - confirmed empirically: a left/right
# half-tile sets MAXIMIZED_VERT, a top/bottom half-tile sets it too, floating
# has neither), so that's used to detect "already tiled".
#
# The actual tile-in-a-direction action still needs muffin's own
# push-tile-<dir>, since re-implementing edge/multi-monitor geometry by hand
# would be fragile. Those actions are rebound to the obscure, otherwise-unused
# Ctrl+Super+<dir> (see keybinding-additions.tsv) and triggered here via a
# real XTEST keypress - WM-level compositor keybindings react to XTEST same
# as real hardware input (unlike GTK app-level accelerators, which ignore
# XSendEvent-based synthetic events - see smart-close.sh for that distinction).
set -uo pipefail

dir="$1"  # left | right | up | down
keysym="$(tr '[:lower:]' '[:upper:]' <<< "${dir:0:1}")${dir:1}"  # Left | Right | Up | Down

win="$(xdotool getactivewindow)"
state="$(xprop -id "$win" _NET_WM_STATE 2>/dev/null)"

if [[ "$state" == *MAXIMIZED_VERT* || "$state" == *MAXIMIZED_HORZ* ]]; then
    wmctrl -ir "$win" -b remove,maximized_vert,maximized_horz
else
    sleep 0.15
    xdotool key --clearmodifiers "ctrl+super+$keysym"
fi
