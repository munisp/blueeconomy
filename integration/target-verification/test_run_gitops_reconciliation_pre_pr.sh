#!/usr/bin/env bash
# Offline regression tests for the local pre-pull-request reconciliation runner.
# Uses only checked-in inert fixtures and emits no network notification.

set -euo pipefail
umask 077

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
runner="$root/run_gitops_reconciliation_pre_pr.sh"
attestation="$root/examples/protected-promotion-closeout.pending-candidate.example.json"
match="$root/examples/gitops-deployment-identity.match.example.json"
drift="$root/examples/gitops-deployment-identity.image-drift.example.json"
workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT

"$runner" --self-test >"$workspace/self-test.stdout" 2>"$workspace/self-test.stderr"
"$runner" \
  --attestation "$attestation" \
  --deployment-evidence "$match" \
  --mode candidate \
  --output-dir "$workspace/match" >"$workspace/match.stdout" 2>"$workspace/match.stderr"

set +e
"$runner" \
  --attestation "$attestation" \
  --deployment-evidence "$drift" \
  --mode candidate \
  --output-dir "$workspace/drift" >"$workspace/drift.stdout" 2>"$workspace/drift.stderr"
status=$?
set -e
[[ $status -eq 1 ]] || { echo "drift exit status must be 1, got $status" >&2; exit 1; }

telemetry=$(find "$workspace/drift" -maxdepth 1 -type f -name '*.telemetry.prom' -print -quit)
alert=$(find "$workspace/drift" -maxdepth 1 -type f -name '*.alert.json' -print -quit)
[[ -n "$telemetry" && -n "$alert" ]] || { echo 'drift telemetry or alert is missing' >&2; exit 1; }

grep -Fq 'blueeconomy_gitops_candidate_reconciliation_total{result="drift",mode="candidate"} 1' "$telemetry"
grep -Fq 'blueeconomy_gitops_candidate_binding_mismatch_total{field="image_and_chart_digest_set_sha256",mode="candidate"} 1' "$telemetry"
grep -Fq 'blueeconomy_gitops_candidate_binding_blocking{mode="candidate"} 1' "$telemetry"
grep -Fq 'blueeconomy_gitops_candidate_external_contact_attempted 0' "$telemetry"
jq -e '.event_type == "immutable_candidate_binding_drift" and .severity == "critical" and .action == "block_pull_request_and_promotion" and .mismatch_fields == ["image_and_chart_digest_set_sha256"] and .notification_sent == false and .target_contacted == false and .target_mutated == false' "$alert" >/dev/null
grep -Fq 'ALERT: immutable candidate binding drift; pull request and promotion are blocked.' "$workspace/drift.stderr"

printf '%s\n' 'pre-PR reconciliation runner telemetry tests passed'
