#!/usr/bin/env python3
"""Revoke the Apple Development certificates that Xcode's cloud signing mints on every CI runner.

Each fresh runner has an empty keychain, so `xcodebuild archive -allowProvisioningUpdates` creates a new
"Created via API" development certificate. Apple caps development certificates per account, so without this the
TestFlight workflow starts failing after ~10 runs. Only development certificates named "Created via API" are
touched: the owner's own Mac certificate (named after them) and every distribution certificate are left alone.
TestFlight runs are serialised (concurrency group), so no other run is using these certificates.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (the .p8 written by the workflow). Standard library + openssl only.
"""
import os
import sys
import urllib.error

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc import API, call, make_token  # noqa: E402

DEV_TYPES = {"DEVELOPMENT", "IOS_DEVELOPMENT"}
CI_NAME = "Created via API"


def is_ci_dev_cert(cert: dict) -> bool:
    attrs = cert.get("attributes", {})
    labels = (attrs.get("name") or "", attrs.get("displayName") or "")
    return attrs.get("certificateType") in DEV_TYPES and any(CI_NAME in label for label in labels)


def main() -> int:
    token = make_token(os.environ["ASC_KEY_ID"], os.environ["ASC_ISSUER_ID"], os.environ["ASC_KEY_PATH"])
    certs, url = [], f"{API}/certificates?limit=200"
    while url:
        page = call("GET", url, token)
        certs += page.get("data", [])
        url = page.get("links", {}).get("next")

    targets = [c for c in certs if is_ci_dev_cert(c)]
    print(f"{len(certs)} certificates on the account; revoking {len(targets)} CI development certificate(s)")
    failed = 0
    for cert in targets:
        try:
            call("DELETE", f"{API}/certificates/{cert['id']}", token)
            print(f"  revoked {cert['attributes'].get('serialNumber', cert['id'])}")
        except urllib.error.HTTPError as err:
            failed += 1
            print(f"  could not revoke {cert['id']}: HTTP {err.code} {err.read()[:300]!r}", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
