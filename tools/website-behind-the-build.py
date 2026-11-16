#!/usr/bin/env python3
"""Fill recipefinder.uk's "Behind the build" page from CHANGELOG.md.

CHANGELOG entries are three lines (format at the top of CHANGELOG.md):
    ## YYYY-MM-DD · <item> · <commit>
    - For you: …
    - Behind the build: …
Entries are grouped by week (Monday), newest first, and written between the
`<!-- behind-the-build:start -->` / `<!-- behind-the-build:end -->` markers. The item name and commit stay off the page
(they're for the team). A malformed entry stops the script so nothing half-written is published.
Usage (from the repo root):
    python3 tools/website-behind-the-build.py --check                              # validate CHANGELOG.md only
    python3 tools/website-behind-the-build.py ../RecipeFinderWebsite/behind-the-build.html
"""
import datetime, html, re, sys

HEADING = re.compile(r"^## (\d{4}-\d{2}-\d{2}) · (.+) · (\S+)$")
FOR_YOU, BEHIND = "- For you: ", "- Behind the build: "
START, END = "<!-- behind-the-build:start -->", "<!-- behind-the-build:end -->"


def parse(text):
    """Returns [(date, for_you, behind)] in file order; raises ValueError naming the first bad entry."""
    lines, out = text.splitlines(), []
    in_fence = False
    for i, line in enumerate(lines):
        if line.startswith("```"):
            in_fence = not in_fence
        if in_fence or not line.startswith("## "):
            continue
        m = HEADING.match(line)
        if not m:
            raise ValueError(f"line {i + 1}: heading must be '## YYYY-MM-DD · item · commit': {line}")
        try:
            day = datetime.date.fromisoformat(m.group(1))
        except ValueError:
            raise ValueError(f"line {i + 1}: not a date: {m.group(1)}") from None
        body = lines[i + 1:i + 3]
        if len(body) < 2 or not body[0].startswith(FOR_YOU) or not body[1].startswith(BEHIND):
            raise ValueError(f"line {i + 1}: '{m.group(2)}' needs '{FOR_YOU.strip()}' then '{BEHIND.strip()}' lines")
        for_you, behind = body[0][len(FOR_YOU):].strip(), body[1][len(BEHIND):].strip()
        if not for_you or not behind:
            raise ValueError(f"line {i + 1}: '{m.group(2)}' has an empty line")
        out.append((day, for_you, behind))
    return out


def text_html(t):
    return html.escape(t, quote=False).replace("'", "’")


def render(entries):
    weeks = {}
    for e in entries:
        weeks.setdefault(e[0] - datetime.timedelta(days=e[0].weekday()), []).append(e)
    parts = []
    for monday in sorted(weeks, reverse=True):
        items = []
        # Stable sort keeps file order (newest first) within a day.
        for day, for_you, behind in sorted(weeks[monday], key=lambda e: e[0], reverse=True):
            items.append(
                f'                    <li>\n'
                f'                        <time datetime="{day.isoformat()}">{day.day} {day.strftime("%b")}</time>\n'
                f'                        <p class="btb-for-you">{text_html(for_you)}</p>\n'
                f'                        <p class="btb-behind">{text_html(behind)}</p>\n'
                f'                    </li>')
        parts.append(f'            <section class="btb-week">\n'
                     f'                <h2>Week of {monday.day} {monday.strftime("%B %Y")}</h2>\n'
                     f'                <ul class="btb-list">\n' + "\n".join(items) + '\n                </ul>\n'
                     f'            </section>')
    return "\n".join(parts)


def fill(page, entries):
    if START not in page or END not in page:
        raise ValueError(f"page needs {START} and {END} markers")
    a, b = page.index(START) + len(START), page.index(END)
    return page[:a] + "\n" + render(entries) + "\n            " + page[b:]


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    try:
        entries = parse(open("CHANGELOG.md", encoding="utf-8").read())
        if sys.argv[1] != "--check":
            page = fill(open(sys.argv[1], encoding="utf-8").read(), entries)
            open(sys.argv[1], "w", encoding="utf-8").write(page)
    except ValueError as error:
        sys.exit(f"CHANGELOG.md: {error}")
    print(f"{len(entries)} entries OK" + ("" if sys.argv[1] == "--check" else f"; wrote {sys.argv[1]}"), file=sys.stderr)
