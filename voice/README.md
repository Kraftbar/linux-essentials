# Hands-free voice interface for Claude Code

Press `Super+Shift+V`, talk, listen. Press it again to end the session.

Within a session it is genuinely hands-free: it hears you stop talking, answers
aloud, and listens again. The hotkey only opens and closes the conversation.

## Why a daemon (again)

Whisper takes ~5.4s to load and ~0.1s to run; Piper takes ~1.0s to load and
synthesises at 14x realtime. Per-utterance spawning would be almost entirely
model loading, so both stay resident and the hotkey just writes to a socket.

## Latency

| stage | cost |
|---|---:|
| speech recognition, warm | 0.1-1s |
| **`claude -p`** | **3.6-5.6s** |
| speech synthesis, 50 words | ~0.5s |

**5-7s per turn, and the middle term dominates.** Nothing local can fix that;
it is the model call. Recognition and synthesis together are under a fifth of it.

## Why CPU

The 8 GB card is fully committed to `ocrd`, which holds ~7.2 GB resident. There
is no room for Whisper beside it. `base` with int8 on a Ryzen 3700X transcribes
far faster than realtime, so the GPU buys nothing here and both features stay
available at once.

## Speaking style

`SPOKEN_STYLE` is appended to Claude's system prompt: 50 word limit, no markdown
or code blocks, and - when approval is needed - a closing yes/no question so it
can be answered out loud.

Measured, this lands at **53-55 words** against the 50 asked for. It is a prompt
constraint, not an enforced one, so expect roughly 10% overshoot. The approval
convention holds up well: asked to delete a 5 GB directory, it checked the
target, explained the risk, and ended "Shall I print the exact remove command
for you to run?"

## Permissions are skipped

The daemon passes `--dangerously-skip-permissions`, because hands-free is
unusable if tool calls stop for a prompt nobody is looking at.

Be clear about what that costs. The spoken yes/no convention is now the *only*
thing between a misheard sentence and a command running, and it is a prompt
instruction rather than an enforced check - Claude following a convention, not
the harness stopping anything. Whisper does mishear: during testing it
transcribed a reply as "Nothing." In a terminal you see each action before it
happens; hands-free you may not be looking at the screen at all.

Two ways to bound it:

    VOICED_SKIP_PERMISSIONS=0    restore permission prompts
    VOICED_WORKDIR=/some/project  limit what a misheard request can reach

The startup log always states which mode is active, so it is never a silent
default:

    [voiced] permissions: SKIPPED (yolo), working directory /home/nybo

Note `--ask-for-approval never` is Codex CLI syntax and does nothing here; the
Claude Code equivalents are `--dangerously-skip-permissions` and
`--permission-mode bypassPermissions`.

## Session continuation

The first turn passes `--session-id <uuid>`; every later turn passes
`--resume <uuid>`. This is not interchangeable: reusing `--session-id` fails
with "Session ID is already in use", so a naive implementation works for
exactly one utterance and then breaks.

## Install

    ./install.sh
    cd "../config&docs" && ./apply-custom-keybindings.sh

The installer builds the venv, downloads the Piper voice, and enables the user
service. It installs `webrtcvad-wheels` rather than `webrtcvad`: the original
imports `pkg_resources`, which setuptools 81 removed, so it fails at import.

## Tuning

Environment variables, set in `voiced.service`:

| variable | default | effect |
|---|---|---|
| `VOICED_MODEL` | `base` | whisper size; `small` is more accurate and slower |
| `VOICED_VOICE` | `en_US-lessac-medium` | piper voice |
| `VOICED_INPUT` | unset | microphone; unset uses the system default |
| `VOICED_LANGUAGE` | unset | force a language; unset autodetects |
| `VOICED_VAD` | `2` | 0 lax to 3 strict |
| `VOICED_SILENCE_MS` | `900` | silence that ends an utterance |
| `VOICED_WORKDIR` | `$HOME` | directory Claude runs in |

## Audio notes

Half duplex on purpose: the microphone is closed while speaking, so the daemon
never transcribes its own voice. This matters if output goes to speakers rather
than a headset.

**Pick the microphone before touching gain.** A Logitech C922 webcam mic at
desk distance works; a headset boom mic left dangling a metre away does not,
and no amount of gain fixes it - a boom mic is built for 2 cm, so at a metre it
is roughly 30 dB down and you are amplifying the room as much as the voice.
Both gain layers ended up near maximum chasing that, and the WebRTC VAD still
refused to call the result speech.

Working configuration:

    pactl set-default-source alsa_input.usb-046d_C922_...analog-stereo
    pactl set-source-volume  <that source> 70%

The same webcam clipped at full scale at 150%, so it wants *less* than unity -
the opposite of the far-field headset.

**Adjust gain through `pactl`, not `amixer`.** PulseAudio re-syncs its own
source volume when an ALSA capture control changes, so raising ALSA gain can
*lower* what actually gets recorded - which happened twice here: +26 dB of ALSA
gain took the level from 2.2% down to 0.9%.

Calibrate with `./calibrate.sh`, which records while you speak and reports the
peak against the range Whisper wants (roughly 25-60% of full scale).

Working values on this machine, reached from a first reading of 2.2%:

    pactl set-source-volume <source> 300%     # +28.6 dB
    amixer -c 1 sset Capture 100%             # +30 dB
    amixer -c 1 sset "Front Mic Boost" 3      # +30 dB

That gives ~45% peak on normal speech. Both layers are near maximum, so a
quieter mic or a greater speaking distance would need better hardware rather
than more gain.

The desktop shipped at ALSA +60 dB and clipped at full scale on room noise
alone, which Whisper also handles badly - so both extremes were wrong, and the
only way to find the middle was to measure with a voice.

## If the hotkey seems dead

`voicetoggle` logs one line per invocation to
`$XDG_RUNTIME_DIR/voicetoggle.log`. No line means the keypress never arrived -
almost always `csd-media-keys` not having re-grabbed, which
`apply-custom-keybindings.sh` now handles.
