#!/usr/bin/env python3
"""Offline tests for CRL-to-cached-stapled-OCSP selection behavior."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EVALUATOR = ROOT / "evaluate_offline_revocation_cache.py"
POLICY = ROOT / "examples" / "offline-revocation-policy.example.json"
FALLBACK_CACHE = ROOT / "examples" / "offline-revocation-cache.crl-expired-stapled-ocsp-current.example.json"
STALE_CACHE = ROOT / "examples" / "offline-revocation-cache.all-stale.example.json"
ARGS = [
    "--policy", str(POLICY),
    "--certificate-reference", "cert:EXAMPLE-SIGNER-01",
    "--verification-time", "2026-08-22T12:00:00Z",
]


def run(cache: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(EVALUATOR), *ARGS, "--cache-manifest", str(cache)],
        check=False,
        text=True,
        capture_output=True,
    )


def main() -> int:
    fallback = run(FALLBACK_CACHE)
    if fallback.returncode != 0:
        raise AssertionError(f"fallback cache did not select cached OCSP: {fallback.stderr}")
    fallback_json = json.loads(fallback.stdout)
    assert fallback_json["status"] == "stapled-ocsp-selected-requires-cryptographic-verification"
    assert fallback_json["selected_record"] == "stapled_ocsp"
    assert fallback_json["network_accessed"] is False
    assert fallback_json["ocsp_signature_cryptographically_verified"] is False
    assert fallback_json["trust_path_verified"] is False
    assert fallback_json["ministry_approval_established"] is False

    stale = run(STALE_CACHE)
    if stale.returncode != 1:
        raise AssertionError(f"stale cache did not fail closed: {stale.returncode} {stale.stderr}")
    stale_json = json.loads(stale.stdout)
    assert stale_json["status"] == "revocation-status-blocked"
    assert stale_json["selected_record"] is None
    assert stale_json["network_accessed"] is False
    assert stale_json["ministry_approval_established"] is False
    print("offline revocation cache tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
