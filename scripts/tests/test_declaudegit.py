"""Regression checks for rewriting and publishing history without attribution."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('declaudegit', Path(__file__).resolve().parents[1] / 'declaudegit.py')
declaudegit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(declaudegit)

TRAILER = 'Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>'
ENV = dict(os.environ, GIT_AUTHOR_NAME='A', GIT_AUTHOR_EMAIL='a@example.com', GIT_AUTHOR_DATE='2026-01-01T10:00:00+01:00',
           GIT_COMMITTER_NAME='C', GIT_COMMITTER_EMAIL='c@example.com', GIT_COMMITTER_DATE='2026-01-02T10:00:00+01:00',
           GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_SYSTEM=os.devnull)


def git(repo, *args, data=None):
    return subprocess.run(['git', '-C', str(repo), *args], input=data, capture_output=True, check=True,
                          env=ENV).stdout.decode().strip()


def commit(repo, name, message):
    (repo / (name + '.txt')).write_text(name)
    git(repo, 'add', name + '.txt')
    git(repo, 'commit', '-q', '-m', message)
    return git(repo, 'rev-parse', 'HEAD')


def sign(repo):
    """Give HEAD a signature header, as a commit made in GitHub's web editor has."""
    header, gap, body = git(repo, 'cat-file', 'commit', 'HEAD').partition('\n\n')
    signed = header + '\ngpgsig -----BEGIN PGP SIGNATURE-----\n \n fake\n -----END PGP SIGNATURE-----' + gap + body + '\n'
    oid = git(repo, 'hash-object', '-t', 'commit', '-w', '--stdin', data=signed.encode())
    git(repo, 'reset', '-q', '--soft', oid)
    return oid


class RewriteTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        self.origin, self.repo, self.backups = root / 'origin.git', root / 'work', root / 'backups'
        os.environ.update({key: ENV[key] for key in ('GIT_CONFIG_GLOBAL', 'GIT_CONFIG_SYSTEM')})
        git(root, 'init', '-q', '--bare', '-b', 'main', str(self.origin))
        git(root, 'init', '-q', '-b', 'main', str(self.repo))
        git(self.repo, 'remote', 'add', 'origin', str(self.origin))
        self.base = commit(self.repo, 'base', 'Base')
        self.signed = sign(self.repo)
        self.bad = commit(self.repo, 'bad', f'Work\n\nCo-authored-by: Alice <alice@example.com>\n{TRAILER}\n')
        git(self.repo, 'tag', 'light')
        git(self.repo, 'checkout', '-q', '-b', 'side')
        commit(self.repo, 'side', 'Side work')
        self.side = sign(self.repo)
        git(self.repo, 'checkout', '-q', 'main')
        self.next = commit(self.repo, 'next', 'Next')
        git(self.repo, 'tag', '-a', 'v1', '-m', 'Release one')
        git(self.repo, 'merge', '-q', '--no-ff', '-m', 'Merge side', 'side')
        self.merge = git(self.repo, 'rev-parse', 'HEAD')
        git(self.repo, 'push', '-q', 'origin', 'main', 'side', '--tags')
        (self.repo / 'base.txt').write_text('uncommitted edit')

    def fix(self):
        state = declaudegit.check(self.repo, fetch=False)
        return state, declaudegit.fix_commits(self.repo, state, self.backups)

    def test_check_finds_the_commit_and_every_ref_holding_it(self):
        state = declaudegit.check(self.repo, fetch=False)
        self.assertEqual(state['commits'], [self.bad])
        self.assertEqual(sorted(state['refs']), ['main', 'origin/main', 'origin/side', 'side', 'tag light', 'tag v1'])

    def test_only_the_message_and_parents_change(self):
        self.fix()
        self.assertEqual(git(self.repo, 'rev-parse', 'light~1'), self.signed)
        self.assertIn('gpgsig', git(self.repo, 'cat-file', 'commit', self.signed))
        self.assertEqual(git(self.repo, 'log', '-1', '--format=%B', 'light').strip(),
                         'Work\n\nCo-authored-by: Alice <alice@example.com>')
        for old, new in [(self.bad, 'light'), (self.side, 'side'), (self.next, 'v1^{commit}'), (self.merge, 'main')]:
            with self.subTest(old=old):
                self.assertNotEqual(git(self.repo, 'rev-parse', new), old)
                for field in ('%T', '%an %ae %ad', '%cn %ce %cd', '%s'):
                    self.assertEqual(git(self.repo, 'log', '-1', f'--format={field}', new),
                                     git(self.repo, 'log', '-1', f'--format={field}', old))
        self.assertNotIn('gpgsig', git(self.repo, 'cat-file', 'commit', 'side'))
        self.assertEqual(git(self.repo, 'rev-parse', 'main^1', 'main^2'), git(self.repo, 'rev-parse', 'v1^{commit}', 'side'))
        self.assertEqual(git(self.repo, 'cat-file', '-t', 'v1'), 'tag')
        self.assertIn('Release one', git(self.repo, 'cat-file', 'tag', 'v1'))
        git(self.repo, 'fsck', '--strict')

    def test_origin_and_the_working_tree_follow(self):
        _, notes = self.fix()
        for ref in ('refs/heads/main', 'refs/heads/side', 'refs/tags/light', 'refs/tags/v1'):
            self.assertEqual(git(self.origin, 'rev-parse', ref), git(self.repo, 'rev-parse', ref))
            self.assertIn(f'pushed {ref}', notes)
        self.assertEqual(git(self.repo, 'status', '--porcelain'), 'M base.txt')
        self.assertTrue((self.backups / 'work.bundle').exists())
        self.assertIn(self.merge, git(self.repo, 'bundle', 'list-heads', str(self.backups / 'work.bundle')))
        self.assertEqual(declaudegit.check(self.repo, fetch=False)['commits'], [])

    def test_a_repo_in_the_middle_of_a_merge_is_left_alone(self):
        (self.repo / '.git' / 'MERGE_HEAD').write_text(self.side + '\n')
        _, notes = self.fix()
        self.assertIn('skipped', notes[0])
        self.assertEqual(git(self.repo, 'rev-parse', 'main'), self.merge)
        self.assertEqual(git(self.origin, 'rev-parse', 'main'), self.merge)

    def test_origin_that_moved_is_not_overwritten(self):
        other = Path(self.tmp.name) / 'other'
        git(self.tmp.name, 'clone', '-q', str(self.origin), str(other))
        newer = commit(other, 'newer', 'Newer')
        git(other, 'push', '-q', 'origin', 'main')
        _, notes = self.fix()
        self.assertEqual(git(self.origin, 'rev-parse', 'main'), newer)
        self.assertIn('refs/heads/main moved on origin since the fetch; run again', notes)


if __name__ == '__main__':
    unittest.main()
