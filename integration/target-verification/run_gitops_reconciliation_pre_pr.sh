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

set +e
python3 "$checker" \
  --attestation "$attestation" \
  --deployment-evidence "$deployment_evidence" \
  --attestation-mode "$mode" >"$stdout" 2>"$stderr"
status=$?
set -e

printf 'mode=%s\nattestation=%s\ndeployment_evidence=%s\nexit_code=%s\n' \
  "$mode" "$attestation" "$deployment_evidence" "$status" > "$invocation"
sha256sum "$stdout" "$stderr" "$invocation" > "$output_dir/${run_id}.sha256sums.txt"

case "$status" in
  0)
    jq -e '.status == "immutable-candidate-match" and .target_contacted == false and .target_mutated == false and .cryptographic_signature_verified == false and .ministry_approval_established == false' "$stdout" >/dev/null
    ;;
  1)
    jq -e '.status == "immutable-candidate-drift" and (.mismatches | type == "array" and length > 0)' "$stdout" >/dev/null
    ;;
esac

exit "$status"
