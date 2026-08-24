#!/bin/bash
# Push the screenshot set to loq (which holds the GPU and the engines), run each
# engine over it, and pull the text back into out/<engine>/<label>.txt.
#
#   ./run_engines.sh                  # every engine that is installed
#   ./run_engines.sh tesseract surya
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REMOTE=loq
RDIR='~/services/ocr-tests/shot-bench'

engines=("$@")
[ ${#engines[@]} -eq 0 ] && engines=(daemon)

shopt -s nullglob
pngs=("$HERE"/shots/*.png)
if [ ${#pngs[@]} -eq 0 ]; then
    echo "no screenshots in $HERE/shots - run capture.sh first"; exit 1
fi
echo "syncing ${#pngs[@]} screenshots to $REMOTE..."
ssh "$REMOTE" "mkdir -p $RDIR/shots"
rsync -q "${pngs[@]}" "$REMOTE:$RDIR/shots/"

for engine in "${engines[@]}"; do
    echo "=== $engine ==="
    case "$engine" in
    daemon)
        # Score whatever the locally deployed daemon is currently running.
        # This is the case that matters day to day: "is the thing I actually
        # installed still as good as the benchmark said?" The remote engines
        # below exist because tesseract and surya live on loq, not here.
        mkdir -p "$HERE/out/daemon"
        if [ ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ocrd.sock" ]; then
            echo "  daemon not running (systemctl --user start ocrd)"
        else
            for f in "$HERE"/shots/*.png; do
                b=$(basename "$f" .png)
                python3 "$HERE/../ocr/ocrsend.py" "$f" > "$HERE/out/daemon/$b.txt" 2>/dev/null \
                    && echo "  $b" || echo "  $b FAILED"
            done
        fi
        continue
        ;;
    tesseract)
        ssh "$REMOTE" "bash -s" <<REMOTE_EOF
set -u
export TESSDATA_PREFIX=\$HOME/services/ocr-tests/models/tessdata
mkdir -p $RDIR/out/tesseract
command -v tesseract >/dev/null || { echo "  tesseract not installed"; exit 0; }
for f in $RDIR/shots/*.png; do
    b=\$(basename "\$f" .png)
    tesseract "\$f" "$RDIR/out/tesseract/\$b" -l eng 2>/dev/null
done
echo "  done: \$(ls $RDIR/out/tesseract/*.txt 2>/dev/null | wc -l) files"
REMOTE_EOF
        ;;
    surya)
        ssh "$REMOTE" "bash -s" <<REMOTE_EOF
set -u
V=\$HOME/services/ocr-tests/surya-uv/.venv/bin/python
mkdir -p $RDIR/out/surya
[ -x "\$V" ] || { echo "  surya venv missing"; exit 0; }
RECOGNITION_BATCH_SIZE=4 DETECTOR_BATCH_SIZE=2 \$V - <<'PY'
import os, json, glob
from pathlib import Path
from PIL import Image
from surya.foundation import FoundationPredictor
from surya.recognition import RecognitionPredictor
from surya.detection import DetectionPredictor
out = Path(os.path.expanduser("~/services/ocr-tests/shot-bench/out/surya"))
out.mkdir(parents=True, exist_ok=True)
foundation = FoundationPredictor()
rec, det = RecognitionPredictor(foundation), DetectionPredictor()
for f in sorted(glob.glob(os.path.expanduser("~/services/ocr-tests/shot-bench/shots/*.png"))):
    image = Image.open(f).convert("RGB")
    preds = rec([image], det_predictor=det)
    lines = [l.text for l in preds[0].text_lines if l.confidence >= 0.5]
    (out / (Path(f).stem + ".txt")).write_text("\n".join(lines), encoding="utf-8")
    print("  ", Path(f).stem, len("\n".join(lines)), "chars")
PY
REMOTE_EOF
        ;;
    paddlevl)
        ssh "$REMOTE" "bash -s" <<REMOTE_EOF
set -u
V=\$HOME/services/ocr-tests/paddlevl-uv/.venv/bin/python
mkdir -p $RDIR/out/paddlevl
\$V -c "import paddleocr" 2>/dev/null || { echo "  paddleocr not installed yet"; exit 0; }
\$V - <<'PY'
import os, glob, re
from pathlib import Path
from paddleocr import PaddleOCRVL
out = Path(os.path.expanduser("~/services/ocr-tests/shot-bench/out/paddlevl"))
out.mkdir(parents=True, exist_ok=True)
pipe = PaddleOCRVL(pipeline_version="v1.6", device="gpu:0")
for f in sorted(glob.glob(os.path.expanduser("~/services/ocr-tests/shot-bench/shots/*.png"))):
    md = "\n".join(r.markdown if isinstance(r.markdown, str)
                   else r.markdown.get("markdown_texts", "") for r in pipe.predict(f))
    text = re.sub(r"^\s{0,3}#{1,6}\s*", "", md, flags=re.M)
    text = re.sub(r"\*\*|__", "", text)
    (out / (Path(f).stem + ".txt")).write_text(text.strip(), encoding="utf-8")
    print("  ", Path(f).stem, len(text), "chars")
PY
REMOTE_EOF
        ;;
    *) echo "  unknown engine: $engine" ;;
    esac
    mkdir -p "$HERE/out/$engine"
    rsync -q "$REMOTE:$RDIR/out/$engine/*.txt" "$HERE/out/$engine/" 2>/dev/null || true
done
echo; echo "pulled results into $HERE/out/"
