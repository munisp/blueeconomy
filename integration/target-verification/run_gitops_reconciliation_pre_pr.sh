#!/usr/bin/env bash
# Run offline immutable GitOps candidate reconciliation before opening a pull request.
# This script never contacts a cluster, Git provider API, PKI endpoint, KMS/HSM,
# target, secret store, APISIX, Keycloak or deployment controller.

set -euo pipefail
umask 027

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
checker="$root/reconcile_gitops_deployment_identity.py"
test_script="$root/test_reconcile_gitops_deployment_identity.py"

usage() {
  cat <<'USAGE'
Usage:
  run_gitops_reconciliation_pre_pr.sh \
    --attestation /absolute/path/to/candidate-or-approved-attestation.json \
    --deployment-evidence /absolute/path/to/ministry-controlled-offline-export.json \
    --mode candidate|approved \
    --output-dir /absolute/path/to/local-evidence

  run_gitops_reconciliation_pre_pr.sh --self-test

The deployment-evidence input must be an approved, non-secret offline export from
the Ministry GitOps evidence adapter. This script validates local syntax and invokes
only the repository reconciliation checker. It never deploys or queries a target.

Exit status:
  0  Candidate/export identities match; this is not Ministry approval.
  1  Immutable candidate drift was detected; block the pull request/promotion.
  64 Invalid arguments or unsafe/malformed local input.
USAGE
}

attestation=''
deployment_evidence=''
mode=''
output_dir=''
self_test=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --attestation)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      attestation=$2
      shift 2
      ;;
    --deployment-evidence)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      deployment_evidence=$2
      shift 2
      ;;
    --mode)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      mode=$2
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || { usage >&2; exit 64; }
      output_dir=$2
      shift 2
      ;;
    --self-test)
      self_test=true
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

command -v python3 >/dev/null 2>&1 || { echo 'python3 is required' >&2; exit 64; }
command -v jq >/dev/null 2>&1 || { echo 'jq is required' >&2; exit 64; }
python3 -m py_compile "$checker" "$test_script"

if [[ "$self_test" == true ]]; then
  [[ -z "$attestation$deployment_evidence$mode$output_dir" ]] || { usage >&2; exit 64; }
  exec python3 "$test_script"
fi

[[ -n "$attestation" && -n "$deployment_evidence" && -n "$mode" && -n "$output_dir" ]] || { usage >&2; exit 64; }
case "$mode" in candidate|approved) ;; *) usage >&2; exit 64 ;; esac
[[ "$output_dir" = /* ]] || { echo 'output directory must be absolute' >&2; exit 64; }

mkdir -p "$output_dir"
[[ ! -L "$output_dir" ]] || { echo 'output directory must not be a symlink' >&2; exit 64; }
chmod 0750 "$output_dir"
run_id="pre-pr-$(date -u +%Y%m%dT%H%M%SZ)"
stdout="$output_dir/${run_id}.stdout.json"
stderr="$output_dir/${run_id}.stderr.log"
invocation="$output_dir/${run_id}.invocation.log"
telemetry="$output_dir/${run_id}.telemetry.prom"
alert="$output_dir/${run_id}.alert.json"

set +e
python3 "$checker" \
  --attestation "$attestation" \
  --deployment-evidence "$deployment_evidence" \
  --attestation-mode "$mode" >"$stdout" 2>"$stderr"
status=$?
set -e

printf 'mode=%s\nattestation=%s\ndeployment_evidence=%s\nexit_code=%s\n' \
  "$mode" "$attestation" "$deployment_evidence" "$status" > "$invocation"

case "$status" in
  0)
    jq -e '.status == "immutable-candidate-match" and .target_contacted == false and .target_mutated == false and .cryptographic_signature_verified == false and .ministry_approval_established == false' "$stdout" >/dev/null
    cat > "$telemetry" <<EOF
# HELP blueeconomy_gitops_candidate_reconciliation_total Local immutable-candidate reconciliation outcomes.
# TYPE blueeconomy_gitops_candidate_reconciliation_total counter
blueeconomy_gitops_candidate_reconciliation_total{result="match",mode="$mode"} 1
# HELP blueeconomy_gitops_candidate_binding_blocking Whether this local result blocks the candidate.
# TYPE blueeconomy_gitops_candidate_binding_blocking gauge
blueeconomy_gitops_candidate_binding_blocking{mode="$mode"} 0
# HELP blueeconomy_gitops_candidate_external_contact_attempted Whether this runner attempted an external contact.
# TYPE blueeconomy_gitops_candidate_external_contact_attempted gauge
blueeconomy_gitops_candidate_external_contact_attempted 0
EOF
    ;;
  1)
    jq -e '.status == "immutable-candidate-drift" and (.mismatches | type == "array" and length > 0)' "$stdout" >/dev/null
    mismatch_fields=$(jq -r '.mismatches[].field' "$stdout" | sort -u)
    {
      printf '%s\n' '# HELP blueeconomy_gitops_candidate_reconciliation_total Local immutable-candidate reconciliation outcomes.'
      printf '%s\n' '# TYPE blueeconomy_gitops_candidate_reconciliation_total counter'
      printf 'blueeconomy_gitops_candidate_reconciliation_total{result="drift",mode="%s"} 1\n' "$mode"
      printf '%s\n' '# HELP blueeconomy_gitops_candidate_binding_mismatch_total Drift count by finite candidate field name.'
      printf '%s\n' '# TYPE blueeconomy_gitops_candidate_binding_mismatch_total counter'
      while IFS= read -r field; do
        [[ -n "$field" ]] && printf 'blueeconomy_gitops_candidate_binding_mismatch_total{field="%s",mode="%s"} 1\n' "$field" "$mode"
      done <<< "$mismatch_fields"
      printf '%s\n' '# HELP blueeconomy_gitops_candidate_binding_blocking Whether this local result blocks the candidate.'
      printf '%s\n' '# TYPE blueeconomy_gitops_candidate_binding_blocking gauge'
      printf 'blueeconomy_gitops_candidate_binding_blocking{mode="%s"} 1\n' "$mode"
      printf '%s\n' '# HELP blueeconomy_gitops_candidate_external_contact_attempted Whether this runner attempted an external contact.'
      printf '%s\n' 'blueeconomy_gitops_candidate_external_contact_attempted 0'
    } > "$telemetry"
    jq -n \
      --arg schema_version 'blueeconomy.gitops-candidate-binding-alert.v1' \
      --arg emitted_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg mode "$mode" \
      --arg run_id "$run_id" \
      --argjson mismatch_fields "$(jq -c '[.mismatches[].field] | unique' "$stdout")" \
      '{schema_version:$schema_version,event_type:"immutable_candidate_binding_drift",severity:"critical",action:"block_pull_request_and_promotion",emitted_at:$emitted_at,mode:$mode,run_id:$run_id,mismatch_fields:$mismatch_fields,target_contacted:false,target_mutated:false,cryptographic_signature_verified:false,ministry_approval_established:false,notification_sent:false}' > "$alert"
    printf 'ALERT: immutable candidate binding drift; pull request and promotion are blocked. See %s\n' "$alert" >&2
    ;;
  *)
    printf 'ALERT: reconciliation failed with exit status %s; pull request and promotion are blocked.\n' "$status" >&2
    ;;
esac

artifacts=("$stdout" "$stderr" "$invocation" "$telemetry")
[[ -f "$alert" ]] && artifacts+=("$alert")
sha256sum "${artifacts[@]}" > "$output_dir/${run_id}.sha256sums.txt"

exit "$status"
