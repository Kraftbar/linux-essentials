#!/bin/bash
# Records while you speak, then says whether the level suits Whisper.
#
#   ./calibrate.sh
#
# Clipping is the failure that matters: Whisper degrades badly on saturated
# input, and the desktop shipped at +60 dB (capture +30, mic boost +30), which
# clipped at full scale on nothing louder than room noise.
set -u
SECONDS_TO_RECORD="${1:-5}"
WAV=$(mktemp --tmpdir calibrate-XXXXXX.wav)

echo "Speak normally for ${SECONDS_TO_RECORD}s - say a sentence or two."
echo
sleep 0.5
timeout $((SECONDS_TO_RECORD + 2)) parecord --file-format=wav \
    --rate=16000 --channels=1 "$WAV" 2>/dev/null &
pid=$!
for i in $(seq "$SECONDS_TO_RECORD" -1 1); do printf "\r  recording... %ds " "$i"; sleep 1; done
kill $pid 2>/dev/null; wait 2>/dev/null
printf "\r%40s\r" " "

python3 - "$WAV" <<'PY'
import sys, wave, audioop, subprocess

with wave.open(sys.argv[1]) as w:
    data = w.readframes(w.getnframes())
    width, rate = w.getsampwidth(), w.getframerate()

peak = audioop.max(data, width)
rms = audioop.rms(data, width)
peak_pct = 100 * peak / 32767
clipped = peak >= 32700

print(f"  peak {peak:5d} ({peak_pct:5.1f}%)   rms {rms:5d}")
print()
if clipped:
    verdict = "CLIPPING - lower the gain, Whisper will mishear this"
elif peak_pct < 8:
    verdict = "too quiet - raise the gain"
elif peak_pct < 25:
    verdict = "quiet but usable - a little more gain would help"
elif peak_pct <= 85:
    verdict = "good - this is the range Whisper wants"
else:
    verdict = "hot, close to clipping - back the gain off a notch"
print(f"  {verdict}")
PY

echo
echo "current gain:"
# PulseAudio is the layer that decides what parecord actually gets. Changing the
# ALSA Capture control makes PA re-sync its own volume, so raising ALSA gain can
# LOWER the recorded level - which is exactly what happened here once. Adjust
# through pactl; treat the ALSA boost as a coarse setting you leave alone.
SRC=$(pactl get-default-source 2>/dev/null)
echo "  device      $SRC"
printf "  PulseAudio  %s\n" "$(pactl list sources 2>/dev/null | awk "/Name: $SRC/,/^\$/" | grep -m1 -E "^[[:space:]]+Volume:" | sed 's/^[[:space:]]*//')"
echo
echo "adjust with:  pactl set-source-volume $SRC 70%"
echo "              values above 100% are allowed; below 100% to tame a hot mic"
rm -f "$WAV"
