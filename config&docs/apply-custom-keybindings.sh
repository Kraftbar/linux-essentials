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

# csd-media-keys installs its passive grabs when it starts and does not reliably
# pick up ids added to custom-list afterwards. Without this nudge a new binding
# silently does nothing until the next login, which reads as "the hotkey is
# broken" rather than "the daemon has not seen it yet".
#
# The short wait is precautionary, not proven necessary: gsettings returns
# before dconf commits, so give the write a moment to land before csd re-reads.
sleep 1

if pid=$(pgrep -x csd-media-keys); then
    kill "$pid"
    sleep 2
    if pgrep -x csd-media-keys >/dev/null; then
        echo "grab: restarted csd-media-keys, bindings are live now"
    else
        setsid /usr/bin/csd-media-keys >/dev/null 2>&1 &
        sleep 2
        pgrep -x csd-media-keys >/dev/null \
            && echo "grab: restarted csd-media-keys, bindings are live now" \
            || echo "grab: csd-media-keys did not come back - log out and in"
    fi
else
    echo "grab: csd-media-keys not running - bindings apply at next login"
fi
