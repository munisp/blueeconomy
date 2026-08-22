#!/usr/bin/env bash
# Validates a completed authorised target-test evidence bundle offline.
# It never contacts a target, invokes a case runner, or signs/verifies with KMS/HSM.

set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/target_test_common.sh
source "$root/lib/target_test_common.sh"

usage() {
  cat <<'USAGE'
Usage: validate-target-evidence-bundle.sh --artifact-dir /absolute/path/to/run

The input must be an evidence bundle created by an authorised target suite using
manifest/summary schema v3. This validator checks local structural consistency,
file modes, runner/verifier digest bindings, redaction field names and manifest
hash records. It does not invoke an external KMS/HSM verifier and cannot itself
establish Ministry acceptance.
USAGE
}

[[ $# -eq 2 && "$1" == '--artifact-dir' ]] || { usage >&2; exit 64; }
artifact_dir=$2
[[ "$artifact_dir" = /* ]] || usage_error 'artifact directory must be an absolute path'
assert_secure_directory "$artifact_dir"
for command in jq sha256sum stat find sort awk diff realpath; do require_command "$command"; done

manifest="$artifact_dir/manifest.json"
summary="$artifact_dir/summary.json"
evidence_manifest="$artifact_dir/evidence-manifest.json"
attestation="$artifact_dir/integrity-attestation.json"
for file in "$manifest" "$summary" "$evidence_manifest" "$attestation"; do
  assert_private_regular_file "$file"
done

manifest_values=$(jq -er '
  select(.schema_version == "blueeconomy.target-test-manifest.v3") |
  select(.suite | type == "string" and test("^(maritime-feed-target|regulated-payment-target)$")) |
  select(.target_environment | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) |
  select(.authorization_reference | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) |
  select(.runbook_reference | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) |
  select(.runbook_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) |
  select(.artifact_root_id | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) |
  select(.case_runner_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) |
  select(.integrity_verifier_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) |
  select(.run_id | type == "string" and test("^[A-Za-z0-9._:-]{3,512}$")) |
  select(.planned_cases | type == "array" and length > 0 and all(.[]; type == "string" and test("^[a-z0-9_]+$"))) |
  [.suite,.target_environment,.run_id,.runbook_sha256,.artifact_root_id,.case_runner_sha256,.integrity_verifier_sha256] | @tsv
' "$manifest") || usage_error 'manifest lacks required v3 target-acceptance bindings'
IFS=$'\t' read -r suite target_environment run_id runbook_sha256 artifact_root_id case_runner_sha256 integrity_verifier_sha256 <<< "$manifest_values"
TARGET_TEST_RUN_ID=$run_id
export TARGET_TEST_RUN_ID

jq -e \
  --arg suite "$suite" \
  --arg environment "$target_environment" \
  --arg run_id "$run_id" \
  --arg runbook_sha256 "$runbook_sha256" \
  --arg artifact_root_id "$artifact_root_id" \
  --arg case_runner_sha256 "$case_runner_sha256" \
  --arg integrity_verifier_sha256 "$integrity_verifier_sha256" '
    .schema_version == "blueeconomy.target-test-summary.v3" and
    .suite == $suite and
    .target_environment == $environment and
    .run_id == $run_id and
    .runbook_sha256 == $runbook_sha256 and
    .artifact_root_id == $artifact_root_id and
    .case_runner_sha256 == $case_runner_sha256 and
    .integrity_verifier_sha256 == $integrity_verifier_sha256 and
    .status == "passed" and
    (.completed_cases | type == "array" and length > 0 and all(.[]; type == "string" and test("^[a-z0-9_]+$"))) and
    ((.completed_cases | length) == (.completed_cases | unique | length))
  ' "$summary" >/dev/null || usage_error 'summary does not bind the approved v3 manifest identity and runner digests'

reject_sensitive_result_fields "$manifest"
reject_sensitive_result_fields "$summary"
if grep -R -I -n -E '-----BEGIN [A-Z ]*PRIVATE KEY-----|[Aa]uthorization:[[:space:]]*[Bb]earer[[:space:]]|(^|[^[:alnum:]_])(access_token|refresh_token|client_secret|password)[[:space:]]*[:=]' \
  "$artifact_dir" --exclude='integrity-attestation.json' --exclude='evidence-manifest.json' --exclude='integrity.stdout.log' --exclude='integrity.stderr.log' >/dev/null; then
  usage_error 'evidence bundle contains a prohibited sensitive-content marker'
fi

while IFS= read -r test_case; do
  validate_case_result \
    "$artifact_dir/cases/$test_case/result.json" \
    "$test_case" \
    "$suite" \
    "$target_environment"
done < <(jq -r '.completed_cases[]' "$summary")

jq -e \
  --arg suite "$suite" \
  --arg environment "$target_environment" \
  --arg run_id "$run_id" \
  --arg runbook_sha256 "$runbook_sha256" \
  --arg artifact_root_id "$artifact_root_id" '
    .schema_version == "blueeconomy.evidence-manifest.v1" and
    .suite == $suite and
    .target_environment == $environment and
    .run_id == $run_id and
    .runbook_sha256 == $runbook_sha256 and
    .artifact_root_id == $artifact_root_id and
    (.files | type == "array" and length > 0 and all(.[];
      (.path | type == "string" and test("^[^/].*$") and (contains("..") | not)) and
      (.sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) and
      (.bytes | type == "number" and . >= 0)
    )) and
    ((.files | map(.path) | length) == (.files | map(.path) | unique | length))
  ' "$evidence_manifest" >/dev/null || usage_error 'evidence manifest is malformed or lacks bound file records'

workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT
actual_records="$workspace/actual.jsonl"
while IFS= read -r -d '' file; do
  relative=${file#"$artifact_dir/"}
  bytes=$(stat -c '%s' -- "$file")
  digest=$(sha256sum -- "$file" | awk '{print $1}')
  jq -cn --arg path "$relative" --arg sha256 "$digest" --argjson bytes "$bytes" \
    '{path:$path,sha256:$sha256,bytes:$bytes}' >> "$actual_records"
done < <(find -P "$artifact_dir" -type f \
  ! -name 'evidence-manifest.json' \
  ! -name 'integrity-attestation.json' \
  ! -name 'integrity.stdout.log' \
  ! -name 'integrity.stderr.log' \
  -print0 | sort -z)

jq -s -c 'sort_by(.path)' "$actual_records" > "$workspace/actual.json"
jq -c '.files | sort_by(.path)' "$evidence_manifest" > "$workspace/declared.json"
diff -u "$workspace/declared.json" "$workspace/actual.json" >/dev/null || usage_error 'evidence manifest file hashes or sizes do not match the retained bundle'

validate_integrity_attestation_file \
  "$suite" \
  "$target_environment" \
  "$runbook_sha256" \
  "$artifact_root_id" \
  "$evidence_manifest" \
  "$attestation"

jq -n \
  --arg schema_version 'blueeconomy.target-evidence-bundle-validation.v1' \
  --arg suite "$suite" \
  --arg target_environment "$target_environment" \
  --arg run_id "$run_id" \
  --arg runbook_sha256 "$runbook_sha256" \
  --arg artifact_root_id "$artifact_root_id" \
  --arg case_runner_sha256 "$case_runner_sha256" \
  --arg integrity_verifier_sha256 "$integrity_verifier_sha256" \
  --arg validated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{schema_version:$schema_version,suite:$suite,target_environment:$target_environment,run_id:$run_id,runbook_sha256:$runbook_sha256,artifact_root_id:$artifact_root_id,case_runner_sha256:$case_runner_sha256,integrity_verifier_sha256:$integrity_verifier_sha256,validated_at:$validated_at,status:"structurally-valid",target_contacted:false,kms_signature_cryptographically_verified:false}'
