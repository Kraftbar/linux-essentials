#!/usr/bin/env python3
"""Find Claude attribution in git repos; with --fix, remove it.

Checks commit messages on local branches, origin branches and tags, pull
request descriptions, and GitHub's Contributors box. The default is a
read-only check after a fetch. --fix saves all refs to a bundle, recreates
only the affected commits and what is built on them, force-pushes with a
lease, edits pull requests and makes GitHub recount contributors.
"""
import argparse
import datetime
import json
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import sys
import time
import urllib.request

clean = runpy.run_path(str(Path(__file__).resolve().with_name('strip-claude-attribution.py')))['clean']
SCOPE = ['--branches', '--remotes=origin', '--tags']
REFS = ['refs/heads', 'refs/remotes/origin', 'refs/tags']
BUSY = ['rebase-merge', 'rebase-apply', 'MERGE_HEAD', 'CHERRY_PICK_HEAD', 'BISECT_LOG']
CLAUDE = re.compile(r'(?i)claude|anthropic')
TEMP = 'declaudegit-recount'


def run(*command, data=None):
    return subprocess.run(command, input=data, capture_output=True)


def git(repo, *args, data=None):
    done = run('git', '-C', str(repo), *args, data=data)
    if done.returncode:
        raise RuntimeError(done.stderr.decode(errors='replace').strip() or f'git {args[0]} failed')
    return done.stdout


def text(repo, *args):
    return git(repo, *args).decode(errors='replace').strip()


def gh(*args):
    """Output of `gh api`, or None when the call fails or gh is not installed."""
    if not shutil.which('gh'):
        return None
    done = run('gh', 'api', *args)
    return None if done.returncode else done.stdout.decode().strip()


def find_repos(paths):
    for path in paths:
        path = path.expanduser().resolve()
        if (path / '.git').exists():
            yield path
            continue
        for child in sorted(path.iterdir()):
            if (child / '.git').exists() and child.name[0] not in '._':
                yield child


def github_name(repo):
    """owner/name when origin is on GitHub, '' for another remote, None without origin."""
    done = run('git', '-C', str(repo), 'remote', 'get-url', 'origin')
    if done.returncode:
        return None
    match = re.search(r'github\.com[:/]([^/]+/[^/]+?)(?:\.git)?/?$', done.stdout.decode().strip())
    return match[1] if match else ''


def affected_commits(repo):
    found = run('git', '-C', str(repo), 'log', *SCOPE, '--format=%H', '-i', '-E', '--grep=claude|anthropic')
    commits = []
    for oid in found.stdout.decode().split():
        body = git(repo, 'cat-file', 'commit', oid).partition(b'\n\n')[2]
        if clean(body) != body:
            commits.append(oid)
    return commits


def affected_pulls(name):
    """{number: cleaned description} for pull requests that carry attribution."""
    listing = gh('--paginate', f'repos/{name}/pulls?state=all&per_page=100',
                 '--jq', '.[] | select(.body) | [.number, .body] | @json')
    pulls = {}
    for line in (listing or '').splitlines():
        number, body = json.loads(line)
        cleaned = clean(body.encode()).decode()
        if cleaned != body:
            pulls[number] = cleaned
    return pulls


def box(name):
    """Logins in GitHub's Contributors box; None when it cannot be read (private repo, offline)."""
    request = urllib.request.Request(
        f'https://github.com/{name}/contributors_list?count=10&current_repository={name.split("/")[1]}&items_to_show=14',
        headers={'X-Requested-With': 'XMLHttpRequest', 'Accept': 'text/html', 'User-Agent': 'declaudegit'})
    try:
        with urllib.request.urlopen(request, timeout=20) as reply:
            return set(re.findall(r'alt="@([\w-]+)"', reply.read().decode(errors='replace')))
    except OSError:
        return None


def listed(logins):
    return sorted(login for login in logins or () if CLAUDE.search(login))


def check(repo, fetch=True):
    name = github_name(repo)
    note = ''
    if fetch and name is not None and run('git', '-C', str(repo), 'fetch', '--quiet', 'origin').returncode:
        note = 'fetch failed, checked what was fetched before'
    commits = affected_commits(repo)
    refs = []
    if commits:
        contains = [arg for oid in commits for arg in ('--contains', oid)]
        for ref in text(repo, 'for-each-ref', '--format=%(refname)', *contains, *REFS).split():
            if ref != 'refs/remotes/origin/HEAD':
                refs.append(ref.replace('refs/heads/', '').replace('refs/remotes/', '').replace('refs/tags/', 'tag '))
    return {'repo': repo, 'name': name, 'note': note, 'commits': commits, 'refs': refs,
            'pulls': affected_pulls(name) if name else {}, 'box': box(name) if name else None}


def problems(state):
    found = []
    if state['commits']:
        found.append(f"{len(state['commits'])} commit(s) on {', '.join(state['refs'])}")
    if state['pulls']:
        found.append('pull request ' + ', '.join(f'#{number}' for number in sorted(state['pulls'])))
    if listed(state['box']):
        found.append('Contributors box lists ' + ', '.join(listed(state['box'])))
    return found


def show(state):
    line = f"{state['repo'].name:<24} {'; '.join(problems(state)) or 'clean'}"
    print(line + (f"  ({state['note']})" if state['note'] else ''), flush=True)


def rewrite(repo, commits):
    """Recreate the affected commits and everything built on them.

    Returns {old: new} and the number of signatures that could not be kept.
    Only the message and parent IDs change; older history keeps its IDs.
    """
    mapping, unsigned = {}, 0
    affected = set(commits)
    for line in text(repo, 'rev-list', '--topo-order', '--reverse', '--parents', *SCOPE).splitlines():
        oid, *parents = line.split()
        if oid not in affected and not any(parent in mapping for parent in parents):
            continue
        raw = git(repo, 'cat-file', 'commit', oid)
        header, gap, body = raw.partition(b'\n\n')
        kept, signature = [], False
        for field in header.split(b'\n'):
            if signature and field.startswith(b' '):
                continue
            signature = field.startswith(b'gpgsig')
            if signature:
                unsigned += 1
            elif field.startswith(b'parent '):
                parent = field[7:].decode()
                kept.append(b'parent ' + mapping.get(parent, parent).encode())
            else:
                kept.append(field)
        tail = gap + clean(body) if gap else raw[len(header):]
        mapping[oid] = git(repo, 'hash-object', '-t', 'commit', '-w', '--stdin',
                           data=b'\n'.join(kept) + tail).decode().strip()
    return mapping, unsigned


def retag(repo, oid, mapping):
    """Recreate an annotated tag on its rewritten commit; a tag signature cannot be kept."""
    header, gap, body = git(repo, 'cat-file', 'tag', oid).partition(b'\n\n')
    fields = header.split(b'\n')
    target = fields[0][7:].decode()
    if fields[1] != b'type commit' or target not in mapping:
        return None
    fields[0] = b'object ' + mapping[target].encode()
    body = re.split(br'-----BEGIN (?:PGP|SSH) SIGNATURE-----', body)[0]
    return git(repo, 'hash-object', '-t', 'tag', '-w', '--stdin',
               data=b'\n'.join(fields) + gap + clean(body)).decode().strip()


def fix_commits(repo, state, backups):
    """Move local branches and tags to the recreated commits and force-push origin's."""
    gitdir = Path(text(repo, 'rev-parse', '--absolute-git-dir'))
    if any((gitdir / name).exists() for name in BUSY):
        return ['skipped: a rebase, merge, cherry-pick or bisect is in progress']
    backups.mkdir(parents=True, exist_ok=True)
    bundle = backups / (repo.name + '.bundle')
    git(repo, 'bundle', 'create', str(bundle), '--all')
    mapping, unsigned = rewrite(repo, state['commits'])
    notes = [f'{len(mapping)} commit(s) recreated; originals in {bundle}']
    if unsigned:
        notes.append(f'{unsigned} signature(s) dropped from recreated commits')
    pushes = []
    for line in text(repo, 'for-each-ref', '--format=%(refname) %(objectname) %(objecttype)', *REFS).splitlines():
        ref, old, kind = line.split()
        new = retag(repo, old, mapping) if kind == 'tag' else mapping.get(old)
        if not new or ref == 'refs/remotes/origin/HEAD':
            continue
        if ref.startswith('refs/remotes/origin/'):
            pushes.append(('refs/heads/' + ref[20:], old, new))
        else:
            git(repo, 'update-ref', '-m', 'declaudegit', ref, new, old)
            if ref.startswith('refs/tags/'):
                pushes.append((ref, old, new))
    if run('git', '-C', str(repo), 'symbolic-ref', '-q', 'HEAD').returncode and text(repo, 'rev-parse', 'HEAD') in mapping:
        notes.append('HEAD is detached on a replaced commit and was left there')
    if state['name'] is None or not pushes:
        return notes
    remote = dict(reversed(line.split('\t')) for line in text(repo, 'ls-remote', 'origin').splitlines())
    for ref, old, new in pushes:
        if remote.get(ref) == old:
            git(repo, 'push', '--quiet', f'--force-with-lease={ref}:{old}', 'origin', f'{new}:{ref}')
            notes.append(f'pushed {ref}')
        elif ref in remote and remote[ref] != new:
            notes.append(f'{ref} moved on origin since the fetch; run again')
    return notes


def fix_pulls(name, pulls):
    notes = []
    for number, body in sorted(pulls.items()):
        done = gh('-X', 'PATCH', f'repos/{name}/pulls/{number}', '-f', f'body={body}')
        notes.append(f'pull request #{number} ' + ('edited' if done is not None else 'could not be edited'))
    return notes


def settle(name, wait):
    """Wait until the Contributors box stops listing Claude; True, False, or None when unreadable."""
    deadline = time.time() + wait
    while True:
        logins = box(name)
        if logins is None:
            time.sleep(min(wait, 30))
            return None
        if not listed(logins):
            return True
        if time.time() >= deadline:
            return False
        time.sleep(5)


def recount(name, wait):
    """Make GitHub rebuild the Contributors box.

    The box is cached and survives a history rewrite. Pointing the default
    branch at a temporary copy of itself for a while, then back, rebuilds it.
    """
    api = f'repos/{name}'
    default = gh(api, '--jq', '.default_branch')
    head = gh(f'{api}/git/ref/heads/{default}', '--jq', '.object.sha') if default else None
    if not head or default == TEMP:
        return 'Contributors box: could not read the default branch; nothing changed'
    if gh(f'{api}/git/refs', '-f', f'ref=refs/heads/{TEMP}', '-f', f'sha={head}') is None:
        return f'Contributors box: could not create branch {TEMP}; nothing changed'
    try:
        if gh('-X', 'PATCH', api, '-f', f'default_branch={TEMP}') is not None:
            settle(name, wait)
    finally:
        restored = any(gh('-X', 'PATCH', api, '-f', f'default_branch={default}') is not None for _ in range(3))
        if restored:
            gh('-X', 'DELETE', f'{api}/git/refs/heads/{TEMP}')
    if not restored:
        return f'WARNING: default branch is still {TEMP}; set it back to {default} in the repo settings'
    return {True: 'Contributors box: recounted, Claude is gone',
            False: 'Contributors box: still lists Claude; GitHub may need longer (--wait)',
            None: 'Contributors box: recount requested (private repo, cannot be read back)'}[settle(name, wait)]


def fix(state, backups, login, wait):
    name = state['name']
    if name == '' or (name and (not login or not name.lower().startswith(login.lower() + '/'))):
        return ['left alone: origin is not a repo of your GitHub account']
    notes = fix_commits(state['repo'], state, backups) if state['commits'] else []
    if name:
        notes += fix_pulls(name, state['pulls'])
        if listed(box(name)) or (state['box'] is None and state['commits']):
            notes.append(recount(name, wait))
    return notes


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('paths', nargs='*', type=Path, default=[Path('~/github')],
                        help='repos, or folders of repos (default: ~/github; folders starting with _ or . are skipped)')
    parser.add_argument('--fix', action='store_true', help='remove what the check finds')
    parser.add_argument('--yes', action='store_true', help='with --fix, do not ask first')
    parser.add_argument('--no-fetch', action='store_true', help='check without fetching from origin')
    parser.add_argument('--wait', type=int, default=120, help='seconds to give GitHub for a recount (default: 120)')
    args = parser.parse_args()

    states = []
    for repo in find_repos(args.paths):
        states.append(check(repo, not args.no_fetch))
        show(states[-1])
    todo = [state for state in states if problems(state)]
    if not args.fix or not todo:
        sys.exit(1 if todo else 0)
    question = f'\nRewrite history, force-push and recount in {len(todo)} repo(s)? [y/N] '
    if not args.yes and input(question).strip().lower() != 'y':
        sys.exit(1)

    login = gh('user', '--jq', '.login')
    backups = Path.home() / 'backups' / ('declaudegit-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
    left = 0
    for state in todo:
        print(f"\n{state['repo'].name}", flush=True)
        try:
            notes = fix(state, backups, login, args.wait)
        except RuntimeError as error:
            notes = [f'failed: {error}']
        for note in notes:
            print('  ' + note, flush=True)
        after = check(state['repo'], fetch=False)
        left += bool(problems(after))
        print('  now: ' + ('; '.join(problems(after)) or 'clean'), flush=True)
    sys.exit(1 if left else 0)


if __name__ == '__main__':
    main()
