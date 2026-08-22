#!/usr/bin/env python3
"""Evaluate an air-gapped CRL/OCSP cache selection policy without network access.

This utility selects an eligible cached revocation record for a certificate reference.
It does not fetch CRL/OCSP endpoints, verify CRL/OCSP signatures, validate a certificate
chain, access a KMS/HSM, or establish Ministry approval. A selected record must still
be cryptographically verified by the Ministry final-audit verifier.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import stat
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

POLICY_SCHEMA = "blueeconomy.offline-revocation-policy.v1"
CACHE_SCHEMA = "blueeconomy.offline-revocation-cache.v1"
RESULT_SCHEMA = "blueeconomy.offline-revocation-selection.v1"
REF_RE = re.compile(r"^[A-Za-z0-9._:/@+=-]{3,512}$")
SHA256_RE = re.compile(r"^[a-fA-F0-9]{64}$")


def fail(message: str) -> None:
    print(f"offline-revocation-cache: {message}", file=sys.stderr)
    raise SystemExit(64)


def require_secure_file(raw: str, label: str) -> Path:
    path = Path(raw)
    if not path.is_absolute() or path.is_symlink() or not path.is_file():
        fail(f"{label} must be an absolute, regular, non-symlink file")
    if path.resolve(strict=True) != path:
        fail(f"{label} must be canonical")
    if stat.S_IMODE(path.stat().st_mode) & 0o022:
        fail(f"{label} must not be group- or world-writable")
    return path


def unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def load_json(path: Path, label: str) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
        fail(f"{label} must be safe UTF-8 JSON: {exc}")
    if not isinstance(data, dict):
        fail(f"{label} must be a JSON object")
    return data


def get_dict(parent: dict[str, Any], key: str, label: str) -> dict[str, Any]:
    value = parent.get(key)
    if not isinstance(value, dict):
        fail(f"{label}.{key} must be an object")
    return value


def get_bool(parent: dict[str, Any], key: str, label: str) -> bool:
    value = parent.get(key)
    if not isinstance(value, bool):
        fail(f"{label}.{key} must be boolean")
    return value


def get_str(parent: dict[str, Any], key: str, label: str, pattern: re.Pattern[str] | None = None) -> str:
    value = parent.get(key)
    if not isinstance(value, str) or not value:
        fail(f"{label}.{key} must be a non-empty string")
    if pattern is not None and not pattern.fullmatch(value):
        fail(f"{label}.{key} has invalid format")
    return value


def parse_time(raw: str, label: str) -> datetime:
    try:
        parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        fail(f"{label} must be RFC3339-compatible")
    if parsed.tzinfo is None:
        fail(f"{label} must include a timezone")
    return parsed.astimezone(timezone.utc)


def parse_optional_time(value: Any, label: str) -> datetime | None:
    if value is None:
        return None
    if not isinstance(value, str):
        fail(f"{label} must be a string when supplied")
    return parse_time(value, label)


def digest(path: Path) -> str:
    sha = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            sha.update(block)
    return sha.hexdigest()


def valid_good_record(record: dict[str, Any], now: datetime, label: str) -> bool:
    if record.get("status") != "good":
        return False
    this_update = parse_time(get_str(record, "this_update", label), f"{label}.this_update")
    next_update = parse_time(get_str(record, "next_update", label), f"{label}.next_update")
    produced_at = parse_optional_time(record.get("produced_at"), f"{label}.produced_at")
    if this_update > now or next_update < now or next_update <= this_update:
        return False
    if produced_at is not None and produced_at > now:
        return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--policy", required=True, help="absolute offline policy JSON path")
    parser.add_argument("--cache-manifest", required=True, help="absolute offline cache manifest JSON path")
    parser.add_argument("--certificate-reference", required=True, help="non-secret certificate/key reference")
    parser.add_argument("--verification-time", required=True, help="RFC3339 verification time")
    args = parser.parse_args()

    if not REF_RE.fullmatch(args.certificate_reference):
        fail("certificate reference has invalid format")
    policy_path = require_secure_file(args.policy, "policy")
    cache_path = require_secure_file(args.cache_manifest, "cache manifest")
    now = parse_time(args.verification_time, "verification time")
    policy = load_json(policy_path, "policy")
    cache = load_json(cache_path, "cache manifest")

    if policy.get("schema_version") != POLICY_SCHEMA or policy.get("document_type") != "offline_policy_example_or_approved_policy":
        fail("policy schema/profile is unsupported")
    rules = get_dict(policy, "rules", "policy")
    if get_bool(rules, "air_gapped", "policy.rules") is not True:
        fail("policy must explicitly be air-gapped")
    if get_bool(rules, "direct_network_fetch_permitted", "policy.rules") is not False:
        fail("policy must forbid direct network fetch")
    fallback_allowed = get_bool(rules, "allow_cached_stapled_ocsp_fallback", "policy.rules")

    if cache.get("schema_version") != CACHE_SCHEMA or cache.get("export_kind") != "controlled_offline_cache_manifest":
        fail("cache manifest schema/profile is unsupported")
    get_str(cache, "manifest_signature_reference", "cache manifest", REF_RE)
    entries = cache.get("entries")
    if not isinstance(entries, list):
        fail("cache manifest.entries must be an array")
    matches = [entry for entry in entries if isinstance(entry, dict) and entry.get("certificate_reference") == args.certificate_reference]
    if len(matches) != 1:
        fail("cache manifest must contain exactly one entry for certificate reference")
    entry = matches[0]
    crl = get_dict(entry, "crl", "cache entry")
    stapled = get_dict(entry, "stapled_ocsp", "cache entry")

    if valid_good_record(crl, now, "cache entry.crl"):
        status = "crl-selected-requires-cryptographic-verification"
        selected = "crl"
        exit_code = 0
        reason = "cached-crl-good-and-current"
    elif fallback_allowed and valid_good_record(stapled, now, "cache entry.stapled_ocsp"):
        status = "stapled-ocsp-selected-requires-cryptographic-verification"
        selected = "stapled_ocsp"
        exit_code = 0
        reason = "cached-crl-expired-or-not-good; policy-permitted-cached-stapled-ocsp-fallback"
    else:
        status = "revocation-status-blocked"
        selected = None
        exit_code = 1
        reason = "no-current-good-cached-crl-or-policy-permitted-current-stapled-ocsp"

    result = {
        "schema_version": RESULT_SCHEMA,
        "verification_time": now.isoformat().replace("+00:00", "Z"),
        "certificate_reference": args.certificate_reference,
        "policy_sha256": digest(policy_path),
        "cache_manifest_sha256": digest(cache_path),
        "status": status,
        "selected_record": selected,
        "selection_reason": reason,
        "network_accessed": False,
        "crl_signature_cryptographically_verified": False,
        "ocsp_signature_cryptographically_verified": False,
        "trust_path_verified": False,
        "ministry_approval_established": False,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
