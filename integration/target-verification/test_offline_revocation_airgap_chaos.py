#!/usr/bin/env python3
"""Deterministic air-gapped chaos cases for offline revocation selection.

The tests install a socket-deny sitecustomize guard. They do not create a listener,
contact localhost or access a network. Any attempted socket creation would fail the
case immediately. These are logical partition simulations, not Ministry acceptance.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EVALUATOR = ROOT / "evaluate_offline_revocation_cache.py"
POLICY = ROOT / "examples" / "offline-revocation-policy.example.json"
FALLBACK_CACHE = ROOT / "examples" / "offline-revocation-cache.crl-expired-stapled-ocsp-current.example.json"
CERT = "cert:EXAMPLE-SIGNER-01"
VERIFY_TIME = "2026-08-22T12:00:00Z"

DENY_SOCKET = """\
import socket

def deny(*args, **kwargs):
    raise RuntimeError('SIMULATED_AIRGAP_SOCKET_DENY')

socket.socket = deny
socket.create_connection = deny
socket.getaddrinfo = deny
"""


def write_secure(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")
    path.chmod(0o600)


def run(policy: Path, cache: Path, sitecustomize: Path) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(sitecustomize.parent)
    env.update({"HTTP_PROXY": "http://127.0.0.1:9", "HTTPS_PROXY": "http://127.0.0.1:9", "ALL_PROXY": "http://127.0.0.1:9"})
    return subprocess.run(
        [
            sys.executable,
            str(EVALUATOR),
            "--policy",
            str(policy),
            "--cache-manifest",
            str(cache),
            "--certificate-reference",
            CERT,
            "--verification-time",
            VERIFY_TIME,
        ],
        check=False,
        text=True,
        capture_output=True,
        env=env,
    )


def main() -> int:
    outcomes: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="blueeconomy-airgap-chaos-") as raw:
        workspace = Path(raw)
        sitecustomize = workspace / "sitecustomize.py"
        sitecustomize.write_text(DENY_SOCKET, encoding="utf-8")
        sitecustomize.chmod(0o600)

        fallback_result = run(POLICY, FALLBACK_CACHE, sitecustomize)
        fallback_json = json.loads(fallback_result.stdout)
        assert fallback_result.returncode == 0, fallback_result.stderr
        assert fallback_json["status"] == "stapled-ocsp-selected-requires-cryptographic-verification"
        assert fallback_json["selected_record"] == "stapled_ocsp"
        assert fallback_json["network_accessed"] is False
        outcomes.append({"case": "partition_expired_crl_current_cached_stapled_ocsp", "exit_code": fallback_result.returncode, "status": fallback_json["status"]})

        stale_result = run(POLICY, ROOT / "examples" / "offline-revocation-cache.all-stale.example.json", sitecustomize)
        stale_json = json.loads(stale_result.stdout)
        assert stale_result.returncode == 1, stale_result.stderr
        assert stale_json["status"] == "revocation-status-blocked"
        assert stale_json["selected_record"] is None
        assert stale_json["network_accessed"] is False
        outcomes.append({"case": "partition_all_cached_records_stale", "exit_code": stale_result.returncode, "status": stale_json["status"]})

        policy_data = json.loads(POLICY.read_text(encoding="utf-8"))
        policy_data["rules"]["allow_cached_stapled_ocsp_fallback"] = False
        no_fallback_policy = workspace / "fallback-disabled-policy.json"
        write_secure(no_fallback_policy, policy_data)
        disabled_result = run(no_fallback_policy, FALLBACK_CACHE, sitecustomize)
        disabled_json = json.loads(disabled_result.stdout)
        assert disabled_result.returncode == 1, disabled_result.stderr
        assert disabled_json["status"] == "revocation-status-blocked"
        assert disabled_json["network_accessed"] is False
        outcomes.append({"case": "partition_fallback_disabled_by_policy", "exit_code": disabled_result.returncode, "status": disabled_json["status"]})

        revoked_cache = json.loads(FALLBACK_CACHE.read_text(encoding="utf-8"))
        revoked_cache["entries"][0]["stapled_ocsp"]["status"] = "revoked"
        revoked_path = workspace / "revoked-ocsp-cache.json"
        write_secure(revoked_path, revoked_cache)
        revoked_result = run(POLICY, revoked_path, sitecustomize)
        revoked_json = json.loads(revoked_result.stdout)
        assert revoked_result.returncode == 1, revoked_result.stderr
        assert revoked_json["status"] == "revocation-status-blocked"
        assert revoked_json["network_accessed"] is False
        outcomes.append({"case": "partition_cached_stapled_ocsp_revoked", "exit_code": revoked_result.returncode, "status": revoked_json["status"]})

    print(json.dumps({"suite": "offline-revocation-airgap-chaos", "network_guard": "socket_creation_denied", "target_contacted": False, "cases": outcomes}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
