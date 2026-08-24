#!/usr/bin/env python3
"""Score OCR output against hand-typed ground truth for screen captures.

Same CER/WER maths as the frak-test scorer, but a different normalizer: book
pages hyphenate across line breaks, screen text does not. Rejoining "--index-"
+ "url" into "indexurl" would wreck any page containing code or CLI flags, so
that step is deliberately absent here.

  ./score_shots.py                    # every engine, every shot
  ./score_shots.py tesseract surya    # named engines only
"""
import re
import sys
from difflib import SequenceMatcher
from pathlib import Path

HERE = Path(__file__).resolve().parent
SHOTS = HERE / "shots"
OUT = HERE / "out"


def normalize(text: str) -> str:
    """Collapse whitespace only. Everything else is left exactly as produced.

    Smart quotes are deliberately NOT folded to ASCII. Tesseract substitutes
    them freely, and for a screenshot tool that is a real defect rather than a
    cosmetic one: a curly quote pasted into code is a syntax error. An earlier
    version of this function folded them, which scored Tesseract 100% on a page
    where it had in fact made four such substitutions.
    """
    return re.sub(r"\s+", " ", text.replace("­", "")).strip()


def edit_distance(a: list, b: list) -> int:
    previous = list(range(len(b) + 1))
    for i, item_a in enumerate(a, start=1):
        current = [i]
        for j, item_b in enumerate(b, start=1):
            current.append(
                min(previous[j] + 1, current[j - 1] + 1,
                    previous[j - 1] + (item_a != item_b))
            )
        previous = current
    return previous[-1]


def score(reference: str, hypothesis: str) -> dict:
    ref, hyp = normalize(reference), normalize(hypothesis)
    cer = edit_distance(list(ref), list(hyp)) / max(1, len(ref))
    ref_words, hyp_words = ref.split(), hyp.split()
    wer = edit_distance(ref_words, hyp_words) / max(1, len(ref_words))
    return {
        "char_accuracy": 1 - cer,
        "word_accuracy": 1 - wer,
        "ref_chars": len(ref),
    }


def main() -> None:
    engines = sys.argv[1:]
    truths = sorted(SHOTS.glob("*.gt.txt"))
    if not truths:
        raise SystemExit(f"no ground truth in {SHOTS} - run capture.sh first")

    if not engines:
        engines = sorted({p.parent.name for p in OUT.glob("*/*.txt")})
    if not engines:
        raise SystemExit(f"no engine output in {OUT}")

    totals = {engine: [0.0, 0.0, 0] for engine in engines}
    for truth in truths:
        label = truth.name[: -len(".gt.txt")]
        reference = truth.read_text(encoding="utf-8")
        print(f"\n### {label}  ({len(normalize(reference))} chars)")
        rows = []
        for engine in engines:
            path = OUT / engine / f"{label}.txt"
            if not path.is_file():
                print(f"  {engine:<16} (no output)")
                continue
            result = score(reference, path.read_text(encoding="utf-8"))
            rows.append((engine, result))
            totals[engine][0] += result["char_accuracy"] * result["ref_chars"]
            totals[engine][1] += result["word_accuracy"] * result["ref_chars"]
            totals[engine][2] += result["ref_chars"]
        for engine, result in sorted(rows, key=lambda r: -r[1]["char_accuracy"]):
            print(f"  {engine:<16}{result['char_accuracy']:>8.1%}"
                  f"{result['word_accuracy']:>9.1%}")

    print(f"\n### POOLED (weighted by page length)")
    print(f"  {'engine':<16}{'char acc':>8}{'word acc':>9}")
    pooled = [(e, c / n, w / n) for e, (c, w, n) in totals.items() if n]
    for engine, char_acc, word_acc in sorted(pooled, key=lambda r: -r[1]):
        print(f"  {engine:<16}{char_acc:>8.1%}{word_acc:>9.1%}")


if __name__ == "__main__":
    main()
