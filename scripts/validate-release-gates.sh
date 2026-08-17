#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mode=${1:-local}
for repo in blueeconomy-port-interoperability blueeconomy-maritime-intelligence blueeconomy-financial-controls blueeconomy-credential-verification blueeconomy-traceability blueeconomy-waterway-safety; do
  test -d "$root/../$repo" || { echo "missing repository: $repo" >&2; exit 1; }
done
printf '%s\n' 'LOCAL_RELEASE_GATE: repository topology present'
if [[ "$mode" == local ]]; then
  printf '%s\n' 'LOCAL_RELEASE_GATE: external authority gates intentionally not evaluated'
  exit 0
fi
if [[ "$mode" == staging ]]; then
  required=(
    MINISTRY_NONPROD_ENVIRONMENT_REF
    PRIVACY_DPO_NONPROD_APPROVAL_REF
    NSW_PCS_SANDBOX_CONTRACT_REF
    NSW_PCS_SANDBOX_MTLS_TRUST_REF
    NSW_PCS_SANDBOX_JWKS_MANIFEST_REF
    TIGERBEETLE_NONPROD_CLUSTER_REF
    MOJALOOP_SANDBOX_ONBOARDING_REF
  )
  missing=0
  for name in "${required[@]}"; do
    if [[ -z "${!name:-}" ]]; then echo "missing staging release gate: $name" >&2; missing=1; fi
  done
  (( missing == 0 )) || exit 2
  printf '%s\n' 'STAGING_RELEASE_GATE: non-production authority references supplied; production quorum and pilot acceptance remain blocked'
  exit 0
fi
[[ "$mode" == production ]] || { echo 'usage: validate-release-gates.sh [local|staging|production]' >&2; exit 64; }
required=(
  MINISTRY_G0_APPROVAL_REF
  NSW_PCS_AUTHORITY_CONTRACT_REF
  NSW_PCS_MTLS_TRUST_REF
  NSW_PCS_JWKS_MANIFEST_REF
  TIGERBEETLE_SIX_REPLICA_APPROVAL_REF
  TIGERBEETLE_FAULT_TEST_EVIDENCE_REF
  MOJALOOP_SANDBOX_CONFORMANCE_REF
  PRIVACY_DPO_APPROVAL_REF
)
missing=0
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then echo "missing production release gate: $name" >&2; missing=1; fi
done
(( missing == 0 )) || exit 2
printf '%s\n' 'PRODUCTION_RELEASE_GATE: authority references supplied; independent evidence review still required'
