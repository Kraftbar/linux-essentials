#!/bin/bash
# Install the OCR daemon, its client, and the systemd user service.
#
# Idempotent: safe to re-run after editing the daemon, which is the normal way
# to deploy a change. Does not touch the keybinding - see the README, since that
# is a personal choice and lives in gsettings, not here.
#
#   ./install.sh              PaddleOCR-VL only (the default engine)
#   ./install.sh --with-surya also build the Surya venv, for A/B comparison
set -euo pipefail

HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SHARE="$HOME/.local/share/ocr-daemon"
BIN="$HOME/.local/bin"
UNIT="$HOME/.config/systemd/user"

WITH_SURYA=false
[ "${1:-}" = "--with-surya" ] && WITH_SURYA=true

mkdir -p "$SHARE" "$BIN" "$UNIT"

# The two engines cannot share a venv: surya-ocr pins transformers 4.x and
# paddleocr requires 5.x. Hence two, with the service choosing via ExecStart.
if [ ! -x "$SHARE/venv-paddle/bin/python" ]; then
    echo "building the PaddleOCR-VL venv (pulls ~5 GB)"
    python3 -m venv "$SHARE/venv-paddle"
    "$SHARE/venv-paddle/bin/pip" install --quiet --upgrade pip
    # Paddle publishes per-CUDA indexes and has no cu128; pick by driver.
    CUDA_INDEX="https://www.paddlepaddle.org.cn/packages/stable/cu130/"
    "$SHARE/venv-paddle/bin/pip" install "paddlepaddle-gpu>=3.3.1" \
        -i "$CUDA_INDEX" --extra-index-url https://pypi.org/simple
    "$SHARE/venv-paddle/bin/pip" install -U \
        "paddleocr[doc-parser]>=3.6.0" "transformers>=5.0.0"
fi

if [ "$WITH_SURYA" = true ] && [ ! -x "$SHARE/venv/bin/python" ]; then
    echo "building the Surya venv"
    python3 -m venv "$SHARE/venv"
    "$SHARE/venv/bin/pip" install --quiet --upgrade pip
    # surya-ocr 0.17.1 imports requests without declaring it, and breaks on
    # transformers 5.x (SuryaDecoderConfig loses pad_token_id). Both pins are
    # load-bearing: without them the daemon crashes on import.
    "$SHARE/venv/bin/pip" install "surya-ocr==0.17.1" "transformers==4.57.6" requests
fi

install -m 644 "$HERE/ocrd.py" "$SHARE/ocrd.py"
install -m 755 "$HERE/ocrclip" "$BIN/ocrclip"
install -m 644 "$HERE/ocrsend.py" "$BIN/ocrsend.py"
install -m 644 "$HERE/ocrd.service" "$UNIT/ocrd.service"

systemctl --user daemon-reload
systemctl --user enable --now ocrd.service
systemctl --user restart ocrd.service

echo
echo "waiting for the model to load..."
for _ in $(seq 1 90); do
    if [ -S "${XDG_RUNTIME_DIR:-/tmp}/ocrd.sock" ]; then
        echo "daemon ready"
        break
    fi
    if ! systemctl --user is-active --quiet ocrd; then
        echo "daemon failed to start:"
        journalctl --user -u ocrd --no-pager -n 15
        exit 1
    fi
    sleep 1
done

command -v xclip >/dev/null || {
    echo
    echo "NOTE: xclip is not installed, and nothing can reach the clipboard"
    echo "without it:  sudo apt install xclip"
}

echo
echo "test with:  ocrclip"
echo "logs:       journalctl --user -u ocrd -f"
