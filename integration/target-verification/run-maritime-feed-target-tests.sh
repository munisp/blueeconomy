#!/usr/bin/env bash
# Executes only owner-approved S2 target scenarios through a Ministry-supplied runner.
# It has no feed endpoint, signing key, credential, payload, or fault command default.

set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/target_test_common.sh
source "$root/lib/target_test_common.sh"

readonly suite='maritime-feed-target'
readonly cases=(
  authentication_denial
  source_revocation_denial
  invalid_signature_rejection
  malformed_contract_rejection
  exact_replay_idempotency
  conflicting_replay_rejection
  late_event_policy
  out_of_order_event_policy
  feed_outage_recovery
  processing_interruption_recovery
  geofence_boundary_validation
  false_positive_disposition
  classification_denial
  analyst_recovery_handoff
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
Usage:
  run-maritime-feed-target-tests.sh --dry-run
  run-maritime-feed-target-tests.sh --execute

Execution requires all of the following environment variables:
  MARITIME_TARGET_TEST_ENABLED=true
  MARITIME_TARGET_AUTHORIZATION_REF=<approved-change-reference>
  MARITIME_TARGET_ENVIRONMENT=<approved-ministry-nonproduction-environment>
  MARITIME_TARGET_RUNBOOK_REF=<approved-runbook-reference>
  MARITIME_TARGET_RUNBOOK_SHA256=<64-character-approved-runbook-digest>
  MARITIME_TARGET_CASE_RUNNER=/absolute/path/to/approved-case-runner
  MARITIME_TARGET_CASE_RUNNER_SHA256=<64-character-approved-case-runner-digest>
  MARITIME_TARGET_ARTIFACT_ROOT=/absolute/path/to/approved-artifact-directory
  MARITIME_TARGET_ARTIFACT_ROOT_ID=<approved-evidence-store-reference>
  MARITIME_TARGET_INTEGRITY_VERIFIER=/absolute/path/to/approved-KMS-HSM-integrity-verifier
  MARITIME_TARGET_INTEGRITY_VERIFIER_SHA256=<64-character-approved-integrity-verifier-digest>

The approved case runner receives: <case-name> <run-id>.
It must create $TARGET_TEST_CASE_DIR/result.json using schema
blueeconomy.target-test-result.v1. The approved integrity verifier receives the completed
artifact directory and must create a KMS/HSM-backed integrity attestation. No credential
or raw payload belongs in a result, manifest, log, or attestation.
USAGE
}

[[ $# -eq 1 ]] || { usage >&2; exit 64; }
case "$1" in
  --dry-run)
    print_dry_run "$suite" "${cases[@]}"
    exit 0
    ;;
  --execute)
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

for command in jq date sha256sum stat realpath find sort awk; do require_command "$command"; done
require_execute_authorization \
  MARITIME_TARGET_TEST_ENABLED \
  MARITIME_TARGET_AUTHORIZATION_REF \
  MARITIME_TARGET_ENVIRONMENT \
  MARITIME_TARGET_RUNBOOK_REF
require_approved_runner_digest \
  MARITIME_TARGET_CASE_RUNNER \
  MARITIME_TARGET_CASE_RUNNER_SHA256
require_secure_artifact_root MARITIME_TARGET_ARTIFACT_ROOT
require_integrity_inputs \
  MARITIME_TARGET_RUNBOOK_SHA256 \
  MARITIME_TARGET_ARTIFACT_ROOT_ID \
  MARITIME_TARGET_INTEGRITY_VERIFIER \
  MARITIME_TARGET_INTEGRITY_VERIFIER_SHA256

create_artifact_directory \
  "$MARITIME_TARGET_ARTIFACT_ROOT" \
  "$suite" \
  "$MARITIME_TARGET_ENVIRONMENT"
write_manifest \
  "$suite" \
  "$MARITIME_TARGET_ENVIRONMENT" \
  "$MARITIME_TARGET_AUTHORIZATION_REF" \
  "$MARITIME_TARGET_RUNBOOK_REF" \
  "$MARITIME_TARGET_RUNBOOK_SHA256" \
  "$MARITIME_TARGET_ARTIFACT_ROOT_ID" \
  "$MARITIME_TARGET_CASE_RUNNER_SHA256" \
  "$MARITIME_TARGET_INTEGRITY_VERIFIER_SHA256" \
  "${cases[@]}"

for test_case in "${cases[@]}"; do
  run_approved_case \
    "$suite" \
    "$MARITIME_TARGET_ENVIRONMENT" \
    "$MARITIME_TARGET_CASE_RUNNER" \
    "$test_case"
done

jq -n \
  --arg schema_version 'blueeconomy.target-test-summary.v3' \
  --arg suite "$suite" \
  --arg target_environment "$MARITIME_TARGET_ENVIRONMENT" \
  --arg authorization_reference "$MARITIME_TARGET_AUTHORIZATION_REF" \
  --arg runbook_sha256 "$MARITIME_TARGET_RUNBOOK_SHA256" \
  --arg artifact_root_id "$MARITIME_TARGET_ARTIFACT_ROOT_ID" \
  --arg case_runner_sha256 "$MARITIME_TARGET_CASE_RUNNER_SHA256" \
  --arg integrity_verifier_sha256 "$MARITIME_TARGET_INTEGRITY_VERIFIER_SHA256" \
  --arg run_id "$TARGET_TEST_RUN_ID" \
  --arg completed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{schema_version:$schema_version,suite:$suite,target_environment:$target_environment,authorization_reference:$authorization_reference,runbook_sha256:$runbook_sha256,artifact_root_id:$artifact_root_id,case_runner_sha256:$case_runner_sha256,integrity_verifier_sha256:$integrity_verifier_sha256,run_id:$run_id,completed_at:$completed_at,status:"passed",completed_cases:$ARGS.positional}' \
  --args "${cases[@]}" \
  > "$TARGET_TEST_ARTIFACT_DIR/summary.json"
chmod 0640 "$TARGET_TEST_ARTIFACT_DIR/summary.json"
write_evidence_manifest \
  "$suite" \
  "$MARITIME_TARGET_ENVIRONMENT" \
  "$MARITIME_TARGET_RUNBOOK_SHA256" \
  "$MARITIME_TARGET_ARTIFACT_ROOT_ID"
verify_integrity_attestation \
  "$suite" \
  "$MARITIME_TARGET_ENVIRONMENT" \
  "$MARITIME_TARGET_RUNBOOK_SHA256" \
  "$MARITIME_TARGET_ARTIFACT_ROOT_ID" \
  "$MARITIME_TARGET_INTEGRITY_VERIFIER"
printf 'Maritime-feed target verification completed with verified evidence integrity: %s\n' "$TARGET_TEST_ARTIFACT_DIR"
