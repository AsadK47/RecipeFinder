"""Print TestFlight beta groups for the app: internal/external, public link on/limit/criteria, testers, and the
newest builds each group can install (version, upload date, expiry, external review state). Read-only.
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, APP_ID."""
import os

from asc import API, call, make_token

token = make_token(os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_PATH"])
app = os.environ["APP_ID"]

groups = call("GET", f"{API}/apps/{app}/betaGroups?limit=50", token).get("data", [])
for g in groups:
    a = g["attributes"]
    print(f"Group: {a.get('name')} | internal={a.get('isInternalGroup')} | publicLink={a.get('publicLinkEnabled')} "
          f"| limitOn={a.get('publicLinkLimitEnabled')} limit={a.get('publicLinkLimit')} "
          f"| feedback={a.get('feedbackEnabled')} | criteria={'yes' if a.get('hasAccessToAllBuilds') is None else a.get('hasAccessToAllBuilds')}")
    testers = call("GET", f"{API}/betaGroups/{g['id']}/relationships/betaTesters?limit=200", token)
    print(f"  testers: {len(testers.get('data', []))}")
    builds = call("GET", f"{API}/betaGroups/{g['id']}/builds?limit=200", token)
    rows = sorted(builds.get("data", []), key=lambda b: b["attributes"].get("uploadedDate", ""), reverse=True)[:3]
    if not rows:
        print("  builds: NONE (testers in this group have nothing to install)")
    for b in rows:
        ba = b["attributes"]
        d = call("GET", f"{API}/builds/{b['id']}/buildBetaDetail", token).get("data", {}).get("attributes", {})
        print(f"  build {ba.get('version')} uploaded {ba.get('uploadedDate', '')[:10]} expires {ba.get('expirationDate', '')[:10]} "
              f"expired={ba.get('expired')} minOS={ba.get('minOsVersion')} external={d.get('externalBuildState')}")

latest = call("GET", f"{API}/builds?filter[app]={app}&sort=-uploadedDate&limit=1&include=buildBetaDetail", token)
for b in latest.get("data", []):
    d = next((x["attributes"] for x in latest.get("included", []) if x["type"] == "buildBetaDetails"), {})
    print(f"Newest upload: build {b['attributes'].get('version')} ({b['attributes'].get('uploadedDate', '')[:10]}) "
          f"external={d.get('externalBuildState')} internal={d.get('internalBuildState')}")
