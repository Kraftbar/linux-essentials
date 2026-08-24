# Screenshot OCR benchmark

The `loq` bake-off in `~/services/ocr-tests/frak-test` scores 19th-century book
scans. This one scores what the OCR tool will actually be pointed at: text
rendered on a screen. Different failure modes - subpixel antialiasing, dark
mode, UI chrome, code punctuation - so the book numbers do not transfer.

## 1. Capture

    ./capture.sh terminal-ls

Drag a region; the image opens for reference and an editor opens on the ground
truth file. **Type the text by hand.** Never paste an engine's output, or that
engine silently becomes the reference for every other engine.

Aim for ~10 shots covering the cases that matter:

| label suggestion | why it is in the set |
|---|---|
| `terminal-light` | monospace, high contrast |
| `terminal-dark` | light-on-dark, where Tesseract historically fails |
| `code-editor` | punctuation soup: `{}` `()` `l1I` `0O` |
| `webpage-article` | proportional body text, the easy case |
| `dialog-box` | small UI text, mixed weights |
| `table-data` | column structure, tests reading order |
| `pdf-viewer` | rendered document, closest to the book pages |
| `chat-window` | mixed sizes, emoji, timestamps |
| `error-message` | paths and stack traces, punctuation-heavy |
| `low-contrast` | grey-on-grey, the stress case |

## 2. Run the engines

    ./run_engines.sh                    # the locally deployed daemon
    ./run_engines.sh tesseract surya    # engines that live on loq

With no arguments it scores whatever `../ocr` has deployed, which answers the
day-to-day question: is the thing actually installed still as good as this
benchmark said? Named engines are run on `loq`, which is where Tesseract and
Surya are installed; screenshots sync there and the text comes back.

Results land in `out/<engine>/<label>.txt`, which is gitignored - it is output,
regenerated on demand. The fixtures and ground truth are the durable part.

## 3. Score

    ./score_shots.py

Per-shot character and word accuracy, plus a pooled total weighted by page
length.

## Results, 2026-08-24

Five shots, scored strictly (see the note below). Character / word accuracy:

| shot | PaddleOCR-VL | Tesseract | Surya |
|---|---:|---:|---:|
| `code-light` (PIL render) | **99.6 / 97.1** | 98.4 / 91.4 | 98.4 / 77.1 |
| `code-dark` (PIL render) | **100 / 100** | 98.4 / 91.4 | 97.7 / 68.6 |
| `code-terminal-dark` (real gnome-terminal) | **100 / 100** | 95.5 / 50.0 | 93.2 / 0.0 |
| `identifiers-mono` | **100 / 100** | 96.9 / 62.5 | 76.5 / -100 |
| `identifiers-serif` | **100 / 100** | 94.9 / 12.5 | 76.5 / -100 |
| **pooled** | **99.9 / 99.2** | 97.3 / 71.3 | 92.3 / 20.1 |

Negative word accuracy means WER exceeded 100%: splitting `arg_one` into two
tokens inserts more words than the reference contains.

**Surya drops underscores.** Every one of them - 0 of 12 survived on the real
terminal capture, 0 of 11 across two fonts on the identifier shots. It also
occasionally wraps a line in spurious `<math>` tags. This is not a rendering
artifact: it reproduces at 19px and 34px, in monospace and serif, on both PIL
renders and genuine antialiased X11 output.

That defect is invisible in character accuracy (still 92-98%, because one
character in eight is wrong at most) and catastrophic in word accuracy, because
every identifier, path and URL becomes two wrong tokens.

**This is why the book benchmark could not decide this question.** The LOQ
bake-off ranked Surya first, and it deserves that on 19th-century prose - which
contains no underscores at all. Extrapolating from it to screen text picked an
engine that mangles the text this tool exists to capture.

**Tesseract** keeps most underscores but substitutes smart quotes (`'` for `'`)
and inserts spurious spaces (`MAX _RETRY_COUNT`, `self. private _method`).

**PaddleOCR-VL** was byte-exact on four of five shots, and preserves leading
indentation, which the other two discard.

### What this set does not yet cover

Every shot is code or identifiers. There is no prose, no UI chrome, no table, no
low-contrast case, and no non-English text. The conclusion above is solid for
code, which is the dominant use, but the set needs the shots listed in the table
further up before it decides anything else.

The point of keeping the fixtures in the repo is that the next engine can be
compared against the same ground truth without transcribing anything by hand
again. That is the expensive part, and it is done.

## Note on scoring

`score_shots.py` is deliberately *not* the frak-test scorer. That one rejoins
words hyphenated across line breaks, which is right for books and wrong here -
it would turn `--index-url` into `indexurl` and wreck any shot containing code
or CLI flags.

This scorer collapses whitespace and nothing else. In particular it does **not**
fold smart quotes to ASCII. An earlier version did, and scored Tesseract 100% on
a shot where it had substituted four curly quotes - which would be four syntax
errors if pasted into an editor. For a clipboard tool the substitution is the
defect, so the scorer has to count it.

Whitespace is collapsed because line wrapping differs between engines. That does
mean indentation is not scored, so PaddleOCR-VL gets no credit here for
preserving it, though it is the only engine that does.
