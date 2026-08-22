#!/usr/bin/env bash
# Readiness-only preflight for Ministry-authorised target acceptance suites.
# It never contacts a target, reads secret values, invokes a runner, or creates evidence.

set -euo pipefail
umask 027

usage() {
  cat <<'USAGE'
Usage:
  validate-target-acceptance-readiness.sh [--suite maritime-feed|regulated-payment|all] [--format text|json] [--require-ready]

The preflight records only control names and validation states. It never prints
credentials, endpoints, runbook content, artifact content, or environment-variable values.
It does not set *_TARGET_TEST_ENABLED, invoke either acceptance wrapper, or contact a target.

--require-ready exits non-zero unless every selected suite is ready. Without it,
the command exits zero so it may be used to report blocked conditions safely in CI.
USAGE
}

suite=all
format=text
require_ready=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      suite=$2
      shift 2
      ;;
    --format)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      format=$2
      shift 2
      ;;
    --require-ready)
      require_ready=true
      shift
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

case "$suite" in maritime-feed|regulated-payment|all) ;; *) usage >&2; exit 64 ;; esac
case "$format" in text|json) ;; *) usage >&2; exit 64 ;; esac
command -v jq >/dev/null 2>&1 || { echo 'target-readiness: jq is required' >&2; exit 69; }
command -v realpath >/dev/null 2>&1 || { echo 'target-readiness: realpath is required' >&2; exit 69; }
command -v sha256sum >/dev/null 2>&1 || { echo 'target-readiness: sha256sum is required' >&2; exit 69; }
command -v stat >/dev/null 2>&1 || { echo 'target-readiness: stat is required' >&2; exit 69; }

is_safe_reference() {
  [[ "$1" =~ ^[A-Za-z0-9._:/@+=-]{3,512}$ ]]
}

is_sha256() {
  [[ "$1" =~ ^[a-fA-F0-9]{64}$ ]]
}

is_private_regular_file() {
  local path=$1
  local mode canonical
  [[ "$path" = /* && -f "$path" && -x "$path" && ! -L "$path" ]] || return 1
  canonical=$(realpath -e -- "$path") || return 1
  [[ "$canonical" == "$path" ]] || return 1
  mode=$(stat -c '%a' -- "$path") || return 1
  (( (8#$mode & 0022) == 0 ))
}

is_secure_directory() {
  local path=$1
  local mode canonical
  [[ "$path" = /* && -d "$path" && ! -L "$path" ]] || return 1
  canonical=$(realpath -e -- "$path") || return 1
  [[ "$canonical" == "$path" ]] || return 1
  mode=$(stat -c '%a' -- "$path") || return 1
  (( (8#$mode & 0002) == 0 ))
}

add_control() {
  local name=$1 ok=$2 reason=$3
  jq -cn --arg name "$name" --arg reason "$reason" --argjson ready "$ok" \
    '{name:$name,ready:$ready,reason:$reason}' >> "$controls_file"
}

check_text() {
  local name=$1 value=${!1:-}
  if [[ -z "${value//[[:space:]]/}" ]]; then
    add_control "$name" false 'missing'
  elif ! is_safe_reference "$value"; then
    add_control "$name" false 'invalid-reference-format'
  else
    add_control "$name" true 'present-and-valid'
  fi
}

check_enabled() {
  local name=$1 value=${!1:-}
  if [[ "$value" == true ]]; then
    add_control "$name" true 'explicitly-enabled'
  elif [[ -z "$value" ]]; then
    add_control "$name" false 'missing'
  else
    add_control "$name" false 'must-equal-true'
  fi
}

check_sha() {
  local name=$1 value=${!1:-}
  if [[ -z "$value" ]]; then
    add_control "$name" false 'missing'
  elif is_sha256 "$value"; then
    add_control "$name" true 'present-and-valid'
  else
    add_control "$name" false 'must-be-64-character-sha256'
  fi
}

check_runner() {
  local name=$1 digest_name=$2 path=${!1:-} expected=${!2:-} actual
  if [[ -z "$path" ]]; then
    add_control "$name" false 'missing'
  elif is_private_regular_file "$path"; then
    add_control "$name" true 'approved-path-shape'
  else
    add_control "$name" false 'must-be-absolute-private-nonsymlink-executable-regular-file'
  fi
  if [[ -z "$expected" ]]; then
    add_control "$digest_name" false 'missing'
  elif ! is_sha256 "$expected"; then
    add_control "$digest_name" false 'must-be-64-character-sha256'
  elif ! is_private_regular_file "$path"; then
    add_control "$digest_name" false 'runner-unavailable-for-digest-check'
  else
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ "${actual,,}" == "${expected,,}" ]]; then
      add_control "$digest_name" true 'matches-approved-runner-bytes'
    else
      add_control "$digest_name" false 'does-not-match-runner-bytes'
    fi
  fi
}

check_artifact_root() {
  local name=$1 path=${!1:-}
  if [[ -z "$path" ]]; then
    add_control "$name" false 'missing'
  elif is_secure_directory "$path"; then
    add_control "$name" true 'approved-path-shape'
  else
    add_control "$name" false 'must-be-absolute-canonical-nonsymlink-non-world-writable-directory'
  fi
}

check_suite() {
  local display=$1 prefix=$2 suite_id=$3
  controls_file=$(mktemp)
  trap 'rm -f "$controls_file"' RETURN

  check_enabled "${prefix}_TARGET_TEST_ENABLED"
  check_text "${prefix}_TARGET_AUTHORIZATION_REF"
  check_text "${prefix}_TARGET_ENVIRONMENT"
  check_text "${prefix}_TARGET_RUNBOOK_REF"
  check_sha "${prefix}_TARGET_RUNBOOK_SHA256"
  check_runner "${prefix}_TARGET_CASE_RUNNER" "${prefix}_TARGET_CASE_RUNNER_SHA256"
  check_artifact_root "${prefix}_TARGET_ARTIFACT_ROOT"
  check_text "${prefix}_TARGET_ARTIFACT_ROOT_ID"
  check_runner "${prefix}_TARGET_INTEGRITY_VERIFIER" "${prefix}_TARGET_INTEGRITY_VERIFIER_SHA256"

  jq -s --arg suite "$suite_id" --arg display_name "$display" \
    '{suite:$suite,display_name:$display_name,ready:(all(.[]; .ready)),controls:.}' "$controls_file"
  rm -f "$controls_file"
  trap - RETURN
}

results_file=$(mktemp)
trap 'rm -f "$results_file"' EXIT
if [[ "$suite" == maritime-feed || "$suite" == all ]]; then
  check_suite 'Maritime-feed S2 target acceptance' MARITIME maritime-feed-target >> "$results_file"
fi
if [[ "$suite" == regulated-payment || "$suite" == all ]]; then
  check_suite 'Regulated-payment S3 target acceptance' PAYMENT regulated-payment-target >> "$results_file"
fi

summary=$(jq -s --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{schema_version:"blueeconomy.target-acceptance-readiness.v1",generated_at:$generated_at,target_contacted:false,target_mutated:false,secret_values_read:false,suites:.,all_ready:(all(.[]; .ready))}' \
  "$results_file")

if [[ "$format" == json ]]; then
  printf '%s\n' "$summary"
else
  printf '%s\n' 'Target acceptance readiness (non-invasive)'
  jq -r '.suites[] | "\(.display_name): \(if .ready then "READY" else "BLOCKED" end)" , (.controls[] | "  - \(.name): \(if .ready then "ready" else "blocked" end) [\(.reason)]")' <<< "$summary"
  printf '%s\n' 'No target, runner, credential, integrity-verifier or endpoint was invoked.'
fi

if [[ "$require_ready" == true ]] && ! jq -e '.all_ready' >/dev/null <<< "$summary"; then
  exit 1
fi
