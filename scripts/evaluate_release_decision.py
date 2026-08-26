#!/usr/bin/env python3
"""Emit a fail-closed release decision from the critical-claim manifest."""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "assurance" / "feature-claim-manifest.json"


def main() -> int:
    document = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    blockers = [
        {"id": claim["id"], "status": claim["status"], "reason": claim["known_limitations"]}
        for claim in document["claims"]
        if claim["status"] != "verified"
    ]
    decision = {
        "schema_version": "blueeconomy.release-decision.v1",
        "decision": "RELEASEABLE" if not blockers else "NOT_RELEASEABLE",
        "blocker_count": len(blockers),
        "blockers": blockers,
    }
    print(json.dumps(decision, indent=2, sort_keys=True))
    return 0 if not blockers else 2


if __name__ == "__main__":
    sys.exit(main())
