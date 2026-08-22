#!/usr/bin/env python3
"""Offline immutable-candidate binding check for protected GitOps promotion.

This program consumes an attestation and a Ministry-approved deployment-identity
*export* supplied as local files. It does not use a Kubernetes client, Git provider
API, network connection, credentials, target endpoint, signature service or KMS/HSM.
It cannot establish Ministry approval or cryptographic signature validity.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

SCHEMA_ATTESTATION = "blueeconomy.protected-promotion-closeout.v1"
SCHEMA_DEPLOYMENT = "blueeconomy.gitops-deployment-identity.v1"
SCHEMA_RESULT = "blueeconomy.gitops-candidate-reconciliation.v1"
SHA256_RE = re.compile(r"^[a-fA-F0-9]{64}$")
GIT_SHA_RE = re.compile(r"^[a-fA-F0-9]{40}$")
REFERENCE_RE = re.compile(r"^[A-Za-z0-9._:/@+=-]{3,512}$")
SENSITIVE_KEY_RE = re.compile(r"^(?:password|client_secret|access_token|refresh_token|private_key)$", re.IGNORECASE)
SENSITIVE_TEXT_RE = re.compile(
    r"-----BEGIN [A-Z ]*PRIVATE KEY-----|"
    r"[Aa]uthorization:\s*[Bb]earer\s+|"
    r"(^|[^A-Za-z0-9_])(access_token|refresh_token|client_secret|password)\"?\s*[:=]"
)


class ValidationError(ValueError):
    """Raised for unsafe, malformed or incompatible local evidence."""


def error(message: str) -> None:
    print(f"gitops-reconciliation: {message}", file=sys.stderr)
    raise SystemExit(64)


def require_secure_file(raw: str, label: str) -> Path:
    path = Path(raw)
    if not path.is_absolute():
        error(f"{label} must be an absolute path")
    if path.is_symlink() or not path.is_file():
        error(f"{label} must be a regular non-symlink file")
    resolved = path.resolve(strict=True)
    if resolved != path:
        error(f"{label} must be canonical")
    mode = stat.S_IMODE(path.stat().st_mode)
    if mode & 0o022:
        error(f"{label} must not be group- or world-writable")
    return path


def no_duplicate_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValidationError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load_json(path: Path, label: str) -> dict[str, Any]:
    try:
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw, object_pairs_hook=no_duplicate_pairs)
    except (OSError, UnicodeError, json.JSONDecodeError, ValidationError) as exc:
        error(f"{label} is not safe UTF-8 JSON: {exc}")
    if not isinstance(data, dict):
        error(f"{label} must be a JSON object")
    if SENSITIVE_TEXT_RE.search(raw):
        error(f"{label} contains a prohibited sensitive-content marker")
    reject_sensitive_keys(data, label)
    return data


def reject_sensitive_keys(value: Any, label: str, path: str = "$") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if SENSITIVE_KEY_RE.search(key):
                error(f"{label} contains prohibited sensitive field name at {path}.{key}")
            reject_sensitive_keys(child, label, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            reject_sensitive_keys(child, label, f"{path}[{index}]")


def require_dict(parent: dict[str, Any], key: str, label: str) -> dict[str, Any]:
    value = parent.get(key)
    if not isinstance(value, dict):
        error(f"{label}.{key} must be an object")
    return value


def require_string(parent: dict[str, Any], key: str, label: str, pattern: re.Pattern[str] | None = None) -> str:
    value = parent.get(key)
    if not isinstance(value, str) or not value:
        error(f"{label}.{key} must be a non-empty string")
    if pattern and not pattern.fullmatch(value):
        error(f"{label}.{key} has invalid format")
    return value


def require_timestamp(parent: dict[str, Any], key: str, label: str) -> str:
    value = require_string(parent, key, label)
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        error(f"{label}.{key} must be RFC3339-compatible")
    return value


def validate_attestation(attestation: dict[str, Any], mode: str) -> dict[str, str]:
    if attestation.get("schema_version") != SCHEMA_ATTESTATION:
        error("attestation schema_version is unsupported")
    if attestation.get("document_type") != "ministry_controlled_attestation":
        error("attestation must be a Ministry-controlled profile")
    if mode == "candidate":
        if attestation.get("status") != "pending_authorized_signature":
            error("candidate mode requires pending_authorized_signature status")
        if require_dict(attestation, "promotion_decision", "attestation").get("decision") != "pending_authorized_signature":
            error("candidate mode requires pending promotion decision")
    else:
        if attestation.get("status") != "approved":
            error("approved mode requires asserted approved status")
        if require_dict(attestation, "promotion_decision", "attestation").get("decision") != "approved":
            error("approved mode requires asserted approved promotion decision")

    candidate = require_dict(attestation, "candidate", "attestation")
    scope = require_dict(attestation, "scope", "attestation")
    decision = require_dict(attestation, "promotion_decision", "attestation")
    if scope.get("promotion_mode") != "gitops_only":
        error("attestation.scope.promotion_mode must be gitops_only")

    required = {
        "source_commit_sha": require_string(candidate, "source_commit_sha", "attestation.candidate", GIT_SHA_RE),
        "environment_overlay_commit_sha": require_string(candidate, "environment_overlay_commit_sha", "attestation.candidate", GIT_SHA_RE),
        "rendered_manifest_sha256": require_string(candidate, "rendered_manifest_sha256", "attestation.candidate", SHA256_RE),
        "external_secret_manifest_sha256": require_string(candidate, "external_secret_manifest_sha256", "attestation.candidate", SHA256_RE),
        "image_and_chart_digest_set_sha256": require_string(candidate, "image_and_chart_digest_set_sha256", "attestation.candidate", SHA256_RE),
        "gitops_reconciler_reference": require_string(decision, "gitops_reconciler_reference", "attestation.promotion_decision", REFERENCE_RE),
    }
    return required


def validate_deployment_export(export: dict[str, Any]) -> dict[str, str]:
    if export.get("schema_version") != SCHEMA_DEPLOYMENT:
        error("deployment evidence schema_version is unsupported")
    if export.get("export_kind") != "ministry_controlled_offline_export":
        error("deployment evidence must identify a Ministry-controlled offline export")
    require_timestamp(export, "observed_at", "deployment_evidence")
    gitops = require_dict(export, "gitops", "deployment_evidence")
    artifacts = require_dict(export, "artifacts", "deployment_evidence")
    if gitops.get("reconciliation_status") != "synced":
        error("deployment evidence reconciliation_status must be synced")
    if gitops.get("direct_apply_detected") is not False:
        error("deployment evidence must explicitly report direct_apply_detected=false")

    return {
        "source_commit_sha": require_string(artifacts, "source_commit_sha", "deployment_evidence.artifacts", GIT_SHA_RE),
        "environment_overlay_commit_sha": require_string(gitops, "reconciled_overlay_commit_sha", "deployment_evidence.gitops", GIT_SHA_RE),
        "rendered_manifest_sha256": require_string(artifacts, "rendered_manifest_sha256", "deployment_evidence.artifacts", SHA256_RE),
        "external_secret_manifest_sha256": require_string(artifacts, "external_secret_manifest_sha256", "deployment_evidence.artifacts", SHA256_RE),
        "image_and_chart_digest_set_sha256": require_string(artifacts, "image_and_chart_digest_set_sha256", "deployment_evidence.artifacts", SHA256_RE),
        "gitops_reconciler_reference": require_string(gitops, "reconciler_reference", "deployment_evidence.gitops", REFERENCE_RE),
    }


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--attestation", required=True, help="absolute local attestation JSON path")
    parser.add_argument("--deployment-evidence", required=True, help="absolute local GitOps identity export JSON path")
    parser.add_argument("--attestation-mode", choices=("candidate", "approved"), required=True)
    args = parser.parse_args()

    attestation_path = require_secure_file(args.attestation, "attestation")
    evidence_path = require_secure_file(args.deployment_evidence, "deployment evidence")
    expected = validate_attestation(load_json(attestation_path, "attestation"), args.attestation_mode)
    observed = validate_deployment_export(load_json(evidence_path, "deployment evidence"))

    mismatches = [
        {"field": key, "expected": expected[key], "observed": observed[key]}
        for key in sorted(expected)
        if expected[key] != observed[key]
    ]
    result = {
        "schema_version": SCHEMA_RESULT,
        "attestation_mode": args.attestation_mode,
        "attestation_sha256": sha256_file(attestation_path),
        "deployment_evidence_sha256": sha256_file(evidence_path),
        "status": "immutable-candidate-match" if not mismatches else "immutable-candidate-drift",
        "mismatches": mismatches,
        "target_contacted": False,
        "target_mutated": False,
        "cryptographic_signature_verified": False,
        "ministry_approval_established": False,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if not mismatches else 1


if __name__ == "__main__":
    raise SystemExit(main())
