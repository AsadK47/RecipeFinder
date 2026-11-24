"""Tests for asc_promote_public.decide. Run from the repo root:
python3 -m unittest discover -s .github/scripts -p 'test_asc_promote_public.py'"""
import contextlib
import io
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_promote_public import decide, main  # noqa: E402


class DecideTests(unittest.TestCase):
    def test_ready_for_submission_submits_then_adds(self):
        self.assertEqual(decide("READY_FOR_BETA_SUBMISSION", in_group=False), "submit_and_add")

    def test_reviewable_states_add_without_submitting(self):
        for state in ("WAITING_FOR_BETA_REVIEW", "IN_BETA_REVIEW", "BETA_APPROVED",
                      "READY_FOR_BETA_TESTING", "IN_BETA_TESTING"):
            with self.subTest(state=state):
                self.assertEqual(decide(state, in_group=False), "add")

    def test_good_state_already_in_group_is_done(self):
        self.assertEqual(decide("BETA_APPROVED", in_group=True), "done")
        self.assertEqual(decide("IN_BETA_REVIEW", in_group=True), "done")

    def test_ready_for_submission_in_group_still_submits(self):
        # In the group but never sent to review: testers would wait forever.
        self.assertEqual(decide("READY_FOR_BETA_SUBMISSION", in_group=True), "submit")

    def test_bad_states_fail_even_when_already_in_group(self):
        for state in ("MISSING_EXPORT_COMPLIANCE", "BETA_REJECTED", "PROCESSING_EXCEPTION", "EXPIRED",
                      "PROCESSING", "IN_EXPORT_COMPLIANCE_REVIEW", None, "SOMETHING_NEW"):
            for in_group in (False, True):
                with self.subTest(state=state, in_group=in_group):
                    self.assertEqual(decide(state, in_group=in_group), "fail")


class FakeASC:
    """Answers the script's GETs and records its POSTs."""
    def __init__(self, state, in_group):
        self.state, self.in_group, self.posts = state, in_group, []

    def call(self, method, url, token, body=None):
        if method == "POST":
            self.posts.append(url.rsplit("/v1/", 1)[1])
            return {}
        if "/betaGroups?" in url:
            return {"data": [{"id": "g1", "attributes": {"name": "Public Beta", "isInternalGroup": False}}]}
        if url.split("?")[0].endswith("/betaGroups/g1/builds"):
            return {"data": [{"id": "b1"}] if self.in_group else []}
        if "/v1/builds?" in url:
            return {"data": [{"id": "b1", "attributes": {"version": "170"}}]}
        if url.endswith("/buildBetaDetail"):
            return {"data": {"attributes": {"externalBuildState": self.state}}}
        raise AssertionError(f"unexpected GET {url}")

    def run(self):
        env = {"ASC_KEY_ID": "k", "ASC_ISSUER_ID": "i", "ASC_KEY_PATH": "p", "APP_ID": "a"}
        with contextlib.redirect_stdout(io.StringIO()):
            main(env=env, call=self.call, make_token=lambda *_: "t")
        return self.posts


class MainTests(unittest.TestCase):
    def test_new_build_is_submitted_then_added(self):
        self.assertEqual(FakeASC("READY_FOR_BETA_SUBMISSION", False).run(),
                         ["betaAppReviewSubmissions", "betaGroups/g1/relationships/builds"])

    def test_approved_build_is_added_without_review(self):
        self.assertEqual(FakeASC("BETA_APPROVED", False).run(), ["betaGroups/g1/relationships/builds"])

    def test_build_in_group_never_reviewed_is_submitted(self):
        self.assertEqual(FakeASC("READY_FOR_BETA_SUBMISSION", True).run(), ["betaAppReviewSubmissions"])

    def test_build_in_group_and_approved_sends_nothing(self):
        self.assertEqual(FakeASC("BETA_APPROVED", True).run(), [])

    def test_rejected_build_fails_and_sends_nothing(self):
        fake = FakeASC("BETA_REJECTED", True)
        with self.assertRaises(SystemExit) as exit_:
            fake.run()
        self.assertEqual(exit_.exception.code, 1)
        self.assertEqual(fake.posts, [])


if __name__ == "__main__":
    unittest.main()
