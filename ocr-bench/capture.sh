#!/bin/bash
# Capture a screen region for the OCR benchmark and transcribe it by hand.
#
#   ./capture.sh terminal-ls
#   ./capture.sh vscode-dark
#
# Produces shots/<label>.png and opens an editor for shots/<label>.gt.txt.
# The ground truth must be typed by hand - never pasted from an OCR engine,
# or that engine becomes the reference for all the others.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SHOTS="$HERE/shots"
mkdir -p "$SHOTS"

label="${1:-}"
if [ -z "$label" ]; then
    echo "usage: capture.sh LABEL   (e.g. terminal-ls, vscode-dark, webpage-article)"
    exit 1
fi

png="$SHOTS/$label.png"
gt="$SHOTS/$label.gt.txt"

echo "Drag a region to capture..."
gnome-screenshot -a -f "$png"
if [ ! -f "$png" ]; then
    echo "cancelled, nothing saved"
    exit 0
fi

read -r w h < <(python3 -c "from PIL import Image;i=Image.open('$png');print(i.width,i.height)")
echo "saved $png (${w}x${h})"

[ -f "$gt" ] || : > "$gt"
xdg-open "$png" >/dev/null 2>&1 &
${EDITOR:-xed} "$gt" >/dev/null 2>&1

chars=$(wc -m < "$gt")
echo "ground truth: $chars characters"
[ "$chars" -lt 20 ] && echo "WARNING: that looks empty - the page will not score meaningfully"
