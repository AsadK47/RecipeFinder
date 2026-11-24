"""Give public-link testers the newest build: if the newest processed build isn't in the external group yet, submit it
for Beta App Review (skipped when Apple already approved it) and add it to the group. Idempotent; run daily.
Any other review state (export compliance missing, rejected, expired, unknown) exits non-zero so the run goes red.
Owner OK 2026-11-22 ("yes, auto-release to public testers").
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, APP_ID, GROUP_NAME (default "Public Beta")."""
import os
import sys
import urllib.error

import asc

# externalBuildState values where the build may sit in the public group (Apple reviews or has approved it).
ADDABLE = {"WAITING_FOR_BETA_REVIEW", "IN_BETA_REVIEW", "BETA_APPROVED", "READY_FOR_BETA_TESTING", "IN_BETA_TESTING"}
SUBMITTABLE = "READY_FOR_BETA_SUBMISSION"


def decide(state, in_group):
    """What to do with the newest build: 'submit_and_add', 'submit', 'add', 'done' or 'fail'.
    State is checked first, so a build already in the group but rejected or stuck still fails the run."""
    if state == SUBMITTABLE:
        return "submit" if in_group else "submit_and_add"
    if state in ADDABLE:
        return "done" if in_group else "add"
    return "fail"


def main(env=os.environ, call=asc.call, make_token=asc.make_token):
    """`call` and `make_token` are parameters so tests can check the requests without the network."""
    API = asc.API
    token = make_token(env["ASC_KEY_ID"], env["ASC_ISSUER_ID"], env["ASC_KEY_PATH"])
    app = env["APP_ID"]
    group_name = env.get("GROUP_NAME", "Public Beta")

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

    state = call("GET", f"{API}/builds/{build['id']}/buildBetaDetail", token)["data"]["attributes"].get(
        "externalBuildState")
    in_group = build["id"] in {b["id"] for b in
                               call("GET", f"{API}/betaGroups/{group['id']}/builds?limit=200", token).get("data", [])}
    action = decide(state, in_group)
    print(f"Build {number}: external state {state}, in {group_name}: {in_group}")

    if action == "fail":
        # stdout, so the reason reaches the run summary (the workflow tees stdout only).
        print(f"Build {number} is {state}; not adding it to {group_name}. Fix it in App Store Connect.")
        sys.exit(1)
    if action == "done":
        print(f"Build {number} is already available to {group_name}; nothing to do.")
        return
    if action in ("submit", "submit_and_add"):
        try:
            call("POST", f"{API}/betaAppReviewSubmissions", token, {
                "data": {"type": "betaAppReviewSubmissions",
                         "relationships": {"build": {"data": {"type": "builds", "id": build["id"]}}}}})
            print(f"Submitted build {number} for Beta App Review.")
        except urllib.error.HTTPError as e:
            sys.exit(f"Review submission refused ({e.code}): {e.read().decode()[:400]}")
    if action in ("add", "submit_and_add"):
        call("POST", f"{API}/betaGroups/{group['id']}/relationships/builds", token,
             {"data": [{"type": "builds", "id": build["id"]}]})
        print(f"Added build {number} to {group_name}; testers get it once Apple approves (usually within a day).")


if __name__ == "__main__":
    main()
