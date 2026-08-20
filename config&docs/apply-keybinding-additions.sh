#!/usr/bin/env bash
# Applies each accelerator listed in keybinding-additions.tsv.
#
# For array-valued keys (e.g. org.cinnamon.desktop.keybindings.wm close),
# the accelerator is merged into the *current* value instead of overwriting
# the whole array like keybindings.pl's import does. This way a new DE
# version can add its own default bindings for the same key and this script
# won't clobber them - it only adds the accelerator if it's not already
# there.
#
# For single-valued keys (e.g. gnome-terminal's next-tab/prev-tab, which
# hold exactly one accelerator, not a list), there's nothing to merge - the
# accelerator just replaces whatever's there.
#
# schema may be a relocatable schema:path pair, e.g.
# org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tsv="$dir/keybinding-additions.tsv"

while IFS=$'\t' read -r schema key accel; do
    [[ -z "$schema" || "$schema" == \#* ]] && continue

    current="$(gsettings get "$schema" "$key")"

    if [[ "$current" == *"$accel"* ]]; then
        echo "skip: $schema $key already has $accel"
        continue
    fi

    if [[ "$current" == \[*  || "$current" == "@as []" ]]; then
        if [[ "$current" == "@as []" || "$current" == "[]" ]]; then
            new="['$accel']"
        else
            new="${current%]}, '$accel']"
        fi
    else
        new="'$accel'"
    fi

    gsettings set "$schema" "$key" "$new"
    echo "set:  $schema $key -> $new"
done < "$tsv"
