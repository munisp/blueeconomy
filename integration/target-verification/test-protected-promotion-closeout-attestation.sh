#!/usr/bin/env bash
# Offline regression tests for closeout-attestation structural validation.
# Uses inert marker strings only; no credentials, target calls, signing or deployment.

set -euo pipefail
umask 077

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
validator="$root/validate-protected-promotion-closeout-attestation.sh"
template="$root/examples/protected-promotion-closeout.template.json"
candidate="$root/examples/protected-promotion-closeout.pending-candidate.example.json"
workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT

expect_pass() {
  local name=$1
  shift
  "$@" >"$workspace/${name}.stdout" 2>"$workspace/${name}.stderr"
}

expect_sensitive_rejection() {
  local name=$1 fixture=$2
  set +e
  "$validator" --attestation "$fixture" --mode candidate >"$workspace/${name}.stdout" 2>"$workspace/${name}.stderr"
  local status=$?
  set -e
  [[ $status -ne 0 ]] || { echo "$name unexpectedly passed" >&2; return 1; }
  grep -Fq 'attestation contains a prohibited sensitive-content marker' "$workspace/${name}.stderr"
}

expect_pass template "$validator" --attestation "$template" --mode template
expect_pass candidate "$validator" --attestation "$candidate" --mode candidate

set +e
"$validator" --attestation "$template" --mode approved >"$workspace/template-approved.stdout" 2>"$workspace/template-approved.stderr"
status=$?
set -e
[[ $status -ne 0 ]] || { echo 'template unexpectedly accepted as approved' >&2; exit 1; }

cp "$candidate" "$workspace/pem.json"
sed -i 's/PENDING_AUTHORIZED_SIGNATURE/-----BEGIN TEST PRIVATE KEY-----/' "$workspace/pem.json"
expect_sensitive_rejection pem "$workspace/pem.json"

cp "$candidate" "$workspace/bearer.json"
sed -i 's/PENDING_AUTHORIZED_SIGNATURE/Authorization: Bearer NONSENSITIVE_TEST_MARKER/' "$workspace/bearer.json"
expect_sensitive_rejection bearer "$workspace/bearer.json"

cp "$candidate" "$workspace/password.json"
sed -i '/"signature_value"/i\    "password": "NONSECRET_TEST_MARKER",' "$workspace/password.json"
expect_sensitive_rejection password "$workspace/password.json"

cp "$candidate" "$workspace/client-secret.json"
sed -i '/"signature_value"/i\    "client_secret": "NONSECRET_TEST_MARKER",' "$workspace/client-secret.json"
expect_sensitive_rejection client_secret "$workspace/client-secret.json"

printf '%s\n' 'closeout-attestation validator regression tests passed'
