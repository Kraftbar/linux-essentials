#!/usr/bin/env python3
"""Ask Claude by voice from the iPhone/Watch ("Hey Siri, spør Claude").

Siri Shortcut -> gautenybo.no/ask.php (LAN + token) -> this daemon on
127.0.0.1:7549 -> `claude -p` -> short reply that the Shortcut reads aloud.

Follow-ups within IDLE_RESET_S resume the same Claude session. Runs as nybo
because Apache's www-data has no Claude login; only listens on localhost.
"""
import json
import os
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("ASKD_PORT", "7549"))
IDLE_RESET_S = int(os.environ.get("ASKD_IDLE_RESET_S", "600"))
TIMEOUT_S = int(os.environ.get("ASKD_TIMEOUT_S", "120"))
WORKDIR = os.path.expanduser(os.environ.get("ASKD_WORKDIR", "~"))

# Same as voiced.py, plus the answer language: dictation arrives in Norwegian.
SPOKEN_STYLE = (
    "Your replies are read aloud by Siri's speech synthesiser, so write for the ear. "
    "HARD LIMIT: 50 words. Count them. A reply over 50 words is a failure, even "
    "if detail is lost - say the single most useful thing and stop. "
    "Use plain sentences: no markdown, no code blocks, no bullet lists, no emoji, "
    "no file paths unless essential, and never emit a long identifier character "
    "by character. Reply in the language the user spoke. The input is speech "
    "recognition, so guess past obvious mis-hearings."
)

lock = threading.Lock()
session = {"id": None, "last": 0.0}


def log(message):
    print("[askd] " + message, flush=True)


def ask(text, new):
    with lock:
        if new or time.time() - session["last"] > IDLE_RESET_S:
            session["id"] = None
        command = ["claude", "-p", text, "--output-format", "json",
                   "--append-system-prompt", SPOKEN_STYLE]
        if session["id"]:
            command += ["--resume", session["id"]]
        started = time.time()
        result = subprocess.run(command, cwd=WORKDIR, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, universal_newlines=True,
                                timeout=TIMEOUT_S)
        try:
            out = json.loads(result.stdout)
        except ValueError:
            raise RuntimeError((result.stderr or result.stdout).strip()[-300:])
        session["id"] = out.get("session_id") or session["id"]
        session["last"] = time.time()
        reply = (out.get("result") or "").strip()
        log("%.1fs %r -> %r" % (time.time() - started, text[:80], reply[:80]))
        return reply


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
            text = str(body.get("text", "")).strip()
            if not text:
                raise ValueError("empty text")
            reply, code = {"ok": True, "reply": ask(text, bool(body.get("new")))}, 200
        except Exception as error:  # report anything to the caller, keep serving
            log("error: %s" % error)
            reply, code = {"ok": False, "reply": "Claude feilet: %s" % error}, 500
        data = json.dumps(reply, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    log("listening on 127.0.0.1:%d" % PORT)
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
