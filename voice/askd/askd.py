#!/usr/bin/env python3
"""Ask Claude by voice from the iPhone/Watch ("Hey Siri, spør Claude").

ClaudeWatch -> gautenybo.no/ask.php -> this daemon on 127.0.0.1:7549 ->
`claude -p` -> short reply that the Watch reads aloud.

Auth: each device holds a P-256 key in its Secure Enclave and signs the raw
request body (X-Sig, DER, base64). The body carries ts and nonce, so a captured
request is dead after MAX_SKEW_S and can't be replayed inside it. Only public
keys live here, in ~/.config/askd/keys/<kid>.der. An unknown device sends
{"register": <SPKI DER b64>} signed by that key; it lands in pending/ until
approved with `askd-approve <kid>` after comparing the code on the Watch.

Follow-ups within IDLE_RESET_S resume the same Claude session. Runs as nybo
because Apache's www-data has no Claude login; only listens on localhost.
"""
import base64
import hashlib
import json
import os
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import load_der_public_key

PORT = int(os.environ.get("ASKD_PORT", "7549"))
IDLE_RESET_S = int(os.environ.get("ASKD_IDLE_RESET_S", "600"))
TIMEOUT_S = int(os.environ.get("ASKD_TIMEOUT_S", "120"))
WORKDIR = os.path.expanduser(os.environ.get("ASKD_WORKDIR", "~"))
KEY_DIR = os.path.expanduser("~/.config/askd/keys")
PENDING_DIR = os.path.expanduser("~/.config/askd/pending")
MAX_SKEW_S = 60
MAX_PENDING = 5
MAX_BODY = 20000

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
seen_nonces = {}


class AuthError(Exception):
    pass


def key_id(spki):
    return hashlib.sha256(spki).hexdigest()[:16]


def verify(spki, body, sig_b64):
    try:
        key = load_der_public_key(spki, default_backend())
        if not isinstance(key, ec.EllipticCurvePublicKey) or key.curve.name != "secp256r1":
            raise AuthError("not a P-256 key")
        key.verify(base64.b64decode(sig_b64), body, ec.ECDSA(hashes.SHA256()))
    except (InvalidSignature, ValueError, TypeError):
        raise AuthError("bad signature")


def check_fresh(req):
    now = time.time()
    for nonce, ts in list(seen_nonces.items()):
        if now - ts > 2 * MAX_SKEW_S:
            del seen_nonces[nonce]
    nonce = str(req.get("nonce", ""))
    if abs(now - float(req.get("ts", 0))) > MAX_SKEW_S:
        raise AuthError("stale request (check the Watch clock)")
    if len(nonce) < 16 or nonce in seen_nonces:
        raise AuthError("replayed request")
    seen_nonces[nonce] = now


def register(req, body, sig):
    spki = base64.b64decode(str(req["register"]))
    verify(spki, body, sig)          # proves the sender holds the private key
    check_fresh(req)
    kid = key_id(spki)
    if os.path.exists(os.path.join(KEY_DIR, kid + ".der")):
        return "approved", kid
    os.makedirs(PENDING_DIR, exist_ok=True)
    path = os.path.join(PENDING_DIR, kid + ".der")
    if not os.path.exists(path) and len(os.listdir(PENDING_DIR)) >= MAX_PENDING:
        raise AuthError("too many pending keys")
    with open(path, "wb") as f:
        f.write(spki)
    log("pending key %s" % kid)
    return "pending", kid


def authenticate(req, body, sig):
    kid = str(req.get("key", ""))
    path = os.path.join(KEY_DIR, kid + ".der")
    if not kid.isalnum() or not os.path.exists(path):
        raise AuthError("unknown key")
    with open(path, "rb") as f:
        verify(f.read(), body, sig)
    check_fresh(req)


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
            length = int(self.headers.get("Content-Length", 0))
            if length > MAX_BODY:
                raise AuthError("too large")
            body = self.rfile.read(length)
            sig = self.headers.get("X-Sig", "")
            req = json.loads(body.decode())
            with lock:
                if "register" in req:
                    state, kid = register(req, body, sig)
                    self.reply(200, {"ok": True, "state": state, "key": kid})
                    return
                authenticate(req, body, sig)
            text = str(req.get("text", "")).strip()
            if not text:
                raise ValueError("empty text")
            self.reply(200, {"ok": True, "reply": ask(text, bool(req.get("new")))})
        except AuthError as error:
            log("auth: %s" % error)
            self.reply(401, {"ok": False, "reply": "Ikke godkjent: %s" % error})
        except Exception as error:  # report anything to the caller, keep serving
            log("error: %s" % error)
            self.reply(500, {"ok": False, "reply": "Claude feilet: %s" % error})

    def reply(self, code, payload):
        data = json.dumps(payload, ensure_ascii=False).encode()
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
