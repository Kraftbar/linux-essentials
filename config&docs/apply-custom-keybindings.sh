#!/usr/bin/env bash
# Applies custom Cinnamon keybindings (id, name, command, binding) listed in
# custom-keybindings.tsv. The custom-list array is merged (existing ids are
# kept, new ones appended) rather than overwritten, so this can be re-run
# without wiping out other custom keybindings added later outside this repo.
#
# `command` in the tsv is relative to the repo root and gets resolved to an
# absolute path here, since Cinnamon spawns it independent of any shell cwd.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(dirname "$dir")"
tsv="$dir/custom-keybindings.tsv"
base="/org/cinnamon/desktop/keybindings/custom-keybindings"

current_list="$(gsettings get org.cinnamon.desktop.keybindings custom-list)"

while IFS=$'\t' read -r id name command binding; do
    [[ -z "$id" || "$id" == \#* ]] && continue

    if [[ "$current_list" != *"'$id'"* ]]; then
        if [[ "$current_list" == "@as []" || "$current_list" == "[]" ]]; then
            current_list="['$id']"
        else
            current_list="${current_list%]}, '$id']"
        fi
        gsettings set org.cinnamon.desktop.keybindings custom-list "$current_list"
        echo "list: added $id -> $current_list"
    fi

    path="org.cinnamon.desktop.keybindings.custom-keybinding:$base/$id/"
    gsettings set "$path" name "'$name'"
    gsettings set "$path" command "'$repo_root/$command'"
    gsettings set "$path" binding "['$binding']"
    echo "set:  $id name=$name command=$repo_root/$command binding=$binding"
done < "$tsv"
