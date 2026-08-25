#!/usr/bin/env python3
"""Resident voice daemon for hands-free Claude Code.

Whisper costs ~5.4s to load and ~0.1s to run; Piper costs ~1.0s to load and
synthesises at 14x realtime. Spawned per utterance the loading dominates
completely, so both models live here and the hotkey only toggles a session.

One session is a conversation: capture, endpoint on silence, transcribe, ask
Claude, speak the answer, listen again - until toggled off. Half duplex: the
microphone is closed while speaking, so the daemon never transcribes itself.

Protocol, newline-delimited JSON over a unix socket:

    -> {"toggle": true}     start a session, or stop the running one
    -> {"stop": true}       stop unconditionally
    -> {"ping": true}       health check, does not touch the models
    <- {"ok": true, "listening": false}

Speech is kept short on purpose: SPOKEN_STYLE is appended to Claude's system
prompt, capping replies near 50 words and requiring a yes/no question whenever
approval is needed, so an answer can be given naturally out loud.
"""
import json
import os
import queue
import signal
import socket
import subprocess
import sys
import threading
import time
import uuid
import wave
from pathlib import Path

SHARE = Path.home() / ".local/share/voice-daemon"
def _socket_path() -> Path:
    """Test the environment string, not Path(it): Path("") is Path("."), which
    is truthy and a directory, so an empty override silently resolved to the
    working directory - and shutdown then tried to unlink it."""
    override = os.environ.get("VOICED_SOCKET", "").strip()
    if override:
        return Path(override)
    runtime = os.environ.get("XDG_RUNTIME_DIR", "").strip()
    base = Path(runtime) if runtime and Path(runtime).is_dir() else Path(f"/run/user/{os.getuid()}")
    return (base if base.is_dir() else Path("/tmp")) / "voiced.sock"


SOCKET_PATH = _socket_path()

INPUT_DEVICE = os.environ.get("VOICED_INPUT") or None      # None = system default
MODEL = os.environ.get("VOICED_MODEL", "base")
LANGUAGE = os.environ.get("VOICED_LANGUAGE") or None        # None = autodetect
VOICE = os.environ.get("VOICED_VOICE", "en_US-lessac-medium")
WORKDIR = os.environ.get("VOICED_WORKDIR", str(Path.home()))
SKIP_PERMISSIONS = os.environ.get("VOICED_SKIP_PERMISSIONS", "1") not in ("0", "false", "no")

RATE = 16000
FRAME_MS = 30
FRAME = RATE * FRAME_MS // 1000
VAD_LEVEL = int(os.environ.get("VOICED_VAD", "2"))          # 0 lax .. 3 strict
SILENCE_MS = int(os.environ.get("VOICED_SILENCE_MS", "900"))
MAX_UTTERANCE_S = int(os.environ.get("VOICED_MAX_UTTERANCE_S", "30"))
START_TIMEOUT_S = int(os.environ.get("VOICED_START_TIMEOUT_S", "20"))

SPOKEN_STYLE = (
    "Your replies are read aloud by a speech synthesiser, so write for the ear. "
    "HARD LIMIT: 50 words. Count them. A reply over 50 words is a failure, even "
    "if detail is lost - say the single most useful thing and stop. "
    "Use plain sentences: no markdown, no code "
    "blocks, no bullet lists, no file paths unless essential, and never emit a "
    "long identifier character by character. "
    "If you need the user's approval before doing something, end your reply with "
    "a single clear yes or no question, so they can answer out loud."
)


def log(message: str) -> None:
    print(f"[voiced] {message}", flush=True)


def notify(title: str, body: str = "") -> None:
    """State has to be visible: a hands-free session is otherwise invisible."""
    try:
        subprocess.run(["notify-send", "-a", "Voice", "-t", "2500", title, body],
                       check=False, timeout=3)
    except Exception:
        pass


class Session:
    """One hands-free conversation. Runs on its own thread until stopped."""

    def __init__(self, models):
        self.models = models
        self.stop_flag = threading.Event()
        self.thread = None
        # A fixed id per session keeps context across turns; a new one per
        # session keeps unrelated conversations from bleeding together.
        self.session_id = str(uuid.uuid4())

    def start(self):
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()

    def stop(self):
        self.stop_flag.set()

    @property
    def running(self):
        return self.thread is not None and self.thread.is_alive()

    def _run(self):
        notify("Voice session started", "Speak - press the key again to stop")
        log(f"session {self.session_id[:8]} started")
        first = True
        turn = 0
        try:
            while not self.stop_flag.is_set():
                audio = self._listen(first)
                first = False
                if self.stop_flag.is_set():
                    break
                if audio is None:
                    log("no speech, ending session")
                    notify("Voice session ended", "Nothing heard")
                    break

                text = self.models.transcribe(audio)
                if not text.strip():
                    continue
                log(f"heard: {text[:80]}")
                notify("Heard", text[:120])

                reply = self.models.ask(text, self.session_id, turn == 0)
                turn += 1
                if self.stop_flag.is_set():
                    break
                if not reply.strip():
                    reply = "Sorry, I did not get an answer."
                log(f"reply: {reply[:80]}")
                self.models.speak(reply, self.stop_flag)
        except Exception as exc:
            log(f"session error: {exc}")
            notify("Voice session failed", str(exc)[:120])
        finally:
            log(f"session {self.session_id[:8]} ended")
            if self.stop_flag.is_set():
                notify("Voice session ended")

    def _listen(self, first):
        """Record until the speaker stops. Returns int16 mono bytes, or None."""
        import audioop
        import sounddevice as sd
        import webrtcvad

        vad = webrtcvad.Vad(VAD_LEVEL)
        frames, voiced, silence_ms, waited_ms = [], False, 0, 0
        loudest, seen = 0, 0
        chunks = queue.Queue()

        def callback(indata, _frames, _time, status):
            chunks.put(bytes(indata))

        with sd.RawInputStream(samplerate=RATE, blocksize=FRAME, dtype="int16",
                               channels=1, device=INPUT_DEVICE, callback=callback):
            while not self.stop_flag.is_set():
                try:
                    frame = chunks.get(timeout=0.5)
                except queue.Empty:
                    continue
                if len(frame) != FRAME * 2:
                    continue

                # Level telemetry: "it heard nothing" has two very different
                # causes - no audio reaching us, or audio the VAD refuses to
                # call speech - and the peak tells them apart immediately.
                peak = audioop.max(frame, 2)
                loudest = max(loudest, peak)
                seen += 1
                if seen % 100 == 0:
                    log(f"listening: peak {loudest} ({100*loudest/32767:.1f}%), "
                        f"voiced_frames={len(frames)}")

                speaking = vad.is_speech(frame, RATE)
                if speaking:
                    voiced = True
                    silence_ms = 0
                    frames.append(frame)
                elif voiced:
                    # Keep trailing silence: cutting at the exact boundary
                    # clips word endings and Whisper mishears them.
                    frames.append(frame)
                    silence_ms += FRAME_MS
                    if silence_ms >= SILENCE_MS:
                        return b"".join(frames)
                else:
                    waited_ms += FRAME_MS
                    # Only give up while waiting for the *first* word; once the
                    # conversation is going, a long pause is just thinking.
                    limit = START_TIMEOUT_S * 1000 if first else START_TIMEOUT_S * 2000
                    if waited_ms >= limit:
                        log(f"gave up after {waited_ms/1000:.0f}s, loudest frame "
                            f"{loudest} ({100*loudest/32767:.1f}%) - the VAD never "
                            f"called it speech")
                        return None

                if len(frames) * FRAME_MS >= MAX_UTTERANCE_S * 1000:
                    return b"".join(frames)
        return None


def session_label(text: str) -> str:
    """A short display name for the /resume picker, built from what was said."""
    words = " ".join(text.split())
    if len(words) > 40:
        words = words[:39].rstrip() + "\u2026"
    return f"voice: {words}" if words else "voice"


class Models:
    """Whisper, Piper and the Claude call. Loaded once, reused."""

    def __init__(self):
        self.lock = threading.Lock()

    def load(self):
        start = time.time()
        from faster_whisper import WhisperModel
        from piper import PiperVoice

        self.whisper = WhisperModel(MODEL, device="cpu", compute_type="int8",
                                    num_workers=4)
        voice_path = SHARE / "voices" / f"{VOICE}.onnx"
        if not voice_path.is_file():
            raise SystemExit(f"voice model missing: {voice_path}")
        self.piper = PiperVoice.load(str(voice_path))
        log(f"models ready in {time.time() - start:.1f}s "
            f"(whisper {MODEL} cpu/int8, piper {VOICE})")
        log(f"permissions: {'SKIPPED (yolo)' if SKIP_PERMISSIONS else 'enforced'}, "
            f"working directory {WORKDIR}")

    def transcribe(self, audio: bytes) -> str:
        import tempfile
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as handle:
            path = handle.name
        try:
            with wave.open(path, "wb") as out:
                out.setnchannels(1)
                out.setsampwidth(2)
                out.setframerate(RATE)
                out.writeframes(audio)
            segments, _ = self.whisper.transcribe(
                path, language=LANGUAGE, vad_filter=True, beam_size=1)
            return " ".join(segment.text for segment in segments).strip()
        finally:
            os.unlink(path)

    def ask(self, text: str, session_id: str, first_turn: bool) -> str:
        """One turn.

        --session-id creates a session and refuses to be reused: a second call
        with the same id fails with "Session ID is already in use". Continuing
        is --resume. So the first turn names the session and every later turn
        resumes it, which is what carries context between utterances.
        """
        command = ["claude", "-p", text, "--append-system-prompt", SPOKEN_STYLE]
        if first_turn:
            # Without a name these sit in the /resume picker as untitled rows
            # among every other session in this directory. The opening utterance
            # is the only thing that tells them apart, so use it as the label.
            command += ["--session-id", session_id, "--name", session_label(text)]
        else:
            command += ["--resume", session_id]
        if SKIP_PERMISSIONS:
            # Requested deliberately: hands-free is unusable if every tool call
            # stops for a prompt nobody can see. Note what this gives up - the
            # spoken yes/no convention in SPOKEN_STYLE becomes the ONLY thing
            # between a misheard sentence and a command running. Whisper does
            # mishear. Set VOICED_SKIP_PERMISSIONS=0 to put the prompts back.
            command.append("--dangerously-skip-permissions")
        try:
            result = subprocess.run(command, capture_output=True, text=True,
                                    timeout=180, cwd=WORKDIR)
        except subprocess.TimeoutExpired:
            return "That took too long, so I stopped waiting."
        if result.returncode != 0:
            detail = (result.stderr or "").strip().splitlines()
            return f"Claude failed. {detail[-1][:120] if detail else ''}"
        return result.stdout.strip()

    def speak(self, text: str, stop_flag: threading.Event) -> None:
        """Synthesise and play. The microphone is not open during this, which
        is what keeps the daemon from transcribing its own voice."""
        import sounddevice as sd
        import numpy as np
        import io

        buffer = io.BytesIO()
        with wave.open(buffer, "wb") as out:
            self.piper.synthesize_wav(text, out)
        buffer.seek(0)
        with wave.open(buffer, "rb") as source:
            rate = source.getframerate()
            data = np.frombuffer(source.readframes(source.getnframes()),
                                 dtype=np.int16)
        sd.play(data, rate)
        while sd.get_stream().active:
            if stop_flag.is_set():
                sd.stop()
                return
            time.sleep(0.05)


class Daemon:
    def __init__(self):
        self.models = Models()
        self.session = None
        self.lock = threading.Lock()

    def toggle(self) -> dict:
        with self.lock:
            if self.session and self.session.running:
                self.session.stop()
                return {"ok": True, "listening": False, "action": "stopped"}
            self.session = Session(self.models)
            self.session.start()
            return {"ok": True, "listening": True, "action": "started"}

    def stop(self) -> dict:
        with self.lock:
            if self.session and self.session.running:
                self.session.stop()
                return {"ok": True, "listening": False, "action": "stopped"}
            return {"ok": True, "listening": False, "action": "idle"}

    def status(self) -> dict:
        running = bool(self.session and self.session.running)
        return {"ok": True, "listening": running}


def handle(conn, daemon):
    with conn:
        conn.settimeout(10)
        buffer = b""
        try:
            while b"\n" not in buffer:
                chunk = conn.recv(4096)
                if not chunk:
                    return
                buffer += chunk
            request = json.loads(buffer.split(b"\n", 1)[0])
        except Exception as exc:
            conn.sendall(json.dumps({"ok": False, "error": str(exc)}).encode() + b"\n")
            return

        if request.get("ping"):
            reply = {"ok": True, "pong": True, **daemon.status()}
        elif request.get("toggle"):
            reply = daemon.toggle()
        elif request.get("stop"):
            reply = daemon.stop()
        elif request.get("status"):
            reply = daemon.status()
        else:
            reply = {"ok": False, "error": "expected toggle, stop, status or ping"}
        try:
            conn.sendall(json.dumps(reply).encode() + b"\n")
        except BrokenPipeError:
            pass


def main():
    if SOCKET_PATH.exists():
        probe = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            probe.connect(str(SOCKET_PATH))
            log(f"another daemon is listening on {SOCKET_PATH}")
            sys.exit(1)
        except (ConnectionRefusedError, FileNotFoundError):
            SOCKET_PATH.unlink(missing_ok=True)
        finally:
            probe.close()

    daemon = Daemon()
    daemon.models.load()

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(SOCKET_PATH))
    SOCKET_PATH.chmod(0o600)      # this socket turns the microphone on
    server.listen(4)
    log(f"listening on {SOCKET_PATH}")

    def shutdown(*_):
        if daemon.session:
            daemon.session.stop()
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
        threading.Thread(target=handle, args=(conn, daemon), daemon=True).start()


if __name__ == "__main__":
    main()
