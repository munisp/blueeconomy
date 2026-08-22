# Blue Economy Platform Innovation Backlog and Delivery Record

**Date:** 2026-08-22  
**Decision boundary:** Items that require a Ministry-controlled APISIX, Keycloak, KMS/HSM, partner endpoint, named environment or authorization are deliberately marked **external acceptance required**. They are not simulated and are not represented as delivered.

## Prioritized innovations

| # | Innovation | Outcome | Status | Ownership boundary |
|---:|---|---|---|---|
| 1 | Non-invasive target readiness preflight | Emits redacted JSON/text readiness state without invoking a target. | **Implemented** | Repository-controlled. |
| 2 | Explicit enablement gate | Requires `*_TARGET_TEST_ENABLED=true` before any target path can run. | **Existing, retained** | Ministry approval required. |
| 3 | Authorization and runbook binding | Requires approved authorization, runbook reference and exact runbook SHA-256. | **Existing, retained** | Ministry change authority. |
| 4 | Immutable case-runner pinning | Requires and checks SHA-256 for the approved external case-runner bytes. | **Implemented** | Ministry/partner runner delivery. |
| 5 | Immutable integrity-verifier pinning | Requires and checks SHA-256 for the approved KMS/HSM verifier bytes. | **Implemented** | Ministry/KMS owner. |
| 6 | Canonical runner path guard | Rejects relative, symlinked, writable and non-canonical runner/verifier paths. | **Enhanced** | Repository-controlled gate. |
| 7 | Evidence manifest v3 | Binds authorization/runbook/artifact identity plus runner and verifier digests. | **Implemented** | Repository-controlled format. |
| 8 | Summary v3 cross-binding | Requires completed-suite summary to carry the same runner/verifier digests. | **Implemented** | Repository-controlled format. |
| 9 | Generic offline evidence validator | Validates S2 or S3 bundle structure, modes, file hashes, redaction fields and bindings without target access. | **Implemented** | Repository-controlled post-run control. |
| 10 | Maritime DR validator upgrade | Delegates to generic v3 validation and then checks required recovery cases. | **Enhanced** | Repository-controlled post-run control. |
| 11 | Sensitive-content tripwire | Rejects retained evidence containing private-key, bearer-token or common credential markers. | **Implemented** | Repository-controlled post-run control. |
| 12 | CI safety workflow | Runs only syntax checks, dry-runs and a redacted readiness report under least-privilege `contents: read`. | **Implemented** | Repository-controlled CI. |
| 13 | APISIX attachment release contract | Requires a non-secret plugin-set reference, SHA-256 and policy-change approval reference in Helm values. | **Implemented** | GitOps contract; target attachment remains external. |
| 14 | APISIX partner-route canonicalization | Requires a non-empty route set; canonical route/host/scope metadata; unique methods, scopes and host/path pairs. | **Implemented** | GitOps contract. |
| 15 | APISIX negative-render regression coverage | Adds regression failures for empty/malformed plugin metadata, invalid routes and duplicate controls. | **Implemented** | Repository-controlled CI. |
| 16 | Target APISIX attachment attestation | Approved runner obtains read-only attachment state and proves exact plugin-set digest at the named non-production target. | **External acceptance required** | Ministry API-gateway owner. |
| 17 | Keycloak policy export and claim-contract attestation | Approved runner verifies realm/client policy, issuer/JWKS, algorithm, audience, scope, expiry and revocation behavior against the approved target. | **External acceptance required** | Ministry identity owner. |
| 18 | KMS/HSM workload-identity authorization test | Approved runner demonstrates only the intended workload may request the defined verify/sign operation, while denial cases leave no unauthorized side effect. | **External acceptance required** | Ministry KMS/HSM owner. |
| 19 | Immutable evidence-store retention proof | Ministry evidence owner supplies encrypted storage identity, retention classification, write-once/retention configuration and integrity-verifier provenance. | **External acceptance required** | Evidence governance and KMS owners. |
| 20 | Partner-schema compatibility and resilience acceptance | Authorised partners supply formal profiles, sandbox routing and data-handling approval for contract, replay, timeout, reconciliation and rollback cases. | **External acceptance required** | Partner interface owners and Ministry change authority. |

## Recommended delivery sequence

The repository-controlled controls in items 1–15 are intended to make an authorised acceptance run observable and difficult to misconfigure. The next work must begin with an approved change record and a named Ministry non-production environment, not with generated endpoints or placeholder credentials.

For the APISIX target, the gateway owner should provide the approved plugin-set reference and digest, target namespace/route identity, policy-change approval reference and a workload identity that can read attachment status but cannot alter unrelated routes. For Keycloak, the identity owner should provide the approved realm/client policy version, the expected issuer/JWKS/claim contract and controlled test principals. For KMS/HSM, the cryptographic owner should provide a verifier executable, its SHA-256, signer key identifier, permitted workload identity and evidence-retention location.

> A rendered Helm ConfigMap is a statement of intended non-secret contract metadata. It is not evidence that an APISIX plugin is attached, a Keycloak policy is enforced, or a KMS/HSM call is authorized. Those statements require items 16–20 to be executed through the approved target runner.

## Acceptance-gate minimum

Before either target suite is invoked, the approval package must contain a named change/fault authorization, target-environment identifier, approved runbook and SHA-256, approved case-runner path and SHA-256, approved integrity-verifier path and SHA-256, encrypted evidence-root identity and a named stop authority. The approved runner must acquire endpoints and short-lived credentials only from the Ministry’s workload-identity and secret-management controls.

## References

[1]: ../integration/target-verification/README.md "Target-side verification contract"
[2]: ../integration/target-verification/validate-target-acceptance-readiness.sh "Non-invasive readiness preflight"
[3]: ../../blueeconomy-platform-gitops/charts/mojaloop-overlay/templates/000-validation.yaml "Mojaloop fail-closed Helm guards"
