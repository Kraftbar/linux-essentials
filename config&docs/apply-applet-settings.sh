#!/usr/bin/env bash
# Applies Cinnamon applet settings listed in applet-settings.tsv (uuid, key,
# value). Applet settings live in ~/.config/cinnamon/spices/<uuid>/<uuid>.json,
# not in gsettings, so apply-cinnamon-settings.sh cannot reach them.
#
# Only the named key is touched; every other setting in the file is preserved,
# so this is safe to re-run and will not revert unrelated customisation.
#
# An empty value clears the setting - which is how a stock keybinding is freed
# for something else to grab.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tsv="$dir/applet-settings.tsv"
spices="$HOME/.config/cinnamon/spices"

while IFS=$'\t' read -r uuid key value; do
    [[ -z "${uuid:-}" || "$uuid" == \#* ]] && continue

    config="$spices/$uuid/$uuid.json"
    if [[ ! -f "$config" ]]; then
        echo "skip: $uuid has no config yet (open its settings once to create it)"
        continue
    fi

    KEY="$key" VALUE="$value" CONFIG="$config" python3 - <<'PY'
import json, os

config, key, value = os.environ["CONFIG"], os.environ["KEY"], os.environ["VALUE"]
with open(config) as handle:
    data = json.load(handle)

if key not in data:
    raise SystemExit(f"skip: {os.path.basename(config)} has no key {key!r}")

before = data[key].get("value")
if before == value:
    print(f"ok:   {key} already {value!r}")
    raise SystemExit(0)

data[key]["value"] = value
with open(config, "w") as handle:
    json.dump(data, handle, indent=4)
print(f"set:  {key} {before!r} -> {value!r}")
PY

    # The applet holds its keybinding grab until it is reloaded.
    gdbus call --session --dest org.Cinnamon --object-path /org/Cinnamon \
        --method org.Cinnamon.ReloadXlet "$uuid" "APPLET" >/dev/null 2>&1 \
        && echo "      reloaded $uuid" || echo "      could not reload $uuid (restart Cinnamon)"
done < "$tsv"
