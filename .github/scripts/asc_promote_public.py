"""Give public-link testers the newest build: if the newest processed build isn't in the external group yet, submit it
for Beta App Review (skipped when Apple already approved it) and add it to the group. Idempotent; run daily.
Owner OK 2026-11-22 ("yes, auto-release to public testers").
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, APP_ID, GROUP_NAME (default "Public Beta")."""
import os
import sys
import urllib.error

from asc import API, call, make_token

token = make_token(os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_PATH"])
app = os.environ["APP_ID"]
group_name = os.environ.get("GROUP_NAME", "Public Beta")

groups = call("GET", f"{API}/apps/{app}/betaGroups?limit=50", token).get("data", [])
group = next((g for g in groups
              if g["attributes"].get("name") == group_name and not g["attributes"].get("isInternalGroup")), None)
if group is None:
    sys.exit(f"No external beta group named {group_name!r}")

newest = call("GET", f"{API}/builds?filter[app]={app}&filter[processingState]=VALID&filter[expired]=false"
                     f"&sort=-uploadedDate&limit=1", token).get("data", [])
if not newest:
    sys.exit("No valid, unexpired build to promote")
build = newest[0]
number = build["attributes"].get("version")

in_group = {b["id"] for b in call("GET", f"{API}/betaGroups/{group['id']}/builds?limit=200", token).get("data", [])}
if build["id"] in in_group:
    print(f"Build {number} is already available to {group_name}; nothing to do.")
    sys.exit(0)

state = call("GET", f"{API}/builds/{build['id']}/buildBetaDetail", token)["data"]["attributes"].get("externalBuildState")
print(f"Build {number}: external state {state}")
if state == "READY_FOR_BETA_SUBMISSION":
    try:
        call("POST", f"{API}/betaAppReviewSubmissions", token, {
            "data": {"type": "betaAppReviewSubmissions",
                     "relationships": {"build": {"data": {"type": "builds", "id": build["id"]}}}}})
        print(f"Submitted build {number} for Beta App Review.")
    except urllib.error.HTTPError as e:
        sys.exit(f"Review submission refused ({e.code}): {e.read().decode()[:400]}")

call("POST", f"{API}/betaGroups/{group['id']}/relationships/builds", token,
     {"data": [{"type": "builds", "id": build["id"]}]})
print(f"Added build {number} to {group_name}; testers get it once Apple approves (usually within a day).")
