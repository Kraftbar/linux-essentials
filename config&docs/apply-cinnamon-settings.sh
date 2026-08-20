#!/usr/bin/env bash
# Applies plain (non-array, non-keybinding) gsettings preferences listed in
# cinnamon-settings.tsv. Unlike keybinding-additions.tsv these are scalar
# values (booleans, strings, numbers) with no future-default list to
# preserve, so a straight overwrite is correct here.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tsv="$dir/cinnamon-settings.tsv"

while IFS=$'\t' read -r schema key value; do
    [[ -z "$schema" || "$schema" == \#* ]] && continue
    gsettings set "$schema" "$key" "$value"
    echo "set:  $schema $key -> $value"
done < "$tsv"
