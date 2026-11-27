"""Tests for fetch_testflight_feedback's retired-id list. Run from the repo root:
python3 -m unittest discover -s .github/scripts -p 'test_fetch_testflight_feedback.py'"""
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fetch_testflight_feedback import (  # noqa: E402
    RETIRED_PATH, issue_for, new_submissions, read_retired, retired_line,
)


def sub(sid, date="2026-11-25T10:00:00Z"):
    return {"id": sid, "attributes": {"createdDate": date}}


class RetiredIdTests(unittest.TestCase):
    def write(self, text):
        handle = tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False)
        handle.write(text)
        handle.close()
        self.addCleanup(os.unlink, handle.name)
        return handle.name

    def test_retired_line_does_not_contain_the_id(self):
        # The list is public; deleting a notice must not leave Apple's reference number behind (Privacy 6.6).
        line = retired_line("AbC-123-submission")
        self.assertNotIn("AbC-123-submission", line)
        self.assertRegex(line, r"^[0-9a-f]{64}$")

    def test_read_retired_skips_comments_and_blanks(self):
        path = self.write(f"# header\n\n{retired_line('one')}\n  {retired_line('two')}  # note\n")
        self.assertEqual(read_retired(path), {retired_line("one"), retired_line("two")})

    def test_missing_file_is_empty(self):
        self.assertEqual(read_retired("/nonexistent/retired.txt"), set())

    def test_malformed_line_fails_loudly(self):
        # A raw id pasted by mistake would sit in a public file; refuse it rather than skip silently.
        path = self.write("raw-submission-id\n")
        with self.assertRaises(ValueError):
            read_retired(path)

    def test_retired_submission_is_not_filed_again(self):
        subs = [sub("deleted-notice"), sub("fresh", "2026-11-26T10:00:00Z")]
        out = new_submissions(subs, seen=set(), retired={retired_line("deleted-notice")})
        self.assertEqual([s["id"] for s in out], ["fresh"])

    def test_seen_submission_is_not_filed_again(self):
        out = new_submissions([sub("filed"), sub("new")], seen={"filed"}, retired=set())
        self.assertEqual([s["id"] for s in out], ["new"])

    def test_new_submissions_oldest_first(self):
        subs = [sub("b", "2026-11-26T10:00:00Z"), sub("a", "2026-11-25T10:00:00Z")]
        self.assertEqual([s["id"] for s in new_submissions(subs, set(), set())], ["a", "b"])

    def test_committed_list_parses(self):
        # The real file must always load, or the hourly job would stop filing notices.
        self.assertIsInstance(read_retired(RETIRED_PATH), set)
        self.assertTrue(os.path.exists(RETIRED_PATH))


class NoticeTests(unittest.TestCase):
    def test_notice_carries_no_tester_fields(self):
        s = {"id": "x1", "attributes": {"createdDate": "2026-11-25T10:00:00Z", "comment": "secret words",
                                        "email": "t@example.com", "deviceModel": "iPhone15,2"}}
        issue = issue_for("screenshot", s)
        text = issue["title"] + issue["body"]
        for field in ("secret words", "t@example.com", "iPhone15,2"):
            self.assertNotIn(field, text)
        self.assertIn("<!-- tf:x1 -->", issue["body"])


if __name__ == "__main__":
    unittest.main()
