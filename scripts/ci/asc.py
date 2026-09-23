#!/usr/bin/env python3
"""App Store Connect API checks for the TestFlight workflow (standard library + openssl only).

Credentials come from the environment: ASC_KEY_ID, ASC_ISSUER_ID (empty for an individual key)
and ASC_KEY_FILE (path to the AuthKey_XXXX.p8 file).

  asc.py normalize-key <raw-p8-text-file> <out.p8>  rebuilds a clean PEM from a pasted secret
  asc.py check-app <bundle-id>                       auth + the app exists → prints its App Store Connect id
  asc.py wait-build <app-id> <build-number> <minutes> waits until Apple lists the uploaded build

Every failure prints an explicit reason and exits with a non-zero status.
"""
import base64
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

API = "https://api.appstoreconnect.apple.com/v1"


def fail(message: str) -> None:
    print(f"::error::{message}")
    sys.exit(1)


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(signature: bytes) -> bytes:
    """ECDSA DER signature (SEQUENCE of two INTEGERs) → 64-byte r || s used by ES256."""
    if len(signature) < 8 or signature[0] != 0x30:
        raise ValueError("unexpected ECDSA signature")
    index = 2 if signature[1] < 0x80 else 2 + (signature[1] & 0x7F)
    parts = []
    for _ in range(2):
        if signature[index] != 0x02:
            raise ValueError("unexpected ECDSA signature")
        length = signature[index + 1]
        value = signature[index + 2:index + 2 + length].lstrip(b"\x00")
        parts.append(value.rjust(32, b"\x00"))
        index += 2 + length
    return b"".join(parts)


def token() -> str:
    key_id = os.environ.get("ASC_KEY_ID", "").strip()
    issuer = os.environ.get("ASC_ISSUER_ID", "").strip()
    key_file = os.environ.get("ASC_KEY_FILE", "")
    if not key_id or not os.path.isfile(key_file):
        fail("ASC_KEY_ID or the .p8 key file is missing.")
    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {"iat": now, "exp": now + 15 * 60, "aud": "appstoreconnect-v1"}
    if issuer:
        payload["iss"] = issuer          # team key
    else:
        payload["sub"] = "user"          # individual key
    signing_input = f"{b64url(json.dumps(header).encode())}.{b64url(json.dumps(payload).encode())}"
    result = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_file],
                            input=signing_input.encode(), capture_output=True)
    if result.returncode != 0:
        fail("Cannot sign with the .p8 key (is ASC_KEY_P8 the full content of AuthKey_XXXX.p8?): "
             + result.stderr.decode().strip())
    return f"{signing_input}.{b64url(der_to_raw(result.stdout))}"


def get(path: str, params: dict) -> dict:
    url = f"{API}/{path}?{urllib.parse.urlencode(params)}"
    request = urllib.request.Request(url, headers={"Authorization": f"Bearer {token()}"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        body = error.read().decode(errors="replace")
        if error.code == 401:
            fail("App Store Connect refused the API key (401 NOT_AUTHORIZED). Check the secrets: "
                 "ASC_KEY_ID = the key's Key ID, ASC_ISSUER_ID = the Issuer ID shown above the team keys "
                 "(empty only for an individual key), ASC_KEY_P8 = the whole .p8 file, BEGIN/END lines "
                 "included. The key must not be revoked. Response: " + body)
        if error.code == 403:
            fail("The API key has no access to this resource (403). Give it the App Manager (or Admin) role. "
                 "Response: " + body)
        fail(f"App Store Connect API error {error.code}: {body}")


def normalize_key(raw_path: str, out_path: str) -> None:
    text = open(raw_path, encoding="utf-8", errors="replace").read()
    text = text.replace("\\n", "\n").replace("\r", "")
    body = re.sub(r"-----(BEGIN|END) [A-Z ]+-----", "", text)
    body = re.sub(r"\s+", "", body)
    if not body or not re.fullmatch(r"[A-Za-z0-9+/=]+", body):
        fail("ASC_KEY_P8 does not look like the content of an AuthKey_XXXX.p8 file.")
    lines = [body[i:i + 64] for i in range(0, len(body), 64)]
    with open(out_path, "w") as out:
        out.write("-----BEGIN PRIVATE KEY-----\n" + "\n".join(lines) + "\n-----END PRIVATE KEY-----\n")
    check = subprocess.run(["openssl", "pkey", "-in", out_path, "-noout"], capture_output=True)
    if check.returncode != 0:
        fail("ASC_KEY_P8 is not a valid private key: " + check.stderr.decode().strip())
    print(f"API key file ready ({len(body)} base64 characters).")


def check_app(bundle_id: str) -> None:
    data = get("apps", {"filter[bundleId]": bundle_id, "fields[apps]": "name,bundleId,sku"})["data"]
    apps = [app for app in data if app["attributes"]["bundleId"] == bundle_id]
    if not apps:
        fail(f"The API key works, but App Store Connect has no app with the bundle ID {bundle_id}. "
             "Create it in App Store Connect → Apps → + New App with exactly this bundle ID.")
    app = apps[0]
    print(f"App Store Connect app: \"{app['attributes']['name']}\" (id {app['id']}, bundle {bundle_id}, "
          f"SKU {app['attributes'].get('sku')})")
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a") as out:
            out.write(f"app_id={app['id']}\n")


def wait_build(app_id: str, build_number: str, minutes: str) -> None:
    deadline = time.time() + float(minutes) * 60
    while True:
        builds = get("builds", {"filter[app]": app_id, "filter[version]": build_number,
                                "fields[builds]": "version,processingState,uploadedDate"})["data"]
        if builds:
            attributes = builds[0]["attributes"]
            state = attributes.get("processingState")
            print(f"Build {build_number} is in App Store Connect: processingState={state}, "
                  f"uploaded {attributes.get('uploadedDate')}")
            if state in ("FAILED", "INVALID"):
                fail(f"Apple rejected build {build_number} while processing it ({state}). "
                     "Check the email Apple sent to the account holder for the reason (ITMS-xxxxx).")
            if state in ("PROCESSING", "VALID"):
                return
        else:
            print(f"Build {build_number} not listed by App Store Connect yet…")
        if time.time() > deadline:
            fail(f"Build {build_number} never appeared in App Store Connect after {minutes} min: "
                 "Apple did not accept the upload.")
        time.sleep(30)


if __name__ == "__main__":
    commands = {"normalize-key": (normalize_key, 2), "check-app": (check_app, 1), "wait-build": (wait_build, 3)}
    if len(sys.argv) < 2 or sys.argv[1] not in commands or len(sys.argv) - 2 != commands[sys.argv[1]][1]:
        print(__doc__)
        sys.exit(2)
    function, _ = commands[sys.argv[1]]
    function(*sys.argv[2:])
