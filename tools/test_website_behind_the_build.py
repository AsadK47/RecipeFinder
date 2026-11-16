"""Tests for tools/website-behind-the-build.py. Run from the repo root: python3 -m unittest tools/test_website_behind_the_build.py"""
import datetime, importlib.util, os, unittest

_spec = importlib.util.spec_from_file_location(
    "btb", os.path.join(os.path.dirname(os.path.abspath(__file__)), "website-behind-the-build.py"))
btb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(btb)

GOOD = """# Changelog
```
## YYYY-MM-DD · <item> · <commit>
- For you: example
```
## 2026-11-16 · Item B · abc1234
- For you: Me opens on your cookbook.
- Behind the build: two reviewers checked it.

## 2026-11-09 · Item A · def5678
- For you: Tap <Made it> & see it's done.
- Behind the build: tested.
"""


class ParseTests(unittest.TestCase):
    def test_reads_entries_and_skips_the_format_example(self):
        entries = btb.parse(GOOD)
        self.assertEqual([e[0] for e in entries], [datetime.date(2026, 11, 16), datetime.date(2026, 11, 9)])
        self.assertEqual(entries[0][1:], ("Me opens on your cookbook.", "two reviewers checked it."))

    def test_missing_behind_line_is_an_error(self):
        with self.assertRaisesRegex(ValueError, "Item C"):
            btb.parse("## 2026-11-16 · Item C · abc\n- For you: x\n\n")

    def test_lines_in_the_wrong_order_are_an_error(self):
        with self.assertRaises(ValueError):
            btb.parse("## 2026-11-16 · Item C · abc\n- Behind the build: y\n- For you: x\n")

    def test_bad_heading_and_bad_date_are_errors(self):
        with self.assertRaisesRegex(ValueError, "heading"):
            btb.parse("## 16 Nov · Item · abc\n- For you: x\n- Behind the build: y\n")
        with self.assertRaisesRegex(ValueError, "not a date"):
            btb.parse("## 2026-13-01 · Item · abc\n- For you: x\n- Behind the build: y\n")

    def test_the_real_changelog_is_valid(self):
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        with open(os.path.join(root, "CHANGELOG.md"), encoding="utf-8") as f:
            self.assertTrue(btb.parse(f.read()))


class RenderTests(unittest.TestCase):
    def test_groups_by_week_newest_first_and_escapes(self):
        out = btb.render(btb.parse(GOOD))
        self.assertLess(out.index("Week of 16 November 2026"), out.index("Week of 9 November 2026"))
        self.assertIn("Tap &lt;Made it&gt; &amp; see it’s done.", out)
        self.assertNotIn("Item A", out)  # item names and commits stay off the page
        self.assertNotIn("def5678", out)

    def test_fill_replaces_between_markers_and_needs_them(self):
        page = f"<main>{btb.START}old{btb.END}</main>"
        filled = btb.fill(page, btb.parse(GOOD))
        self.assertNotIn("old", filled)
        self.assertTrue(filled.startswith("<main>" + btb.START) and filled.endswith(btb.END + "</main>"))
        with self.assertRaises(ValueError):
            btb.fill("<main></main>", [])


if __name__ == "__main__":
    unittest.main()
