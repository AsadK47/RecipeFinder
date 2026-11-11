#!/usr/bin/env python3
"""Fill recipefinder.uk's whats-new.html from the Log in BACKLOG.md and CHANGELOG.md.

Log lines look like `- YYYY-MM-DD · item · commit · notes`. Only items with a user-facing line in
tools/whats-new-copy.json are published (notes are for the team, not the page); others are listed on stderr.
Entries are grouped by week (Monday), newest week first, and written between the
`<!-- whats-new:start -->` / `<!-- whats-new:end -->` markers.
Usage (from the repo root): python3 tools/website-whats-new.py ../RecipeFinderWebsite/whats-new.html
"""
import datetime, html, json, re, sys

LINE = re.compile(r"^- (\d{4}-\d{2}-\d{2}) · (.+?) · ")
START, END = "<!-- whats-new:start -->", "<!-- whats-new:end -->"

def log_lines(path):
    try:
        return [l.rstrip("\n") for l in open(path, encoding="utf-8")]
    except FileNotFoundError:
        return []

def entries(lines, copy):
    out, missing, seen = [], [], set()
    for line in lines:
        m = LINE.match(line)
        if not m:
            continue
        day, item = m.group(1), m.group(2).strip()
        if item in seen:
            continue
        seen.add(item)
        text = copy.get(item)
        if text:
            out.append((datetime.date.fromisoformat(day), text))
        else:
            missing.append(item)
    return out, missing

def render(items):
    weeks = {}
    for day, text in items:
        monday = day - datetime.timedelta(days=day.weekday())
        weeks.setdefault(monday, []).append((day, text))
    parts = []
    for monday in sorted(weeks, reverse=True):
        label = f"Week of {monday.day} {monday.strftime('%B %Y')}"
        lis = "\n".join(
            f'                    <li><time datetime="{d.isoformat()}">{d.day} {d.strftime("%b")}</time> {html.escape(t, quote=False).replace("'", "’")}</li>'
            for d, t in sorted(weeks[monday], key=lambda x: x[0], reverse=True))
        parts.append(f'            <section class="wn-week">\n                <h2>{label}</h2>\n'
                     f'                <ul class="wn-list">\n{lis}\n                </ul>\n            </section>')
    return "\n".join(parts)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    copy = json.load(open("tools/whats-new-copy.json", encoding="utf-8"))
    items, missing = entries(log_lines("BACKLOG.md") + log_lines("CHANGELOG.md"), copy)
    page = open(sys.argv[1], encoding="utf-8").read()
    a, b = page.index(START) + len(START), page.index(END)
    page = page[:a] + "\n" + render(items) + "\n            " + page[b:]
    open(sys.argv[1], "w", encoding="utf-8").write(page)
    print(f"wrote {len(items)} entries; no user-facing copy for: {', '.join(missing) or 'none'}", file=sys.stderr)
