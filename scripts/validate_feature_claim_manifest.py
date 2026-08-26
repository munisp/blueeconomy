#!/usr/bin/env python3
"""Validate structural completeness of the platform critical-claim manifest.

This source-only gate never upgrades a claim to verified. Release status is
calculated separately and remains fail closed while mandatory claims are not
verified at an immutable revision.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "assurance" / "feature-claim-manifest.json"
ASSERTED_PATH = ROOT / "assurance" / "asserted-critical-capabilities.txt"
STATUSES = {"verified", "blocked", "incomplete", "retired", "not_applicable"}
REQUIRED_FIELDS = {
    "id",
    "claim",
    "source_of_truth",
    "owner_component",
    "entry_points",
    "implementation_paths",
    "schema_migration_paths",
    "runtime_config_paths",
    "evidence",
    "security_audit_requirements",
    "data_classification",
    "owner",
    "status",
    "last_verified_revision",
    "known_limitations",
}
SHA = re.compile(r"^[0-9a-f]{40}$")


def fail(message: str) -> None:
    raise SystemExit(f"feature claim manifest invalid: {message}")


def main() -> int:
    try:
        document = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(str(error))
    if document.get("schema_version") != "blueeconomy.feature-claim-manifest.v1":
        fail("schema_version must be blueeconomy.feature-claim-manifest.v1")
    claims = document.get("claims")
    if not isinstance(claims, list) or not claims:
        fail("claims must be a non-empty list")
    identifiers: set[str] = set()
    for claim in claims:
        if not isinstance(claim, dict):
            fail("each claim must be an object")
        missing = REQUIRED_FIELDS - claim.keys()
        if missing:
            fail(f"claim {claim.get('id', '<unknown>')} is missing {sorted(missing)}")
        identifier = claim["id"]
        if not isinstance(identifier, str) or not re.fullmatch(r"[A-Z0-9-]+", identifier):
            fail("claim ID must use stable upper-case hyphenated syntax")
        if identifier in identifiers:
            fail(f"duplicate claim ID {identifier}")
        identifiers.add(identifier)
        if claim["status"] not in STATUSES:
            fail(f"claim {identifier} has invalid status")
        if not isinstance(claim["known_limitations"], str) or not claim["known_limitations"].strip():
            fail(f"claim {identifier} needs explicit known_limitations")
        for field in ("entry_points", "implementation_paths", "evidence", "security_audit_requirements"):
            if not isinstance(claim[field], list) or not claim[field]:
                fail(f"claim {identifier} needs non-empty {field}")
        revision = claim["last_verified_revision"]
        if claim["status"] == "verified":
            if not isinstance(revision, str) or not SHA.fullmatch(revision):
                fail(f"verified claim {identifier} needs a 40-character immutable revision")
        elif revision is not None:
            fail(f"non-verified claim {identifier} must not imply a verified revision")
    asserted = {
        line.strip()
        for line in ASSERTED_PATH.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    missing_assertions = asserted - identifiers
    if missing_assertions:
        fail(f"asserted critical capabilities lack manifest records: {sorted(missing_assertions)}")
    print(json.dumps({"claim_count": len(claims), "asserted_claim_count": len(asserted)}, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
