#!/usr/bin/env bash
# Validates a completed, authorised maritime-feed target-test evidence bundle.
# It never contacts a target environment, executes a fault, or signs evidence.

set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/target_test_common.sh
source "$root/lib/target_test_common.sh"

readonly suite='maritime-feed-target'
readonly required_dr_cases=(
  feed_outage_recovery
  processing_interruption_recovery
  deployment_rollback
  post_rollback_contract_validation
  kubernetes_failure_domain_recovery
  postgresql_restore_to_rpo
  kafka_replay_reconciliation
  delta_reprocessing_lineage
  object_storage_access_recovery
  oidc_key_rotation_and_revocation
  observability_retention_continuity
)

usage() {
  cat <<'USAGE'
Usage: validate-maritime-feed-dr-evidence.sh --artifact-dir /absolute/path/to/run

The directory must be the approved evidence bundle created by
run-maritime-feed-target-tests.sh after an authorised target execution. This
validator verifies structural consistency, secure local modes, manifest binding,
and integrity-attestation metadata. It does not verify an HSM/KMS signature
itself and does not determine whether a Ministry owner has accepted the result.
USAGE
}

[[ $# -eq 2 && "$1" == '--artifact-dir' ]] || { usage >&2; exit 64; }
artifact_dir=$2
[[ "$artifact_dir" = /* ]] || usage_error 'artifact directory must be an absolute path'
assert_secure_directory "$artifact_dir"
require_command jq
require_command sha256sum
require_command stat

summary="$artifact_dir/summary.json"
manifest="$artifact_dir/manifest.json"
attestation="$artifact_dir/integrity-attestation.json"
assert_private_regular_file "$summary"
assert_private_regular_file "$manifest"
assert_private_regular_file "$attestation"
"$root/validate-target-evidence-bundle.sh" --artifact-dir "$artifact_dir" >/dev/null

manifest_values=$(jq -er --arg suite "$suite" '
  select(.schema_version == "blueeconomy.target-test-manifest.v3") |
  select(.suite == $suite) |
  select(.authorization_reference | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) |
  select(.runbook_reference | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) |
  select(.runbook_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) |
  select(.artifact_root_id | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) |
  select(.case_runner_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) |
  select(.integrity_verifier_sha256 | type == "string" and test("^[a-fA-F0-9]{64}$")) |
  select(.run_id | type == "string" and test("^[A-Za-z0-9._:-]{3,512}$")) |
  [.target_environment,.run_id,.runbook_sha256,.artifact_root_id,.case_runner_sha256,.integrity_verifier_sha256] | @tsv
' "$manifest") || usage_error 'manifest lacks approved v3 authorisation, runbook-digest, artifact-root, or runner-digest bindings'
IFS=$'\t' read -r target_environment run_id runbook_sha256 artifact_root_id case_runner_sha256 integrity_verifier_sha256 <<< "$manifest_values"
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
    .status == "passed"
  ' "$summary" >/dev/null || usage_error 'summary does not bind the approved manifest identity and digest values'
reject_sensitive_result_fields "$manifest"
reject_sensitive_result_fields "$summary"

for test_case in "${required_dr_cases[@]}"; do
  validate_case_result \
    "$artifact_dir/cases/$test_case/result.json" \
    "$test_case" \
    "$suite" \
    "$target_environment"
done

validate_integrity_attestation_file \
  "$suite" \
  "$target_environment" \
  "$runbook_sha256" \
  "$artifact_root_id" \
  "$artifact_dir/evidence-manifest.json" \
  "$attestation"

jq -n \
  --arg schema_version 'blueeconomy.maritime-dr-evidence-validation.v3' \
  --arg suite "$suite" \
  --arg target_environment "$target_environment" \
  --arg run_id "$run_id" \
  --arg runbook_sha256 "$runbook_sha256" \
  --arg artifact_root_id "$artifact_root_id" \
  --arg case_runner_sha256 "$case_runner_sha256" \
  --arg integrity_verifier_sha256 "$integrity_verifier_sha256" \
  --arg validated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{schema_version:$schema_version,suite:$suite,target_environment:$target_environment,run_id:$run_id,runbook_sha256:$runbook_sha256,artifact_root_id:$artifact_root_id,case_runner_sha256:$case_runner_sha256,integrity_verifier_sha256:$integrity_verifier_sha256,validated_at:$validated_at,status:"complete",validated_cases:$ARGS.positional}' \
  --args "${required_dr_cases[@]}"
