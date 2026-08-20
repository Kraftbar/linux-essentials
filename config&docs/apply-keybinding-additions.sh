#!/usr/bin/env bash
# Merges each accelerator listed in keybinding-additions.tsv into the
# *current* value of its gsettings array, instead of overwriting the whole
# array like keybindings.pl's import does. This way a new DE version can add
# its own default bindings for the same key and this script won't clobber
# them - it only adds the accelerator if it's not already there.
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

    if [[ "$current" == "@as []" || "$current" == "[]" ]]; then
        new="['$accel']"
    else
        new="${current%]}, '$accel']"
    fi

    gsettings set "$schema" "$key" "$new"
    echo "set:  $schema $key -> $new"
done < "$tsv"
