"""Regression checks for selectively removing commit-message attribution."""
from pathlib import Path
import runpy
import unittest

clean = runpy.run_path(str(Path(__file__).resolve().parents[1] / 'strip-claude-attribution.py'))['clean']


class AttributionTests(unittest.TestCase):
    def test_unrelated_messages_are_byte_identical(self):
        for message in [b'Keep exact\n\n\n', b'Improve askclaude integration\n',
                        b'Binary \xff\n', b'Co-authored-by: Alice <alice@example.com>\n']:
            with self.subTest(message=message):
                self.assertEqual(clean(message), message)

    def test_only_matching_coauthor_is_removed(self):
        message = (b'Work\n\nCo-authored-by: Alice <alice@example.com>\n'
                   b'Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>\n')
        self.assertEqual(clean(message), b'Work\n\nCo-authored-by: Alice <alice@example.com>\n')

    def test_attribution_footer_forms(self):
        for footer in [b'Co-Authored-By: Claude <noreply@anthropic.com>',
                       b'Claude-Session: abc', b'Generated with Claude Code',
                       b'https://claude.ai/code/session/abc']:
            with self.subTest(footer=footer):
                self.assertEqual(clean(b'Work\n\n' + footer + b'\n'), b'Work\n')


if __name__ == '__main__':
    unittest.main()
