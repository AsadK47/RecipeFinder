#!/usr/bin/env python3
"""Fill TestFlight's "What to Test" for the build just uploaded, so the owner sees what changed without asking.

Waits for App Store Connect to register the build (it appears a few minutes after upload), then creates or updates the
build's beta localization with the notes file. Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, BUNDLE_ID, BUILD_NUMBER,
NOTES_FILE. Standard library + openssl only.
"""
import os
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc import API, call, make_token  # noqa: E402

WAIT_SECONDS = 20 * 60
POLL_SECONDS = 30


def main() -> int:
    key = (os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_PATH"])
    notes = open(os.environ["NOTES_FILE"]).read().strip()[:3900]
    build_number = os.environ["BUILD_NUMBER"]

    token = make_token(*key)
    query = urllib.parse.urlencode({"filter[bundleId]": os.environ.get("BUNDLE_ID", "com.asadkhan.recipefinder")})
    apps = call("GET", f"{API}/apps?{query}", token).get("data", [])
    if not apps:
        print("App not found in App Store Connect", file=sys.stderr)
        return 1
    app = apps[0]
    locale = app.get("attributes", {}).get("primaryLocale") or "en-GB"

    build_query = urllib.parse.urlencode({"filter[app]": app["id"], "filter[version]": build_number, "limit": 1})
    deadline, build = time.time() + WAIT_SECONDS, None
    while time.time() < deadline:
        token = make_token(*key)  # tokens last 10 minutes; re-sign each poll
        found = call("GET", f"{API}/builds?{build_query}", token).get("data", [])
        if found:
            build = found[0]
            break
        print(f"Build {build_number} not in App Store Connect yet; waiting…")
        time.sleep(POLL_SECONDS)
    if build is None:
        print(f"Build {build_number} never appeared; leaving What to Test empty", file=sys.stderr)
        return 1

    existing = call("GET", f"{API}/builds/{build['id']}/betaBuildLocalizations", token).get("data", [])
    if existing:
        loc = next((l for l in existing if l.get("attributes", {}).get("locale") == locale), existing[0])
        call("PATCH", f"{API}/betaBuildLocalizations/{loc['id']}", token, {"data": {
            "type": "betaBuildLocalizations", "id": loc["id"], "attributes": {"whatsNew": notes}}})
    else:
        call("POST", f"{API}/betaBuildLocalizations", token, {"data": {
            "type": "betaBuildLocalizations", "attributes": {"locale": locale, "whatsNew": notes},
            "relationships": {"build": {"data": {"type": "builds", "id": build["id"]}}}}})
    print(f"What to Test set for build {build_number} ({locale}):\n{notes}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
