#!/usr/bin/env bash
# Reports everything already bound to a keybinding, so a new one can be chosen
# without colliding.
#
#   ./check-keybinding.sh '<Super><Shift>a'
#
# Checks gsettings schemas AND applet/desklet JSON config. The latter matters:
# the sound applet ships <Shift><Super>s as its "show menu" key, wins the grab,
# and is invisible to a gsettings-only search - which cost an afternoon.
#
# KNOWN BLIND SPOT: it cannot see X11 grabs taken by running applications, and
# X has no way to enumerate them. <Super><Shift>g reports free here and is not
# in dconf, any applet, or any Cinnamon extension, yet never reaches a custom
# keybinding on this machine. If a key reports FREE and still does nothing, an
# application owns it - test with another key rather than hunting the grabber.
set -uo pipefail

want="${1:-}"
[ -z "$want" ] && { echo "usage: check-keybinding.sh '<Super><Shift>a'"; exit 1; }

# Cinnamon writes modifiers in either order, so compare on a sorted key set.
canon() {
    # LC_ALL=C is load-bearing: the applet scan below sorts the same tokens in
    # Python, which orders by codepoint. Locale collation puts '<' elsewhere, so
    # without this the two halves of this script silently never agree.
    printf '%s' "$1" | tr 'A-Z' 'a-z' | grep -oE '<[a-z]+>|[a-z0-9]+$' \
        | LC_ALL=C sort | tr -d '\n'
}
target=$(canon "$want")
found=0

echo "checking: $want"

while read -r schema; do
    while IFS= read -r line; do
        value="${line#* * }"
        case "$value" in *"<"*) ;; *) continue ;; esac
        while read -r combo; do
            [ -z "$combo" ] && continue
            if [ "$(canon "$combo")" = "$target" ]; then
                echo "  TAKEN  gsettings: ${line%% *} ${line#* } "
                found=1
            fi
        done < <(printf '%s' "$value" | grep -oE "'[^']*<[^']*'" | tr -d "'")
    done < <(gsettings list-recursively "$schema" 2>/dev/null)
done < <(gsettings list-schemas)

# Custom keybindings live in a relocatable schema, which list-recursively
# cannot reach without being handed each path. They are exactly what a new
# binding is most likely to collide with, so enumerate them explicitly.
base="/org/cinnamon/desktop/keybindings/custom-keybindings"
for id in $(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null \
            | grep -oE "'[^']+'" | tr -d "'"); do
    path="org.cinnamon.desktop.keybindings.custom-keybinding:$base/$id/"
    name=$(gsettings get "$path" name 2>/dev/null | tr -d "'")
    for combo in $(gsettings get "$path" binding 2>/dev/null \
                   | grep -oE "'[^']*'" | tr -d "'"); do
        if [ "$(canon "$combo")" = "$target" ]; then
            echo "  TAKEN  custom keybinding: $id ($name) = $combo"
            found=1
        fi
    done
done

for config in "$HOME"/.config/cinnamon/spices/*/*.json; do
    [ -f "$config" ] || continue
    TARGET="$target" CONFIG="$config" python3 - <<'PY'
import json, os, re, sys

def canon(text):
    parts = re.findall(r"<[a-z]+>|[a-z0-9]+$", text.lower())
    return "".join(sorted(parts))

config, target = os.environ["CONFIG"], os.environ["TARGET"]
try:
    data = json.load(open(config))
except Exception:
    sys.exit(0)
for key, entry in (data.items() if isinstance(data, dict) else []):
    if not isinstance(entry, dict):
        continue
    value = entry.get("value")
    if not isinstance(value, str) or "<" not in value:
        continue
    for combo in value.split("::"):
        if combo and canon(combo) == target:
            print(f"  TAKEN  applet: {os.path.basename(os.path.dirname(config))} {key} = {combo!r}")
PY
done

[ "$found" = 0 ] && echo "  (no gsettings match)"
echo "done - applet matches, if any, are listed above"
