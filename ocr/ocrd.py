#!/usr/bin/env python3
"""Resident OCR daemon.

The accurate engines cost seconds to import and load weights but well under a
second to run. Spawned per keypress that is an order of magnitude more expensive
than the work; kept resident it is imperceptible. So the model lives here, in a
process that starts with the session, and the hotkey talks to it over a unix
socket.

Two backends, selected with OCRD_ENGINE:

  paddlevl  PaddleOCR-VL 1.6 (default). Byte-exact on four of five screenshot
            fixtures, and the only engine that preserves indentation.
  surya     Surya. Better on prose scans, but drops every underscore, which
            wrecks identifiers, paths and URLs. Kept for A/B, not recommended.

See ../../ocr-bench and the LOQ bake-off for the measurements behind that.

Protocol, newline-delimited JSON over SOCK_STREAM:

    -> {"image": "/path/to.png"}          request
    <- {"ok": true, "text": "...",        reply
        "lines": 12, "seconds": 0.48}

Errors come back as {"ok": false, "error": "..."} rather than a dropped
connection, so the client can say something useful.
"""
import json
import os
import re
import signal
import socket
import sys
import threading
import time
from pathlib import Path

def _runtime_dir() -> Path:
    """Where to put the socket. Must agree with ocrsend.py, which resolves it
    the same way: XDG_RUNTIME_DIR is not always set in the environment a desktop
    keybinding spawns, and /tmp is the wrong answer when /run/user/<uid> exists.
    """
    env = os.environ.get("XDG_RUNTIME_DIR")
    if env and Path(env).is_dir():
        return Path(env)
    run_user = Path(f"/run/user/{os.getuid()}")
    return run_user if run_user.is_dir() else Path("/tmp")


SOCKET_PATH = Path(os.environ.get("OCRD_SOCKET", _runtime_dir() / "ocrd.sock"))
ENGINE = os.environ.get("OCRD_ENGINE", "paddlevl").lower()
CONFIDENCE = float(os.environ.get("OCRD_CONFIDENCE", "0.5"))

_backend = None
_lock = threading.Lock()


def log(message: str) -> None:
    print(f"[ocrd] {message}", flush=True)


class PaddleVLBackend:
    """PaddleOCR-VL 1.6 via the page-level document-parsing pipeline.

    Not the transformers example from the model card: that path is element-level
    and skips layout analysis, which on anything larger than a single line reads
    the page in the wrong order.
    """

    name = "paddlevl"

    def load(self):
        from paddleocr import PaddleOCRVL
        self.pipeline = PaddleOCRVL(
            pipeline_version="v1.6",
            device=os.environ.get("OCRD_DEVICE", "gpu:0"),
            # Cap parallel block recognition. Peak activation memory multiplies
            # with this, and it buys nothing here: requests are serialized by
            # _lock, and a hotkey never has two in flight.
            vl_rec_max_concurrency=1,
        )

    def run(self, image_path: str) -> list[str]:
        # markdown_ignore_labels=[] is load-bearing. The pipeline drops footnote
        # blocks from markdown by default; on a page that was a third footnotes
        # that silently cost 42 points of accuracy while looking like a
        # recognition failure.
        markdown = "\n".join(
            page.markdown if isinstance(page.markdown, str)
            else page.markdown.get("markdown_texts", "")
            for page in self.pipeline.predict(image_path, markdown_ignore_labels=[])
        )
        text = re.sub(r"^\s{0,3}#{1,6}\s*", "", markdown, flags=re.M)  # headings
        text = re.sub(r"\*\*|__", "", text)                            # emphasis
        text = re.sub(r"^\s*```.*$", "", text, flags=re.M)             # fences
        return text.strip("\n").splitlines()


class SuryaBackend:
    """Surya. Retained for comparison; see the underscore caveat above."""

    name = "surya"

    def load(self):
        from surya.foundation import FoundationPredictor
        from surya.recognition import RecognitionPredictor
        from surya.detection import DetectionPredictor
        foundation = FoundationPredictor()
        self.recognizer = RecognitionPredictor(foundation)
        self.detector = DetectionPredictor()

    def run(self, image_path: str) -> list[str]:
        from PIL import Image
        image = Image.open(image_path).convert("RGB")
        predictions = self.recognizer([image], det_predictor=self.detector)
        # The confidence floor is not cosmetic: Surya emits fluent nonsense for
        # noise regions and scores it 0.07-0.37 against 0.99+ for real text.
        return [
            line.text for line in predictions[0].text_lines
            if getattr(line, "confidence", 1.0) >= CONFIDENCE
        ]


BACKENDS = {"paddlevl": PaddleVLBackend, "surya": SuryaBackend}


def load_models() -> None:
    """Import and warm the backend. Called once, before we accept work."""
    global _backend
    if ENGINE not in BACKENDS:
        log(f"unknown OCRD_ENGINE {ENGINE!r}, expected one of {sorted(BACKENDS)}")
        sys.exit(2)

    start = time.time()
    _backend = BACKENDS[ENGINE]()
    _backend.load()
    log(f"engine {ENGINE} ready in {time.time() - start:.1f}s")


def recognize(image_path: str) -> dict:
    path = Path(image_path)
    if not path.is_file():
        return {"ok": False, "error": f"no such file: {image_path}"}

    start = time.time()
    # Backends are not thread-safe and share CUDA state, so only one request
    # runs at a time. Reject rather than queue: a queued request outlives the
    # client that owns its temp file, so it used to wait its turn and then fail
    # with "No such file", which is the worst of both outcomes.
    if not _lock.acquire(blocking=False):
        return {"ok": False, "error": "busy with another region, try again"}
    try:
        lines = _backend.run(str(path))
    except Exception as exc:
        return {"ok": False, "error": f"recognition failed: {exc}"}
    finally:
        _lock.release()

    return {
        "ok": True,
        "text": "\n".join(lines),
        "lines": len(lines),
        "engine": _backend.name,
        "seconds": round(time.time() - start, 3),
    }


def handle(conn: socket.socket) -> None:
    with conn:
        conn.settimeout(30)
        buffer = b""
        try:
            while b"\n" not in buffer:
                chunk = conn.recv(4096)
                if not chunk:
                    return
                buffer += chunk
            request = json.loads(buffer.split(b"\n", 1)[0])
        except Exception as exc:
            conn.sendall(json.dumps(
                {"ok": False, "error": f"bad request: {exc}"}).encode() + b"\n")
            return

        if request.get("ping"):
            conn.sendall(json.dumps(
                {"ok": True, "pong": True, "engine": ENGINE}).encode() + b"\n")
            return

        reply = recognize(request.get("image", ""))
        if reply["ok"]:
            log(f"{reply['lines']} lines in {reply['seconds']}s")
        else:
            log(f"error: {reply['error']}")
        try:
            conn.sendall(json.dumps(reply).encode() + b"\n")
        except BrokenPipeError:
            # The client gave up while we were working. Normal for a long
            # selection; not worth a traceback in the journal.
            log("client disconnected before the reply was sent")


def main() -> None:
    if SOCKET_PATH.exists():
        # A leftover socket from a killed daemon would block bind(); a live one
        # means we are a duplicate and should not steal it.
        probe = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            probe.connect(str(SOCKET_PATH))
            log(f"another daemon is already listening on {SOCKET_PATH}")
            sys.exit(1)
        except (ConnectionRefusedError, FileNotFoundError):
            SOCKET_PATH.unlink(missing_ok=True)
        finally:
            probe.close()

    load_models()

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(SOCKET_PATH))
    SOCKET_PATH.chmod(0o600)          # the socket is a text-extraction oracle
    server.listen(4)
    log(f"listening on {SOCKET_PATH}")

    def shutdown(*_):
        log("shutting down")
        server.close()
        SOCKET_PATH.unlink(missing_ok=True)
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    while True:
        try:
            conn, _ = server.accept()
        except OSError:
            break
        threading.Thread(target=handle, args=(conn,), daemon=True).start()


if __name__ == "__main__":
    main()
