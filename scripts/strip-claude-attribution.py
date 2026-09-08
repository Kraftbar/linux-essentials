#!/usr/bin/env python3
"""Audit attribution; optionally prepare and verify a separate rewritten mirror.

Never changes the input repository or pushes. Requires git-filter-repo 2.47.0
for --prepare; the default is a read-only commit-message audit.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess


CALLBACK = r'''
import re
pattern = re.compile(br"(?i)^[ \t]*(?:co-authored-by:[^\r\n]*(?:claude|anthropic)|claude-session:|(?:[^\r\n]*generated with[^\r\n]*claude)|https?://claude\.ai/code/session)")
lines = message.splitlines(keepends=True)
kept = [line for line in lines if not pattern.search(line)]
if len(kept) == len(lines):
    return message
while kept and not kept[-1].strip():
    kept.pop()
return b"".join(kept)
'''
namespace = {}
exec('def clean(message):\n' + '\n'.join('    ' + line for line in CALLBACK.splitlines()), namespace)
clean = namespace['clean']


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])


def commits(repo):
    return git(repo, 'rev-list', '--all').decode().splitlines()


def refs(repo):
    return dict(line.split() for line in git(
        repo, 'for-each-ref', '--format=%(refname) %(objectname)').decode().splitlines())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repo', type=Path)
    parser.add_argument('--prepare', type=Path, help='new directory for backup bundle, mirror and report')
    parser.add_argument('--filter-repo', default=str(Path.home() / '.local/share/git-attribution-tools/bin/git-filter-repo'))
    args = parser.parse_args()
    repo = args.repo.resolve()
    before_refs = refs(repo)
    objects = {oid: git(repo, 'cat-file', 'commit', oid) for oid in commits(repo)}
    affected = [oid for oid, raw in objects.items() if clean(raw.split(b'\n\n', 1)[1]) != raw.split(b'\n\n', 1)[1]]
    report = {'source': str(repo), 'commit_count': len(objects), 'affected_commits': affected,
              'refs_before': before_refs}
    if args.prepare is None:
        print(json.dumps(report, indent=2))
        return
    if not affected:
        print('No matching attribution; no rewrite needed.')
        return
    tags = {}
    for ref, oid in before_refs.items():
        kind = git(repo, 'cat-file', '-t', oid).strip()
        if kind == b'tag':
            raw = git(repo, 'cat-file', 'tag', oid)
            if b'\ntype commit\n' not in raw or b'-----BEGIN PGP SIGNATURE-----' in raw:
                raise SystemExit('Nested/non-commit/signed tag needs separate handling: ' + ref)
            tags[oid] = raw
        elif kind != b'commit':
            raise SystemExit('Unsupported ref object: ' + ref)
    if any(b'\ngpgsig ' in raw.split(b'\n\n', 1)[0] for raw in objects.values()):
        raise SystemExit('Signed commits require a separate signing decision.')
    executable = shutil.which(args.filter_repo)
    if not executable:
        raise SystemExit('Install git-filter-repo 2.47.0 or pass --filter-repo PATH.')
    output = args.prepare.resolve()
    output.mkdir(mode=0o700, parents=True, exist_ok=False)
    git(repo, 'bundle', 'create', str(output / 'before.bundle'), '--all')
    git(repo, 'bundle', 'verify', str(output / 'before.bundle'))
    mirror = output / 'clean.git'
    subprocess.run(['git', 'clone', '--mirror', '--no-local', str(repo), str(mirror)], check=True)
    # Keep pre-existing origin tracking refs as data; remove only the clone's
    # remote configuration, which filter-repo would otherwise remove with refs.
    git(mirror, 'config', '--remove-section', 'remote.origin')
    # --force applies only to this newly created disposable mirror.
    # --partial suppresses automatic origin-ref migration/deletion. All refs
    # are still processed; the checks below require their exact preservation.
    subprocess.run([executable, '--force', '--partial', '--message-callback', CALLBACK, '--preserve-commit-hashes',
                    '--preserve-commit-encoding', '--prune-empty', 'never',
                    '--prune-degenerate', 'never'], cwd=mirror, check=True)
    mapping = dict(line.split() for line in (mirror / 'filter-repo/commit-map').read_text().splitlines()[1:])
    if set(mapping) != set(objects) or len(set(mapping.values())) != len(objects):
        raise SystemExit('Commit set changed unexpectedly; do not publish.')
    for old, raw in objects.items():
        header, message = raw.split(b'\n\n', 1)
        expected_header = b'\n'.join(
            b'parent ' + mapping[line[7:].decode()].encode() if line.startswith(b'parent ') else line
            for line in header.split(b'\n'))
        expected = expected_header + b'\n\n' + clean(message)
        if git(mirror, 'cat-file', 'commit', mapping[old]) != expected:
            raise SystemExit('Unexpected metadata/tree/message change at ' + old)
    after_refs = refs(mirror)
    for old, raw in tags.items():
        header, message = raw.split(b'\n\n', 1)
        target = header.splitlines()[0][7:].decode()
        expected = b'object ' + mapping[target].encode() + b'\n' + header.split(b'\n', 1)[1] + b'\n\n' + clean(message)
        tag_ref = next(ref for ref, oid in before_refs.items() if oid == old)
        new = after_refs.get(tag_ref)
        if not new or git(mirror, 'cat-file', 'tag', new) != expected:
            raise SystemExit('Unexpected annotated tag change: ' + tag_ref)
        mapping[old] = new
    if after_refs != {ref: mapping[oid] for ref, oid in before_refs.items()}:
        raise SystemExit('Unexpected ref changes; do not publish.')
    if refs(repo) != before_refs:
        raise SystemExit('Input refs moved during preparation; repeat from current state.')
    git(mirror, 'fsck', '--full')
    report.update(refs_after=after_refs, commit_map=mapping,
                  verified='Every commit matches original tree, identities, dates and headers; only matching message lines and mapped parent IDs changed.')
    (output / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'affected_commits': len(affected), 'verified_commits': len(objects),
                      'mirror': str(mirror), 'report': str(output / 'report.json')}, indent=2))


if __name__ == '__main__':
    main()
