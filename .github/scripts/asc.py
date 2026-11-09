"""Shared App Store Connect API helpers for CI scripts: ES256 JWT auth with the workflow's .p8 key, and JSON calls.
Standard library + openssl only (runners have both)."""
import base64
import json
import subprocess
import time
import urllib.request

API = "https://api.appstoreconnect.apple.com/v1"


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


def call(method: str, url: str, token: str, body=None):
    headers = {"Authorization": f"Bearer {token}"}
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, method=method, headers=headers, data=data)
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = resp.read()
        return json.loads(body) if body else None
