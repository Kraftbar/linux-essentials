#!/usr/bin/env bash
# Lighten the shade Cinnamon's lock screen paints over the wallpaper.
#
# cinnamon-screensaver hard-codes it in monitorView.py: 70 % black while the
# clock shows, 75-90 % black around the unlock box. There is no setting, so
# this edits the numbers in place and restarts the screensaver. Re-run it
# after a cinnamon-screensaver upgrade puts the stock file back, or with other
# values to tune it:  IDLE=0 MIDDLE=0.3 ./apply-lockscreen-shade.sh
set -euo pipefail

FILE=${FILE:-/usr/share/cinnamon-screensaver/monitorView.py}
IDLE=${IDLE:-0.15}      # while the clock is showing
EDGE=${EDGE:-0.25}      # top and bottom of the screen while the unlock box is up
MIDDLE=${MIDDLE:-0.40}  # behind the unlock box
SUDO=${SUDO-sudo}       # SUDO= to edit a file you own
RESTART=${RESTART:-1}   # RESTART=0 to only edit the file

[ -e "$FILE.orig" ] || $SUDO cp -p "$FILE" "$FILE.orig"   # stock copy, for reference
$SUDO sed -E -i \
    -e "s/(cr\.set_source_rgba\(0\.0, 0\.0, 0\.0, )[0-9.]+\)/\1$IDLE)/" \
    -e "s/(add_color_stop_rgba \(0, 0, 0, 0, )[0-9.]+\)/\1$EDGE)/" \
    -e "s/(add_color_stop_rgba \(1, 0, 0, 0, )[0-9.]+\)/\1$EDGE)/" \
    -e "s/(add_color_stop_rgba \(\.35, 0, 0, 0, )[0-9.]+\)/\1$MIDDLE)/" \
    -e "s/(add_color_stop_rgba \(\.65, 0, 0, 0, )[0-9.]+\)/\1$MIDDLE)/" \
    "$FILE"

hits=$(grep -c -E "set_source_rgba\(0\.0, 0\.0, 0\.0, $IDLE\)|\(0, 0, 0, 0, $EDGE\)|\(1, 0, 0, 0, $EDGE\)|\(\.35, 0, 0, 0, $MIDDLE\)|\(\.65, 0, 0, 0, $MIDDLE\)" "$FILE")
[ "$hits" -eq 5 ] || { echo "expected 5 shade values in $FILE, found $hits - file layout changed, nothing restarted" >&2; exit 1; }
python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' "$FILE"   # syntax check, writes no .pyc
echo "lock screen shade: idle $IDLE, unlock box $MIDDLE, edges $EDGE"

[ "$RESTART" = 1 ] || exit 0
# The daemon is D-Bus activated and its process is the python main script,
# so match on that rather than on a process name.
running() { pgrep -f 'cinnamon-screensaver-main\.py' >/dev/null; }
cinnamon-screensaver-command --exit 2>/dev/null || true
for _ in 1 2 3 4 5 6; do running || break; sleep 0.5; done
running || setsid cinnamon-screensaver >/dev/null 2>&1 &
sleep 1; running && echo "cinnamon-screensaver restarted" || echo "cinnamon-screensaver did not come back; it starts again at the next lock" >&2
