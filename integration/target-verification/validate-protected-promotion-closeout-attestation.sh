#!/usr/bin/env bash
# Validates protected-promotion closeout attestation structure offline.
# It never contacts a target, invokes a deployment, reads a secret, or verifies a Ministry signature.

set -euo pipefail
umask 027

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/target_test_common.sh
source "$root/lib/target_test_common.sh"

usage() {
  cat <<'USAGE'
Usage:
  validate-protected-promotion-closeout-attestation.sh \
    --attestation /absolute/path/to/attestation.json \
    --mode template|candidate|approved \
    [--expected-source-commit 40-hex] \
    [--expected-overlay-commit 40-hex] \
    [--expected-rendered-manifest-sha256 64-hex] \
    [--expected-external-secret-manifest-sha256 64-hex] \
    [--expected-image-chart-set-sha256 64-hex]

This offline validator checks repository-owned structure, candidate digest binding,
evidence grouping and forbidden value markers. It does not query a Ministry evidence
system, KMS/HSM, GitHub environment, secret store, Kubernetes cluster, APISIX,
Keycloak, partner interface or target. It does not cryptographically verify a signature
and cannot establish a Ministry approval.

Modes:
  template  Validates an explicitly non-authoritative placeholder template only.
  candidate Validates an unsigned Ministry-controlled candidate pending authorization.
  approved  Validates the shape and binding of an asserted approved payload, but emits
            cryptographic_signature_verified=false. An approved Ministry verifier is
            still required at the final audit gate.
USAGE
}

attestation=''
mode=''
expected_source=''
expected_overlay=''
expected_rendered=''
expected_external_secret=''
expected_image_chart=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --attestation)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      attestation=$2
      shift 2
      ;;
    --mode)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      mode=$2
      shift 2
      ;;
    --expected-source-commit)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      expected_source=$2
      shift 2
      ;;
    --expected-overlay-commit)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      expected_overlay=$2
      shift 2
      ;;
    --expected-rendered-manifest-sha256)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      expected_rendered=$2
      shift 2
      ;;
    --expected-external-secret-manifest-sha256)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      expected_external_secret=$2
      shift 2
      ;;
    --expected-image-chart-set-sha256)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      expected_image_chart=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 64
      ;;
  esac
done

[[ -n "$attestation" && -n "$mode" ]] || { usage >&2; exit 64; }
case "$mode" in template|candidate|approved) ;; *) usage >&2; exit 64 ;; esac
for command in jq sha256sum stat date; do require_command "$command"; done
[[ "$attestation" = /* ]] || usage_error 'attestation path must be absolute'
assert_private_regular_file "$attestation"

sha_re='^[a-fA-F0-9]{64}$'
git_re='^[a-fA-F0-9]{40}$'
for pair in \
  "expected_source:$expected_source:$git_re" \
  "expected_overlay:$expected_overlay:$git_re" \
  "expected_rendered:$expected_rendered:$sha_re" \
  "expected_external_secret:$expected_external_secret:$sha_re" \
  "expected_image_chart:$expected_image_chart:$sha_re"; do
  IFS=: read -r name value pattern <<< "$pair"
  [[ -z "$value" || "$value" =~ $pattern ]] || usage_error "$name must be a valid digest when supplied"
done

jq -e 'type == "object"' "$attestation" >/dev/null || usage_error 'attestation must be a JSON object'

# Reject content markers that should never be retained in a closeout attestation.
if grep -I -n -E -- '-----BEGIN [A-Z ]*PRIVATE KEY-----|[Aa]uthorization:[[:space:]]*[Bb]earer[[:space:]]|(^|[^[:alnum:]_])(access_token|refresh_token|client_secret|password)[[:space:]]*[:=]' \
  "$attestation" >/dev/null; then
  usage_error 'attestation contains a prohibited sensitive-content marker'
fi

reference_re='^[A-Za-z0-9._:/@+=-]{3,512}$'

if [[ "$mode" == template ]]; then
  jq -e '
    .schema_version == "blueeconomy.protected-promotion-closeout.v1" and
    .document_type == "template_only" and
    .status == "template_not_signed_not_approved" and
    .promotion_decision.decision == "not_approved_template_only" and
    .signature.status == "placeholder_not_a_signature" and
    .signature.signature_value == "NOT_A_VALID_SIGNATURE"
  ' "$attestation" >/dev/null || usage_error 'template must be explicitly non-authoritative and unsigned'

  jq -n \
    --arg schema_version 'blueeconomy.protected-promotion-closeout-validation.v1' \
    --arg attestation_sha256 "$(sha256sum -- "$attestation" | awk '{print $1}')" \
    --arg validated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$schema_version,mode:"template",attestation_sha256:$attestation_sha256,validated_at:$validated_at,status:"template-structurally-valid",target_contacted:false,target_mutated:false,cryptographic_signature_verified:false,ministry_approval_established:false}'
  exit 0
fi

# Candidate and approved payloads must have realistic, non-placeholder structured fields.
jq -e --arg ref "$reference_re" '
  .schema_version == "blueeconomy.protected-promotion-closeout.v1" and
  .document_type == "ministry_controlled_attestation" and
  (.status | IN("pending_authorized_signature", "approved", "rejected", "expired")) and
  (.attestation_id | type == "string" and test($ref)) and
  (.issued_at | type == "string" and fromdateiso8601? != null) and
  (.expires_at | type == "string" and fromdateiso8601? != null) and
  ((.expires_at | fromdateiso8601) > (.issued_at | fromdateiso8601)) and
  (.scope | type == "object" and
    (.environment_reference | type == "string" and test($ref)) and
    (.namespace_reference | type == "string" and test($ref)) and
    (.change_authorization_reference | type == "string" and test($ref)) and
    .promotion_mode == "gitops_only") and
  (.candidate | type == "object" and
    (.source_commit_sha | type == "string" and test("^[a-fA-F0-9]{40}$")) and
    (.environment_overlay_commit_sha | type == "string" and test("^[a-fA-F0-9]{40}$")) and
    (.rendered_manifest_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) and
    (.external_secret_manifest_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) and
    (.image_and_chart_digest_set_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$"))) and
  (.required_evidence | type == "array" and length == 4 and
    ([.[].control] | sort == ["P1-P4", "P13-P18", "P5-P7", "P8-P12"]) and
    all(.[]; (.kind | type == "string" and test($ref)) and
      (.reference | type == "string" and test($ref)) and
      (.sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) and
      (.status | IN("required", "verified", "rejected", "expired")))) and
  (.automated_checks | type == "array" and length > 0 and
    all(.[]; (.name | type == "string" and test($ref)) and
      (.run_reference | type == "string" and test($ref)) and
      (.source_commit_sha | type == "string" and test("^[a-fA-F0-9]{40}$")) and
      (.status == "passed"))) and
  (.review | type == "object" and
    (.independent_reviewer_role | type == "string" and test($ref)) and
    (.review_outcome | IN("pending_authorized_signature", "accepted", "rejected", "exception_accepted")) and
    (.findings_reference | type == "string") and
    (.exception_reference | type == "string")) and
  (.promotion_decision | type == "object" and
    (.decision | IN("pending_authorized_signature", "approved", "rejected", "expired")) and
    (.gitops_reconciler_reference | type == "string" and test($ref)) and
    (.rollback_reference | type == "string" and test($ref)) and
    (.post_promotion_verification_reference | type == "string" and test($ref))) and
  (.signature | type == "object" and
    (.status | IN("not_signed", "present", "verified", "rejected")) and
    (.algorithm | type == "string" and test($ref)) and
    (.signer_key_id | type == "string" and test($ref)) and
    (.signature_reference | type == "string" and test($ref)) and
    (.signature_value | type == "string" and length > 0 and . != "NOT_A_VALID_SIGNATURE"))
' "$attestation" >/dev/null || usage_error 'attestation fails repository-owned structural/profile validation'

case "$mode" in
  candidate)
    jq -e '.status == "pending_authorized_signature" and .promotion_decision.decision == "pending_authorized_signature" and .signature.status == "not_signed"' "$attestation" >/dev/null || usage_error 'candidate must remain unsigned and pending authorization'
    ;;
  approved)
    jq -e '.status == "approved" and .promotion_decision.decision == "approved" and (.review.review_outcome | IN("accepted", "exception_accepted")) and (.signature.status | IN("present", "verified"))' "$attestation" >/dev/null || usage_error 'approved profile must assert a completed review, promotion decision and signature presence'
    ;;
esac

[[ -z "$expected_source" || "$(jq -r '.candidate.source_commit_sha' "$attestation")" == "$expected_source" ]] || usage_error 'source commit does not match expected candidate'
[[ -z "$expected_overlay" || "$(jq -r '.candidate.environment_overlay_commit_sha' "$attestation")" == "$expected_overlay" ]] || usage_error 'overlay commit does not match expected candidate'
[[ -z "$expected_rendered" || "$(jq -r '.candidate.rendered_manifest_sha256' "$attestation")" == "$expected_rendered" ]] || usage_error 'rendered manifest digest does not match expected candidate'
[[ -z "$expected_external_secret" || "$(jq -r '.candidate.external_secret_manifest_sha256' "$attestation")" == "$expected_external_secret" ]] || usage_error 'ExternalSecret manifest digest does not match expected candidate'
[[ -z "$expected_image_chart" || "$(jq -r '.candidate.image_and_chart_digest_set_sha256' "$attestation")" == "$expected_image_chart" ]] || usage_error 'image/chart digest-set does not match expected candidate'

jq -n \
  --arg schema_version 'blueeconomy.protected-promotion-closeout-validation.v1' \
  --arg mode "$mode" \
  --arg attestation_sha256 "$(sha256sum -- "$attestation" | awk '{print $1}')" \
  --arg validated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{schema_version:$schema_version,mode:$mode,attestation_sha256:$attestation_sha256,validated_at:$validated_at,status:"repository-profile-valid",target_contacted:false,target_mutated:false,cryptographic_signature_verified:false,ministry_approval_established:false}'
