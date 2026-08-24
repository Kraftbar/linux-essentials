#!/usr/bin/env python3
"""Send one image path to the OCR daemon and print the recognised text.

Split out of ocrclip so the shell never has to quote JSON. Text goes to stdout,
a one-line status to stderr, and any failure is a non-zero exit with the reason
on stderr.
"""
import json
import os
import socket
import sys
from pathlib import Path

def _runtime_dir() -> Path:
    """Where the daemon's socket lives.

    XDG_RUNTIME_DIR is not always set in the environment a desktop keybinding
    spawns, and falling straight back to /tmp silently looks in the wrong place
    while the daemon is listening perfectly well on /run/user/<uid>.
    """
    env = os.environ.get("XDG_RUNTIME_DIR")
    if env and Path(env).is_dir():
        return Path(env)
    run_user = Path(f"/run/user/{os.getuid()}")
    return run_user if run_user.is_dir() else Path("/tmp")


SOCKET_PATH = Path(os.environ.get("OCRD_SOCKET", _runtime_dir() / "ocrd.sock"))
# Recognition costs roughly 8ms per output character, so a dense selection
# can legitimately take minutes. The old 60s ceiling turned a slow success
# into a confusing "daemon did not reply".
TIMEOUT = float(os.environ.get("OCRD_TIMEOUT", "300"))


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if len(sys.argv) < 2:
        fail("usage: ocrsend.py IMAGE")
    image = str(Path(sys.argv[1]).resolve())

    if not SOCKET_PATH.is_socket():
        fail(f"daemon not running (no socket at {SOCKET_PATH})")

    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.settimeout(TIMEOUT)
    try:
        client.connect(str(SOCKET_PATH))
        client.sendall(json.dumps({"image": image}).encode() + b"\n")
        buffer = b""
        while b"\n" not in buffer:
            chunk = client.recv(65536)
            if not chunk:
                break
            buffer += chunk
    except socket.timeout:
        fail(f"daemon did not reply within {TIMEOUT:g}s")
    except ConnectionRefusedError:
        fail("daemon socket exists but nothing is listening")
    except OSError as exc:
        fail(f"socket error: {exc}")
    finally:
        client.close()

    if not buffer.strip():
        fail("empty reply from daemon")

    try:
        reply = json.loads(buffer.split(b"\n", 1)[0])
    except json.JSONDecodeError as exc:
        fail(f"malformed reply: {exc}")

    if not reply.get("ok"):
        fail(reply.get("error", "unknown daemon error"))

    sys.stdout.write(reply.get("text", ""))
    print(f"{reply.get('lines', 0)} lines in {reply.get('seconds', 0):.2f}s",
          file=sys.stderr)


if __name__ == "__main__":
    main()
