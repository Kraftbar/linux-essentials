#!/bin/bash
# Open a terminal with known text, capture ONLY that window, close it.
set -u
SP="$1"; OUT="$2"; PROFILE_ARGS="${3:-}"
TITLE="OCRBENCH-$$"
gnome-terminal --title="$TITLE" --geometry=76x9 -- bash -c "cat '$SP/realtest.txt'; sleep 45" &
sleep 2.5
WID=$(xdotool search --name "$TITLE" | head -1)
if [ -z "$WID" ]; then echo "window not found"; exit 1; fi
xdotool windowactivate "$WID"; sleep 1
gnome-screenshot -w -f "$OUT"
xdotool windowkill "$WID" 2>/dev/null
[ -s "$OUT" ] && python3 -c "
from PIL import Image; i=Image.open('$OUT'); print('captured', i.size)" || echo "capture failed"
