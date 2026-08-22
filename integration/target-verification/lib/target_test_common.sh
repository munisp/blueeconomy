#!/usr/bin/env bash
# Shared fail-closed controls for Ministry-authorised target integration tests.
# This library contains no endpoint, credential, signing key, or fault-command default.

set -euo pipefail
umask 027

readonly TARGET_TEST_SCHEMA_VERSION='blueeconomy.target-test-result.v1'
readonly TARGET_INTEGRITY_SCHEMA_VERSION='blueeconomy.evidence-integrity.v1'

usage_error() {
  printf 'target-verification: %s\n' "$*" >&2
  exit 64
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || usage_error "required command is unavailable: $1"
}

require_text() {
  local name=$1
  local value=${!name:-}
  [[ -n "${value//[[:space:]]/}" ]] || usage_error "$name must be supplied"
}

require_safe_reference() {
  local name=$1
  local value=${!name:-}
  require_text "$name"
  [[ "$value" =~ ^[A-Za-z0-9._:/@+=-]{3,512}$ ]] || usage_error "$name contains unsupported characters"
}

require_sha256() {
  local name=$1
  local value=${!name:-}
  require_text "$name"
  [[ "$value" =~ ^[a-fA-F0-9]{64}$ ]] || usage_error "$name must be a 64-character SHA-256 hexadecimal digest"
}

require_approved_runner() {
  local name=$1
  local runner=${!name:-}
  require_text "$name"
  [[ "$runner" = /* ]] || usage_error "$name must be an absolute path"
  [[ -f "$runner" && -x "$runner" && ! -L "$runner" ]] || usage_error "$name must identify an executable regular file"
  [[ "$(realpath -e -- "$runner")" == "$runner" ]] || usage_error "$name must be a canonical non-symlink path"
  assert_private_regular_file "$runner"
}

require_approved_runner_digest() {
  local runner_name=$1
  local digest_name=$2
  local runner expected actual

  require_approved_runner "$runner_name"
  require_sha256 "$digest_name"
  runner=${!runner_name}
  expected=${!digest_name}
  actual=$(sha256sum -- "$runner" | awk '{print $1}')
  [[ "${actual,,}" == "${expected,,}" ]] || usage_error "$digest_name does not match the approved bytes at $runner_name"
}

assert_private_regular_file() {
  local path=$1
  [[ -f "$path" && ! -L "$path" ]] || usage_error "required file is not a regular non-symlink: $path"
  local mode
  mode=$(stat -c '%a' -- "$path")
  if (( (8#$mode & 0022) != 0 )); then
    usage_error "file must not be group- or world-writable: $path"
  fi
}

assert_secure_directory() {
  local path=$1
  [[ -d "$path" && ! -L "$path" ]] || usage_error "required directory is not a regular non-symlink: $path"
  local mode
  mode=$(stat -c '%a' -- "$path")
  if (( (8#$mode & 0002) != 0 )); then
    usage_error "directory must not be world-writable: $path"
  fi
}

require_secure_artifact_root() {
  local name=$1
  local root=${!name:-}
  require_text "$name"
  [[ "$root" = /* ]] || usage_error "$name must be an absolute path"
  assert_secure_directory "$root"
  realpath -e -- "$root" >/dev/null || usage_error "$name cannot be canonicalized"
}

require_execute_authorization() {
  local enabled_name=$1
  local authorization_name=$2
  local environment_name=$3
  local runbook_name=$4
  local enabled=${!enabled_name:-}

  [[ "$enabled" == 'true' ]] || usage_error "$enabled_name=true is required for execution"
  require_safe_reference "$authorization_name"
  require_safe_reference "$environment_name"
  require_safe_reference "$runbook_name"
}

require_integrity_inputs() {
  local runbook_digest_name=$1
  local artifact_root_id_name=$2
  local integrity_runner_name=$3
  local integrity_runner_digest_name=$4

  require_sha256 "$runbook_digest_name"
  require_safe_reference "$artifact_root_id_name"
  require_approved_runner_digest "$integrity_runner_name" "$integrity_runner_digest_name"
}

create_artifact_directory() {
  local artifact_root=$1
  local suite_name=$2
  local environment=$3
  local run_id canonical_root

  assert_secure_directory "$artifact_root"
  canonical_root=$(realpath -e -- "$artifact_root")
  run_id="${suite_name}-$(date -u +%Y%m%dT%H%M%SZ)-$$"
  TARGET_TEST_RUN_ID=$run_id
  TARGET_TEST_ARTIFACT_DIR="$canonical_root/$environment/$run_id"
  mkdir -p "$TARGET_TEST_ARTIFACT_DIR"
  chmod 0750 "$TARGET_TEST_ARTIFACT_DIR"
  assert_secure_directory "$TARGET_TEST_ARTIFACT_DIR"
  export TARGET_TEST_RUN_ID TARGET_TEST_ARTIFACT_DIR
}

write_manifest() {
  local suite_name=$1
  local target_environment=$2
  local authorization_ref=$3
  local runbook_ref=$4
  local runbook_sha256=$5
  local artifact_root_id=$6
  local case_runner_sha256=$7
  local integrity_verifier_sha256=$8
  shift 8

  jq -n \
    --arg schema_version 'blueeconomy.target-test-manifest.v3' \
    --arg suite "$suite_name" \
    --arg target_environment "$target_environment" \
    --arg authorization_reference "$authorization_ref" \
    --arg runbook_reference "$runbook_ref" \
    --arg runbook_sha256 "$runbook_sha256" \
    --arg artifact_root_id "$artifact_root_id" \
    --arg case_runner_sha256 "$case_runner_sha256" \
    --arg integrity_verifier_sha256 "$integrity_verifier_sha256" \
    --arg run_id "$TARGET_TEST_RUN_ID" \
    --arg started_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$schema_version,suite:$suite,target_environment:$target_environment,authorization_reference:$authorization_reference,runbook_reference:$runbook_reference,runbook_sha256:$runbook_sha256,artifact_root_id:$artifact_root_id,case_runner_sha256:$case_runner_sha256,integrity_verifier_sha256:$integrity_verifier_sha256,run_id:$run_id,started_at:$started_at,planned_cases:$ARGS.positional}' \
    --args "$@" \
    > "$TARGET_TEST_ARTIFACT_DIR/manifest.json"
  chmod 0640 "$TARGET_TEST_ARTIFACT_DIR/manifest.json"
  assert_private_regular_file "$TARGET_TEST_ARTIFACT_DIR/manifest.json"
}

reject_sensitive_result_fields() {
  local result=$1
  jq -e '
    [paths(scalars) as $p | ($p | map(tostring) | join(".") | ascii_downcase)]
    | all(test("(password|secret|access_token|refresh_token|private_key)") | not)
  ' "$result" >/dev/null || usage_error "result evidence contains a prohibited sensitive field name"
}

validate_case_result() {
  local result=$1
  local expected_case=$2
  local expected_suite=$3
  local expected_environment=$4

  assert_private_regular_file "$result"
  jq -e \
    --arg schema "$TARGET_TEST_SCHEMA_VERSION" \
    --arg case "$expected_case" \
    --arg suite "$expected_suite" \
    --arg environment "$expected_environment" '
      .schema_version == $schema and
      .suite == $suite and
      .case == $case and
      .target_environment == $environment and
      .status == "passed" and
      (.executed_at | type == "string" and length > 0) and
      (.evidence_references | type == "array" and length > 0 and all(.[]; type == "string" and length > 0)) and
      (.observed_outcome | type == "string" and length > 0) and
      (.expected_safe_outcome | type == "string" and length > 0)
    ' "$result" >/dev/null || usage_error "case result is incomplete or not passed: $expected_case"
  reject_sensitive_result_fields "$result"
}

run_approved_case() {
  local suite_name=$1
  local target_environment=$2
  local runner=$3
  local case_name=$4
  local case_dir="$TARGET_TEST_ARTIFACT_DIR/cases/$case_name"
  local status

  mkdir -p "$case_dir"
  chmod 0750 "$case_dir"
  printf 'case=%s started_at=%s\n' "$case_name" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$case_dir/invocation.txt"
  chmod 0640 "$case_dir/invocation.txt"

  set +e
  TARGET_TEST_SUITE="$suite_name" \
  TARGET_TEST_CASE="$case_name" \
  TARGET_TEST_CASE_DIR="$case_dir" \
  TARGET_TEST_RUN_ID="$TARGET_TEST_RUN_ID" \
  "$runner" "$case_name" "$TARGET_TEST_RUN_ID" >"$case_dir/stdout.log" 2>"$case_dir/stderr.log"
  status=$?
  set -e

  chmod 0640 "$case_dir/stdout.log" "$case_dir/stderr.log"
  assert_private_regular_file "$case_dir/stdout.log"
  assert_private_regular_file "$case_dir/stderr.log"
  [[ $status -eq 0 ]] || usage_error "approved runner failed for case $case_name; inspect $case_dir/stderr.log"
  validate_case_result "$case_dir/result.json" "$case_name" "$suite_name" "$target_environment"
  printf 'case=%s completed_at=%s status=passed\n' "$case_name" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$case_dir/invocation.txt"
}

write_evidence_manifest() {
  local suite_name=$1
  local target_environment=$2
  local runbook_sha256=$3
  local artifact_root_id=$4
  local records="$TARGET_TEST_ARTIFACT_DIR/.evidence-records.jsonl"
  local relative file bytes digest

  : > "$records"
  while IFS= read -r -d '' file; do
    relative=${file#"$TARGET_TEST_ARTIFACT_DIR/"}
    bytes=$(stat -c '%s' -- "$file")
    digest=$(sha256sum -- "$file" | awk '{print $1}')
    jq -n --arg path "$relative" --arg sha256 "$digest" --argjson bytes "$bytes" \
      '{path:$path,sha256:$sha256,bytes:$bytes}' >> "$records"
  done < <(find -P "$TARGET_TEST_ARTIFACT_DIR" -type f ! -name 'evidence-manifest.json' ! -name 'integrity-attestation.json' ! -name '.evidence-records.jsonl' -print0 | sort -z)

  jq -s \
    --arg schema_version 'blueeconomy.evidence-manifest.v1' \
    --arg suite "$suite_name" \
    --arg target_environment "$target_environment" \
    --arg run_id "$TARGET_TEST_RUN_ID" \
    --arg runbook_sha256 "$runbook_sha256" \
    --arg artifact_root_id "$artifact_root_id" \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$schema_version,suite:$suite,target_environment:$target_environment,run_id:$run_id,runbook_sha256:$runbook_sha256,artifact_root_id:$artifact_root_id,created_at:$created_at,files:.}' \
    "$records" > "$TARGET_TEST_ARTIFACT_DIR/evidence-manifest.json"
  rm -f "$records"
  chmod 0640 "$TARGET_TEST_ARTIFACT_DIR/evidence-manifest.json"
  assert_private_regular_file "$TARGET_TEST_ARTIFACT_DIR/evidence-manifest.json"
}

validate_integrity_attestation_file() {
  local suite_name=$1
  local target_environment=$2
  local runbook_sha256=$3
  local artifact_root_id=$4
  local manifest=$5
  local attestation=$6
  local manifest_sha256

  assert_private_regular_file "$manifest"
  assert_private_regular_file "$attestation"
  manifest_sha256=$(sha256sum -- "$manifest" | awk '{print $1}')
  jq -e \
    --arg schema "$TARGET_INTEGRITY_SCHEMA_VERSION" \
    --arg suite "$suite_name" \
    --arg environment "$target_environment" \
    --arg run_id "$TARGET_TEST_RUN_ID" \
    --arg runbook_sha256 "$runbook_sha256" \
    --arg artifact_root_id "$artifact_root_id" \
    --arg manifest_sha256 "$manifest_sha256" '
      .schema_version == $schema and
      .suite == $suite and
      .target_environment == $environment and
      .run_id == $run_id and
      .runbook_sha256 == $runbook_sha256 and
      .artifact_root_id == $artifact_root_id and
      .evidence_manifest_sha256 == $manifest_sha256 and
      .status == "verified" and
      (.signature_reference | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) and
      (.signer_key_id | type == "string" and test("^[A-Za-z0-9._:/@+=-]{3,512}$")) and
      (.verified_at | type == "string" and length > 0)
    ' "$attestation" >/dev/null || usage_error "integrity attestation is incomplete or does not bind the approved evidence manifest"
  reject_sensitive_result_fields "$attestation"
}

verify_integrity_attestation() {
  local suite_name=$1
  local target_environment=$2
  local runbook_sha256=$3
  local artifact_root_id=$4
  local integrity_runner=$5
  local manifest="$TARGET_TEST_ARTIFACT_DIR/evidence-manifest.json"
  local attestation="$TARGET_TEST_ARTIFACT_DIR/integrity-attestation.json"
  local status
  set +e
  TARGET_TEST_EVIDENCE_MANIFEST="$manifest" \
  TARGET_TEST_INTEGRITY_ATTESTATION="$attestation" \
  TARGET_TEST_SUITE="$suite_name" \
  TARGET_TEST_TARGET_ENVIRONMENT="$target_environment" \
  TARGET_TEST_RUN_ID="$TARGET_TEST_RUN_ID" \
  TARGET_TEST_RUNBOOK_SHA256="$runbook_sha256" \
  TARGET_TEST_ARTIFACT_ROOT_ID="$artifact_root_id" \
  "$integrity_runner" "$TARGET_TEST_ARTIFACT_DIR" "$TARGET_TEST_RUN_ID" >"$TARGET_TEST_ARTIFACT_DIR/integrity.stdout.log" 2>"$TARGET_TEST_ARTIFACT_DIR/integrity.stderr.log"
  status=$?
  set -e
  chmod 0640 "$TARGET_TEST_ARTIFACT_DIR/integrity.stdout.log" "$TARGET_TEST_ARTIFACT_DIR/integrity.stderr.log"
  [[ $status -eq 0 ]] || usage_error "integrity verifier failed; inspect $TARGET_TEST_ARTIFACT_DIR/integrity.stderr.log"
  validate_integrity_attestation_file \
    "$suite_name" \
    "$target_environment" \
    "$runbook_sha256" \
    "$artifact_root_id" \
    "$manifest" \
    "$attestation"
}

print_dry_run() {
  local suite_name=$1
  shift
  printf 'DRY RUN: %s would execute %d approved target cases:\n' "$suite_name" "$#"
  printf '  - %s\n' "$@"
  printf '%s\n' 'No network request, fault injection, credential use, integrity signing, or target mutation was performed.'
}
