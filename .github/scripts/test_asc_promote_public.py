"""Tests for asc_promote_public.decide. Run from the repo root:
python3 -m unittest discover -s .github/scripts -p 'test_asc_promote_public.py'"""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc_promote_public import decide  # noqa: E402


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


if __name__ == "__main__":
    unittest.main()
