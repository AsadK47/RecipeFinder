#!/usr/bin/env python3
"""Revoke the Apple Development certificates that Xcode's cloud signing mints on every CI runner.

Each fresh runner has an empty keychain, so `xcodebuild archive -allowProvisioningUpdates` creates a new
"Created via API" development certificate. Apple caps development certificates per account, so without this the
TestFlight workflow starts failing after ~10 runs. Only development certificates named "Created via API" are
touched: the owner's own Mac certificate (named after them) and every distribution certificate are left alone.
TestFlight runs are serialised (concurrency group), so no other run is using these certificates.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (the .p8 written by the workflow). Standard library + openssl only.
"""
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

API = "https://api.appstoreconnect.apple.com/v1"
DEV_TYPES = {"DEVELOPMENT", "IOS_DEVELOPMENT"}
CI_NAME = "Created via API"


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(der: bytes) -> bytes:
    """ECDSA DER signature (SEQUENCE{r INTEGER, s INTEGER}) -> 64-byte r||s, the JWS ES256 format."""
    def read_len(i):
        n = der[i]
        i += 1
        if n & 0x80:
            k = n & 0x7F
            n = int.from_bytes(der[i:i + k], "big")
            i += k
        return n, i

    if der[0] != 0x30:
        raise ValueError("not a DER sequence")
    _, i = read_len(1)
    out = b""
    for _ in range(2):
        if der[i] != 0x02:
            raise ValueError("not a DER integer")
        n, i = read_len(i + 1)
        out += der[i:i + n].lstrip(b"\x00").rjust(32, b"\x00")
        i += n
    return out


def make_token(key_id: str, issuer_id: str, key_path: str) -> str:
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    now = int(time.time())
    payload = {"iss": issuer_id, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"}
    signing_input = f"{b64url(json.dumps(header).encode())}.{b64url(json.dumps(payload).encode())}".encode()
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", key_path],
        input=signing_input, capture_output=True, check=True,
    ).stdout
    return f"{signing_input.decode()}.{b64url(der_to_raw(der))}"


def call(method: str, url: str, token: str):
    req = urllib.request.Request(url, method=method, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read()
        return json.loads(body) if body else None


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
