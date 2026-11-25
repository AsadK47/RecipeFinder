#!/usr/bin/env python3
"""File a short notice for each new TestFlight feedback submission (screenshot + crash) as a GitHub issue labelled
`testflight-feedback`.

The repo is public, so an issue carries no tester content: no comment, screenshot, crash log, device details or email
(Privacy Policy 6.5). It names the kind, the date and the App Store Connect submission id; the owner reads the feedback
in App Store Connect / TestFlight and writes what to fix on the issue in their own words before adding `owner-ok`
(BACKLOG top). Each issue body embeds `<!-- tf:<submission id> -->` so nothing is filed twice.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, BUNDLE_ID, GITHUB_TOKEN, GITHUB_REPOSITORY.
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
        for sub in sorted(submissions, key=lambda s: s.get("attributes", {}).get("createdDate") or ""):
            if sub["id"] in seen:
                continue
            new_issues.append(issue_for(kind, sub))

    for issue in new_issues:
        created = github("POST", f"/repos/{repo}/issues", issue)
        print(f"Filed #{created['number']}: {issue['title']}")
    print(f"{len(new_issues)} new TestFlight feedback item(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
