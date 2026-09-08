# Git attribution cleanup

`strip-claude-attribution.py` audits commit messages reachable from all local
refs for Claude co-author trailers, session trailers and generated-with lines.
It preserves other co-authors and ordinary references to Claude tools.
It does not edit source files or remove installed software.

Audit (Python 3 and Git only):

```sh
python3 scripts/strip-claude-attribution.py /path/to/repo
```

Prepare a cleanup in a **new** output directory:

```sh
python3 -m venv ~/.local/share/git-attribution-tools
~/.local/share/git-attribution-tools/bin/pip install git-filter-repo==2.47.0
python3 scripts/strip-claude-attribution.py /path/to/repo --prepare /path/to/new-review-directory
```

The output contains `before.bundle`, a rewritten `clean.git` mirror, and
`report.json` with old/new object IDs. The input repository is untouched.
Verification compares every commit's raw metadata, file tree and mapped parents,
and checks ref preservation and unsigned annotated tags. Empty commits and merge
structure are retained. Unexpected changes stop preparation without publishing.
Signed commits and signed/nested tags require separate handling.

Review the report before publishing selected refs with an explicit
`--force-with-lease=refs/heads/BRANCH:OLD_ID`. The tool never pushes or aligns
existing checkouts. Do not mirror-push: local recovery refs may be private.
After publishing, align affected checkouts only after preserving their refs
and verifying their working files and trees. Retain the original backup bundle.

This audits local refs, so check the current remote refs separately. It is not
a source-content scanner or a purge of old objects, reflogs or recovery backups.
Preparation is triggered by affected commit messages; tags are verified and
cleaned during that preparation, but tag-only attribution is not an audit target.

Run callback regression checks:

```sh
python3 -m unittest discover -s scripts/tests -p 'test_strip_claude_attribution.py'
```
