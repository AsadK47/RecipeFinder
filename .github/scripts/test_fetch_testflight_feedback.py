"""Tests for fetch_testflight_feedback's retired ids and notices. Run from the repo root:
python3 -m unittest discover -s .github/scripts -p 'test_fetch_testflight_feedback.py'"""
import os
import sys
import unittest
from unittest import mock


sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fetch_testflight_feedback as ftf  # noqa: E402
from fetch_testflight_feedback import issue_for, new_submissions, parse_retired  # noqa: E402


def sub(sid, date="2026-11-25T10:00:00Z"):
    return {"id": sid, "attributes": {"createdDate": date}}


class RetiredIdTests(unittest.TestCase):
    def test_parse_one_per_line_ignoring_blanks_and_spaces(self):
        self.assertEqual(parse_retired("one\n\n  two  \r\nthree"), {"one", "two", "three"})

    def test_parse_strips_backticks_copied_from_a_notice(self):
        # The notice shows the id as `id`; a copy with the backticks must still match.
        self.assertEqual(parse_retired("`abc-123`, def-456"), {"abc-123", "def-456"})

    def test_unset_variable_is_empty(self):
        self.assertEqual(parse_retired(""), set())
        self.assertEqual(parse_retired(None), set())

    def test_retired_submission_is_not_filed_again(self):
        subs = [sub("deleted-notice"), sub("fresh", "2026-11-26T10:00:00Z")]
        out = new_submissions(subs, seen=set(), retired=parse_retired("`deleted-notice`"))
        self.assertEqual([s["id"] for s in out], ["fresh"])

    def test_seen_submission_is_not_filed_again(self):
        out = new_submissions([sub("filed"), sub("new")], seen={"filed"}, retired=set())
        self.assertEqual([s["id"] for s in out], ["new"])

    def test_new_submissions_oldest_first(self):
        subs = [sub("b", "2026-11-26T10:00:00Z"), sub("a", "2026-11-25T10:00:00Z")]
        self.assertEqual([s["id"] for s in new_submissions(subs, set(), set())], ["a", "b"])

    def test_workflow_passes_the_secret(self):
        # Without this env line the list is silently empty and deleted notices come back; a `vars.` value would be
        # printed in the public run log, so it must be a secret.
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "workflows", "testflight-feedback.yml")
        with open(root, encoding="utf-8") as handle:
            self.assertIn("TF_RETIRED_IDS: ${{ secrets.TF_RETIRED_IDS }}", handle.read())


class MainWiringTests(unittest.TestCase):
    def test_main_skips_ids_in_the_variable(self):
        posted = []

        def fake_call(method, url, token):
            if "/apps?" in url:
                return {"data": [{"id": "app"}]}
            if "Screenshot" in url:
                return {"data": [sub("retired-one"), sub("kept-one")]}
            return {"data": []}

        def fake_github(method, path, body=None):
            if method == "POST":
                posted.append(body)
                return {"number": len(posted)}
            return []

        env = {"ASC_KEY_ID": "k", "ASC_ISSUER_ID": "i", "ASC_KEY_PATH": "p", "GITHUB_TOKEN": "t",
               "GITHUB_REPOSITORY": "o/r", "TF_RETIRED_IDS": "retired-one"}
        with mock.patch.dict(os.environ, env), mock.patch.object(ftf, "make_token", return_value="tok"), \
                mock.patch.object(ftf, "call", side_effect=fake_call), \
                mock.patch.object(ftf, "github", side_effect=fake_github), \
                mock.patch("sys.stdout"):
            self.assertEqual(ftf.main(), 0)
        self.assertEqual([b["body"].count("<!-- tf:kept-one -->") for b in posted], [1])


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
