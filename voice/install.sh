#!/bin/bash
# Install the voice daemon, its toggle client, and the systemd user service.
# Idempotent: re-run to deploy edits.
set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SHARE="$HOME/.local/share/voice-daemon"
BIN="$HOME/.local/bin"
UNIT="$HOME/.config/systemd/user"
VOICE="${VOICED_VOICE:-en_US-lessac-medium}"

mkdir -p "$SHARE/voices" "$BIN" "$UNIT"

if [ ! -x "$SHARE/venv/bin/python" ]; then
    echo "creating venv at $SHARE/venv"
    python3 -m venv "$SHARE/venv"
    "$SHARE/venv/bin/pip" install --quiet --upgrade pip
    # webrtcvad-wheels, not webrtcvad: the latter imports pkg_resources, which
    # setuptools 81 removed, so it fails at import on a current venv.
    "$SHARE/venv/bin/pip" install faster-whisper piper-tts sounddevice webrtcvad-wheels
fi

if [ ! -f "$SHARE/voices/$VOICE.onnx" ]; then
    echo "downloading voice $VOICE"
    "$SHARE/venv/bin/python" -c "
from pathlib import Path
from piper.download_voices import download_voice
download_voice('$VOICE', Path.home()/'.local/share/voice-daemon/voices')
"
fi

install -m 644 "$HERE/voiced.py" "$SHARE/voiced.py"
install -m 755 "$HERE/voicetoggle" "$BIN/voicetoggle"
install -m 644 "$HERE/voiced.service" "$UNIT/voiced.service"

systemctl --user daemon-reload
systemctl --user enable --now voiced.service
systemctl --user restart voiced.service

echo
echo "waiting for the models to load..."
for _ in $(seq 1 60); do
    [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/voiced.sock" ] && { echo "daemon ready"; break; }
    if ! systemctl --user is-active --quiet voiced; then
        echo "daemon failed to start:"; journalctl --user -u voiced --no-pager -n 15; exit 1
    fi
    sleep 1
done

echo
echo "bind it:  cd '../config&docs' && ./apply-custom-keybindings.sh"
echo "logs:     journalctl --user -u voiced -f"
