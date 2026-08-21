#!/usr/bin/env bash
# Executes only owner-approved S3 target scenarios through a Ministry/institution runner.
# This wrapper never provides a payment endpoint, participant credential, or fault command.

set -euo pipefail

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/target_test_common.sh
source "$root/lib/target_test_common.sh"

readonly suite='regulated-payment-target'
readonly cases=(
  participant_identity_denial
  invalid_instruction_rejection
  duplicate_instruction_idempotency
  timeout_unknown_outcome
  provider_rejection
  reserve_commit_reverse
  ledger_payment_mismatch
  maker_checker_limit_denial
  reconciliation_input_fault
  payment_rail_outage_recovery
  tigerbeetle_quorum_recovery
  database_temporal_restore
  audit_statement_export
)

usage() {
  cat <<'USAGE'
Usage:
  run-regulated-payment-target-tests.sh --dry-run
  run-regulated-payment-target-tests.sh --execute

Execution requires all of the following environment variables:
  PAYMENT_TARGET_TEST_ENABLED=true
  PAYMENT_TARGET_AUTHORIZATION_REF=<approved-change-reference>
  PAYMENT_TARGET_ENVIRONMENT=<approved-ministry-nonproduction-environment>
  PAYMENT_TARGET_RUNBOOK_REF=<approved-finance-and-DR-runbook-reference>
  PAYMENT_TARGET_RUNBOOK_SHA256=<64-character-approved-runbook-digest>
  PAYMENT_TARGET_CASE_RUNNER=/absolute/path/to/approved-case-runner
  PAYMENT_TARGET_ARTIFACT_ROOT=/absolute/path/to/approved-artifact-directory
  PAYMENT_TARGET_ARTIFACT_ROOT_ID=<approved-evidence-store-reference>
  PAYMENT_TARGET_INTEGRITY_VERIFIER=/absolute/path/to/approved-KMS-HSM-integrity-verifier

The approved case runner receives: <case-name> <run-id>.
It must create $TARGET_TEST_CASE_DIR/result.json using schema
blueeconomy.target-test-result.v1. The approved integrity verifier receives the completed
artifact directory and must create a KMS/HSM-backed integrity attestation. Neither runner
may emit credentials, raw payment data, or unredacted account/customer information.

The wrapper is not a payment switch and must not be used for live-money testing.
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
  PAYMENT_TARGET_TEST_ENABLED \
  PAYMENT_TARGET_AUTHORIZATION_REF \
  PAYMENT_TARGET_ENVIRONMENT \
  PAYMENT_TARGET_RUNBOOK_REF
require_approved_runner PAYMENT_TARGET_CASE_RUNNER
require_secure_artifact_root PAYMENT_TARGET_ARTIFACT_ROOT
require_integrity_inputs \
  PAYMENT_TARGET_RUNBOOK_SHA256 \
  PAYMENT_TARGET_ARTIFACT_ROOT_ID \
  PAYMENT_TARGET_INTEGRITY_VERIFIER

create_artifact_directory \
  "$PAYMENT_TARGET_ARTIFACT_ROOT" \
  "$suite" \
  "$PAYMENT_TARGET_ENVIRONMENT"
write_manifest \
  "$suite" \
  "$PAYMENT_TARGET_ENVIRONMENT" \
  "$PAYMENT_TARGET_AUTHORIZATION_REF" \
  "$PAYMENT_TARGET_RUNBOOK_REF" \
  "$PAYMENT_TARGET_RUNBOOK_SHA256" \
  "$PAYMENT_TARGET_ARTIFACT_ROOT_ID" \
  "${cases[@]}"

for test_case in "${cases[@]}"; do
  run_approved_case \
    "$suite" \
    "$PAYMENT_TARGET_ENVIRONMENT" \
    "$PAYMENT_TARGET_CASE_RUNNER" \
    "$test_case"
done

jq -n \
  --arg schema_version 'blueeconomy.target-test-summary.v2' \
  --arg suite "$suite" \
  --arg target_environment "$PAYMENT_TARGET_ENVIRONMENT" \
  --arg authorization_reference "$PAYMENT_TARGET_AUTHORIZATION_REF" \
  --arg runbook_sha256 "$PAYMENT_TARGET_RUNBOOK_SHA256" \
  --arg artifact_root_id "$PAYMENT_TARGET_ARTIFACT_ROOT_ID" \
  --arg run_id "$TARGET_TEST_RUN_ID" \
  --arg completed_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{schema_version:$schema_version,suite:$suite,target_environment:$target_environment,authorization_reference:$authorization_reference,runbook_sha256:$runbook_sha256,artifact_root_id:$artifact_root_id,run_id:$run_id,completed_at:$completed_at,status:"passed",completed_cases:$ARGS.positional}' \
  --args "${cases[@]}" \
  > "$TARGET_TEST_ARTIFACT_DIR/summary.json"
chmod 0640 "$TARGET_TEST_ARTIFACT_DIR/summary.json"
write_evidence_manifest \
  "$suite" \
  "$PAYMENT_TARGET_ENVIRONMENT" \
  "$PAYMENT_TARGET_RUNBOOK_SHA256" \
  "$PAYMENT_TARGET_ARTIFACT_ROOT_ID"
verify_integrity_attestation \
  "$suite" \
  "$PAYMENT_TARGET_ENVIRONMENT" \
  "$PAYMENT_TARGET_RUNBOOK_SHA256" \
  "$PAYMENT_TARGET_ARTIFACT_ROOT_ID" \
  "$PAYMENT_TARGET_INTEGRITY_VERIFIER"
printf 'Regulated-payment target verification completed with verified evidence integrity: %s\n' "$TARGET_TEST_ARTIFACT_DIR"
