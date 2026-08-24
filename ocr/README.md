# Screenshot OCR

Select a region of the screen, get its text on the clipboard. Replaces the old
`scripts/myocrclip`, which shelled out to Tesseract per invocation.

    ocrclip              # drag a region
    ocrclip shot.png     # or OCR an existing image

Bound to `Super+Shift+C`, the binding `myocrclip` used.

## Why a daemon

The accurate engines cost seconds to load weights but well under a second to
run. Spawned per keypress that is an order of magnitude more expensive than the
work; kept resident it is imperceptible.

| | cold start | 900x300 crop |
|---|---:|---:|
| Tesseract (CPU) | ~0.05s | 0.40s |
| PaddleOCR-VL, per-invocation | 7.3s | ~8s total |
| **PaddleOCR-VL, resident** | paid once at login | **0.96s** |

The daemon is what makes an accurate engine usable on a hotkey at all. Without
it you are choosing between a fast bad answer and an unusable good one.

## Why PaddleOCR-VL

Measured on `../ocr-bench`, against hand-typed ground truth for screen captures.
Character / word accuracy, scored strictly - smart quotes count as errors,
because a curly quote pasted into code is a syntax error:

| engine | pooled char | pooled word |
|---|---:|---:|
| **PaddleOCR-VL 1.6** | **99.9%** | **99.2%** |
| Tesseract | 97.3% | 71.3% |
| Surya | 92.3% | 20.1% |

PaddleOCR-VL was byte-exact on four of the five fixtures, and is the only engine
tested that preserves leading indentation.

**Surya drops underscores - all of them.** 0 of 12 survived a real
gnome-terminal capture; 0 of 11 across two fonts on identifier renders. It
reproduces at 19px and 34px, monospace and serif, on PIL renders and genuine
antialiased X11 output alike, so it is the model rather than the rendering.

That defect hides in character accuracy, which stays at 92-98% because only a
fraction of characters are affected, and is catastrophic in word accuracy,
because every identifier, path and URL becomes two wrong tokens.

**This is worth knowing because the obvious benchmark said the opposite.** The
LOQ bake-off (`~/services/ocr-tests/frak-test` on `loq`) ranks Surya first, and
correctly so - for 19th-century Danish-Norwegian book scans, which contain no
underscores whatsoever. Picking an engine from that benchmark gives you the one
that mangles code.

Tesseract keeps most underscores but substitutes smart quotes and inserts
spurious spaces (`MAX _RETRY_COUNT`, `self. private _method`).

### Caveat

All five fixtures are code or identifiers. That settles the dominant use, and
says nothing about prose, UI chrome, tables, low contrast or non-English text.
`../ocr-bench/README.md` lists the shots that would close those gaps.

## Install

    ./install.sh                 # PaddleOCR-VL only
    ./install.sh --with-surya    # also build the Surya venv, for A/B

Creates a venv under `~/.local/share/ocr-daemon`, installs `ocrclip` into
`~/.local/bin`, and enables the `ocrd` user service. Re-run to deploy edits.

The two engines get **separate venvs**: `surya-ocr` pins transformers 4.x and
`paddleocr` requires 5.x, so they cannot coexist. The service picks one via
`ExecStart`.

Also needs `xclip`, which Mint does not ship:

    sudo apt install xclip

### Hotkey

Not wired by `install.sh`, since it lives in gsettings. The repo's merge-based
helper adds it without disturbing bindings added elsewhere:

    cd "../config&docs" && ./apply-custom-keybindings.sh

`Super+Shift+S` collides with Cinnamon out of the box: the sound applet ships
with it as its `keyOpen` "show menu" shortcut, and the applet wins, so the
hotkey silently opens the volume menu instead. That binding lives in the
applet's own JSON rather than gsettings, so it does not show up when grepping
schemas for the conflict. Clear it with:

    ./apply-applet-settings.sh

The sound menu is still reachable by clicking the panel icon.

## Operating it

    systemctl --user status ocrd
    systemctl --user restart ocrd          # after editing ocrd.py
    journalctl --user -u ocrd -f           # per-request timings

To A/B the engines, edit `OCRD_ENGINE` **and** `ExecStart` in `ocrd.service` -
both, since the engines live in different venvs.

The daemon holds GPU memory while resident. If that matters during a game,
`systemctl --user stop ocrd`; `ocrclip` reports the daemon being down rather
than failing silently.

## Speed scales with text, not image size

Recognition costs roughly **8ms per output character**, because the cost is
autoregressive token generation rather than image encoding:

| selection | output | time |
|---|---:|---:|
| a few lines of code | 192 chars | 1.6s |
| a 1720x1000 wall of code, 40 lines | 2699 chars | 22s |

Downscaling does not help. `max_pixels` at 2M, 1M and 500k all produced
identical output in identical time - the pixels were never the bottleneck.

Nor does parallelism, on this hardware: `vl_rec_max_concurrency=4` runs out of
VRAM on an 8 GB card that is also driving a display. It is pinned to 1.

The practical consequence is that grabbing a line, an error message or a
paragraph is comfortable, and grabbing a whole screen of text takes a minute or
more. `ocrclip` shows a "Reading selection..." notification up front so a long
run does not look like a dead hotkey, and the client waits up to 300s.

A second press while one is running is **rejected**, not queued: a queued
request outlives the client that owns its temp file, so it used to wait its turn
and then fail with "No such file".

## Protocol

Newline-delimited JSON over a unix socket at `$XDG_RUNTIME_DIR/ocrd.sock`:

    -> {"image": "/path/to.png"}
    <- {"ok": true, "text": "...", "lines": 12, "engine": "paddlevl",
        "seconds": 0.96}

Failures come back as `{"ok": false, "error": "..."}` rather than a dropped
connection. The socket is mode 0600: it extracts text from any path handed to
it, so it should not be readable by other users.

`{"ping": true}` returns `{"ok": true, "pong": true, "engine": "..."}` without
touching the GPU, for health checks.

## Two traps worth knowing

**`markdown_ignore_labels=[]` is load-bearing.** PaddleOCR-VL's pipeline
excludes `footnote` blocks from markdown output by default. On a benchmark page
that was a third footnotes, this silently cost 42 points of accuracy - 54.5%
against 96.5% - while looking exactly like a recognition failure. The block was
detected and read correctly; it was dropped on the way out.

**The transformers example on the model card is the wrong API.** It is
element-level and skips layout analysis, so on anything larger than a single
line it returns the page in the wrong reading order. The daemon uses the
page-level `PaddleOCRVL` pipeline instead.

## Tuning

Environment variables, set in `ocrd.service`:

| variable | default | effect |
|---|---|---|
| `OCRD_ENGINE` | `paddlevl` | `paddlevl` or `surya` |
| `OCRD_DEVICE` | `gpu:0` | paddlevl only; `cpu` to run without a GPU |
| `OCRD_CONFIDENCE` | `0.5` | surya only; drops lines below this confidence |
| `OCRD_SOCKET` | `$XDG_RUNTIME_DIR/ocrd.sock` | socket path |
