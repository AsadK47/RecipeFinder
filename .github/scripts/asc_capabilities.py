"""Print the capabilities App Store Connect has on file for each bundle ID given (e.g. to confirm iCloud/CloudKit is
enabled after a developer-portal change). Read-only. Usage: asc_capabilities.py <bundle id> [...]
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH."""
import os
import sys
import urllib.parse

from asc import API, call, make_token

token = make_token(os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_PATH"])
for identifier in sys.argv[1:]:
    query = urllib.parse.urlencode({"filter[identifier]": identifier, "include": "bundleIdCapabilities"})
    resp = call("GET", f"{API}/bundleIds?{query}", token)
    matches = [b for b in resp.get("data", []) if b["attributes"]["identifier"] == identifier]
    if not matches:
        print(f"{identifier}: NOT FOUND")
        continue
    caps = {c["id"]: c for c in resp.get("included", []) if c["type"] == "bundleIdCapabilities"}
    ids = [r["id"] for r in matches[0]["relationships"]["bundleIdCapabilities"].get("data", [])]
    print(f"{identifier}:")
    for cid in ids:
        attrs = caps.get(cid, {}).get("attributes", {})
        settings = "; ".join(
            f"{s.get('key')}=" + ",".join(o.get("key", "") for o in s.get("options", []) if o.get("enabled", True))
            for s in attrs.get("settings") or []
        )
        print(f"  - {attrs.get('capabilityType', cid)}{(' (' + settings + ')') if settings else ''}")
    has_icloud = any(caps.get(cid, {}).get("attributes", {}).get("capabilityType") == "ICLOUD" for cid in ids)
    print(f"  iCloud enabled: {'YES' if has_icloud else 'NO'}")
