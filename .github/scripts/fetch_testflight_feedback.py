#!/usr/bin/env python3
"""File a short notice for each new TestFlight feedback submission (screenshot + crash) as a GitHub issue labelled
`testflight-feedback`.

The repo is public, so an issue carries no tester content: no comment, screenshot, crash log, device details or email
(Privacy Policy 6.5). It names the kind, the date and the App Store Connect submission id; the owner reads the feedback
in App Store Connect / TestFlight and writes what to fix on the issue in their own words before adding `owner-ok`
(BACKLOG top). Each issue body embeds `<!-- tf:<submission id> -->` so nothing is filed twice.

Closing a notice keeps the marker (closed issues count), so close one that is no longer needed. For a deletion
request (Privacy 6.6/10.2), delete the submission in App Store Connect first — the API then stops listing it.
Deleting a notice removes its marker, so before deleting one whose submission App Store Connect still lists, the
owner adds its submission id, one per line, to the repository Actions variable `TF_RETIRED_IDS` (Settings → Secrets
and variables → Actions → Variables); the job skips those ids. A variable, not a file: the repo is public and
its history permanent, so a deleted notice leaves no public trace, and the change counts from the next run.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, BUNDLE_ID, GITHUB_TOKEN, GITHUB_REPOSITORY, TF_RETIRED_IDS (optional).
"""
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc import API, call, make_token  # noqa: E402

LABEL = "testflight-feedback"
GITHUB_API = "https://api.github.com"
KINDS = {"betaFeedbackScreenshotSubmissions": "screenshot", "betaFeedbackCrashSubmissions": "crash"}


def fetch_all(url: str, token: str) -> list:
    items = []
    while url:
        page = call("GET", url, token)
        items += page.get("data", [])
        url = page.get("links", {}).get("next")
    return items


def github(method: str, path: str, body=None):
    req = urllib.request.Request(
        f"{GITHUB_API}{path}", method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
                 "Accept": "application/vnd.github+json", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read() or b"null")


def filed_submission_ids(repo: str) -> set:
    ids, page = set(), 1
    while True:
        issues = github("GET", f"/repos/{repo}/issues?labels={LABEL}&state=all&per_page=100&page={page}")
        for issue in issues:
            ids.update(re.findall(r"<!-- tf:([^ ]+) -->", issue.get("body") or ""))
        if len(issues) < 100:
            return ids
        page += 1


def parse_retired(text: str) -> set:
    """Submission ids whose notice was deleted on purpose, from `TF_RETIRED_IDS`: one per line (commas and spaces also
    separate), backticks as copied from a notice ignored. Never printed — the variable is private."""
    return {token for token in re.split(r"[\s,`]+", text or "") if token}


def new_submissions(submissions: list, seen: set, retired: set) -> list:
    """Submissions with no notice yet, oldest first: not filed (`seen`) and not deleted on purpose (`retired`)."""
    fresh = [s for s in submissions if s["id"] not in seen and s["id"] not in retired]
    return sorted(fresh, key=lambda s: s.get("attributes", {}).get("createdDate") or "")


def issue_for(kind: str, sub: dict) -> dict:
    """A notice with no tester content: kind, date and the App Store Connect submission id."""
    date = (sub.get("attributes", {}).get("createdDate") or "")[:10] or "unknown date"
    label = "crash" if kind == "crash" else "feedback"
    lines = [
        f"New TestFlight {label} from {date}. Read it in App Store Connect → TestFlight → Feedback "
        f"(submission `{sub['id']}`).",
        "",
        "Owner: write what to fix below in your own words, then add `owner-ok`. Agents act only on the owner's words.",
        f"<!-- tf:{sub['id']} -->",
    ]
    return {"title": f"TestFlight {label} · {date}", "body": "\n".join(lines), "labels": [LABEL]}


def main() -> int:
    retired = parse_retired(os.environ.get("TF_RETIRED_IDS", ""))
    token = make_token(os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_PATH"])
    bundle_id = os.environ.get("BUNDLE_ID", "com.asadkhan.recipefinder")

    query = urllib.parse.urlencode({"filter[bundleId]": bundle_id})
    apps = call("GET", f"{API}/apps?{query}", token).get("data", [])
    if not apps:
        print(f"No App Store Connect app with bundle id {bundle_id}", file=sys.stderr)
        return 1
    app_id = apps[0]["id"]

    repo = os.environ["GITHUB_REPOSITORY"]
    seen = filed_submission_ids(repo)
    new_issues = []
    for endpoint, kind in KINDS.items():
        try:
            submissions = fetch_all(f"{API}/apps/{app_id}/{endpoint}?limit=200", token)
        except urllib.error.HTTPError as err:
            print(f"Could not list {endpoint}: HTTP {err.code} {err.read()[:300]!r}", file=sys.stderr)
            return 1
        new_issues += [issue_for(kind, sub) for sub in new_submissions(submissions, seen, retired)]

    for issue in new_issues:
        created = github("POST", f"/repos/{repo}/issues", issue)
        print(f"Filed #{created['number']}: {issue['title']}")
    print(f"{len(new_issues)} new TestFlight feedback item(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
