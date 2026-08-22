#!/usr/bin/env python3
"""Offline integration tests for immutable GitOps candidate reconciliation."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CHECKER = ROOT / "reconcile_gitops_deployment_identity.py"
ATTESTATION = ROOT / "examples" / "protected-promotion-closeout.pending-candidate.example.json"
MATCH = ROOT / "examples" / "gitops-deployment-identity.match.example.json"
DRIFT = ROOT / "examples" / "gitops-deployment-identity.image-drift.example.json"


def run(evidence: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(CHECKER),
            "--attestation",
            str(ATTESTATION),
            "--deployment-evidence",
            str(evidence),
            "--attestation-mode",
            "candidate",
        ],
        check=False,
        capture_output=True,
        text=True,
    )


def main() -> int:
    matching = run(MATCH)
    if matching.returncode != 0:
        raise AssertionError(f"matching fixture failed: {matching.stderr}")
    matching_result = json.loads(matching.stdout)
    assert matching_result["status"] == "immutable-candidate-match"
    assert matching_result["mismatches"] == []
    assert matching_result["target_contacted"] is False
    assert matching_result["target_mutated"] is False
    assert matching_result["cryptographic_signature_verified"] is False
    assert matching_result["ministry_approval_established"] is False

    drift = run(DRIFT)
    if drift.returncode != 1:
        raise AssertionError(f"drift fixture did not block with exit 1: {drift.returncode} {drift.stderr}")
    drift_result = json.loads(drift.stdout)
    assert drift_result["status"] == "immutable-candidate-drift"
    assert drift_result["mismatches"] == [
        {
            "field": "image_and_chart_digest_set_sha256",
            "expected": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            "observed": "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
        }
    ]
    assert drift_result["target_contacted"] is False
    assert drift_result["target_mutated"] is False
    assert drift_result["cryptographic_signature_verified"] is False
    assert drift_result["ministry_approval_established"] is False
    print("GitOps immutable-candidate reconciliation tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
