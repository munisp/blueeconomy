# Authorised Target Verification Harness

This directory contains **fail-closed orchestration scripts** for target-side S2 maritime-feed and S3 regulated-payment negative/resilience tests. They are not local mocks, partner simulators, or payment gateways. They contain no target endpoint, credential, signing key, raw test data, tenant, participant, cluster, or fault-command default.

> Execute only in an approved Ministry-controlled non-production environment with a named change authorisation, approved and digest-bound runbook, authorised partner, defined test data, designated stop authority, approved encrypted evidence store, and KMS/HSM-backed integrity-verification service.

## Scripts

| Script | Purpose | Does it contact a target by itself? |
|---|---|---|
| `run-maritime-feed-target-tests.sh` | Runs 23 owner-approved maritime-feed negative, resilience, rollback, restore, replay, identity, and observability cases through a supplied authorised runner. | No. |
| `run-regulated-payment-target-tests.sh` | Runs 13 owner-approved payment identity, instruction, provider, ledger, reconciliation, quorum, restore, and audit cases through a supplied authorised runner. | No. |
| `validate-maritime-feed-dr-evidence.sh` | Verifies structural consistency, secure local modes, runbook/artifact binding, runner-digest binding, and integrity-attestation metadata for a completed maritime DR bundle. | No. |
| `validate-target-acceptance-readiness.sh` | Reports whether required control names, non-secret references, runner/verifier paths and approved digests are ready. It never enables execution or contacts a target. | No. |
| `validate-target-evidence-bundle.sh` | Verifies an authorised S2 or S3 evidence bundle offline, including v3 manifest/summary bindings and retained file hashes. It does not cryptographically verify a KMS/HSM signature itself. | No. |
| `validate-protected-promotion-closeout-attestation.sh` | Validates a template, pending candidate or asserted approved promotion-closeout attestation offline, including candidate digest binding and evidence grouping. It never verifies a Ministry signature, contacts a target or establishes approval. | No. |
| `schemas/blueeconomy.protected-promotion-closeout.v1.schema.json` | Repository-owned structural JSON Schema baseline for closeout attestations. Ministry policy, signer authorization and signature trust remain externally governed. | No. |
| `reconcile_gitops_deployment_identity.py` | Compares a closeout candidate with a local, Ministry-controlled GitOps deployment-identity export. It blocks immutable commit/digest or reconciler-identity drift without any network or cluster access. | No. |
| `run_gitops_reconciliation_pre_pr.sh` | Local wrapper for syntax, self-test, reconciliation result retention, non-secret drift telemetry and exit-code enforcement before a pull request. It accepts only local absolute evidence paths. | No. |
| `evaluate_offline_revocation_cache.py` | Selects a current cached CRL or, only when policy permits, a current pre-cached stapled-OCSP record for an air-gapped audit. It never fetches a PKI endpoint or claims cryptographic verification. | No. |
| `schemas/blueeconomy.gitops-deployment-identity.v1.schema.json` | Structural schema baseline for the controlled deployment-identity export consumed by the reconciliation checker. | No. |
| `lib/target_test_common.sh` | Shared authorisation, path, mode, immutable runner/verifier digest, manifest, integrity-attestation, result, and sensitive-field validation. | No. |

## Dry-run validation

The dry-run paths enumerate required case names without reading credentials, contacting an endpoint, injecting a fault, performing integrity signing, or mutating a target.

```bash
./run-maritime-feed-target-tests.sh --dry-run
./run-regulated-payment-target-tests.sh --dry-run
```

## Execution gate

Target execution requires an approved case runner **and** an approved integrity verifier. Both must be Ministry/partner-owned executable regular files delivered through an approved administration path and pinned by separately approved SHA-256 digests. The case runner obtains target configuration and short-lived credentials only through approved workload identity and secret-management controls. The integrity verifier binds the completed evidence manifest to an organisation-managed KMS/HSM signing workflow.

| Maritime variable | Payment equivalent | Requirement |
|---|---|---|
| `MARITIME_TARGET_TEST_ENABLED=true` | `PAYMENT_TARGET_TEST_ENABLED=true` | Explicitly enables execution. |
| `MARITIME_TARGET_AUTHORIZATION_REF` | `PAYMENT_TARGET_AUTHORIZATION_REF` | Approved change/fault authorisation reference. |
| `MARITIME_TARGET_ENVIRONMENT` | `PAYMENT_TARGET_ENVIRONMENT` | Named Ministry-controlled non-production target. |
| `MARITIME_TARGET_RUNBOOK_REF` | `PAYMENT_TARGET_RUNBOOK_REF` | Approved operational/rollback/DR runbook reference. |
| `MARITIME_TARGET_RUNBOOK_SHA256` | `PAYMENT_TARGET_RUNBOOK_SHA256` | Exact 64-character SHA-256 digest of the approved runbook bytes. |
| `MARITIME_TARGET_CASE_RUNNER` | `PAYMENT_TARGET_CASE_RUNNER` | Absolute, canonicalised, non-symlinked, executable regular file that is not group/world writable. |
| `MARITIME_TARGET_CASE_RUNNER_SHA256` | `PAYMENT_TARGET_CASE_RUNNER_SHA256` | Exact 64-character SHA-256 digest of the approved case-runner bytes; checked before any target case runs and recorded in manifest/summary v3. |
| `MARITIME_TARGET_ARTIFACT_ROOT` | `PAYMENT_TARGET_ARTIFACT_ROOT` | Absolute, canonicalised, non-symlinked approved evidence root that is not world writable. |
| `MARITIME_TARGET_ARTIFACT_ROOT_ID` | `PAYMENT_TARGET_ARTIFACT_ROOT_ID` | Approved storage/classification/retention reference recorded in the execution manifest. |
| `MARITIME_TARGET_INTEGRITY_VERIFIER` | `PAYMENT_TARGET_INTEGRITY_VERIFIER` | Absolute, canonicalised, non-symlinked approved KMS/HSM integrity verifier. |
| `MARITIME_TARGET_INTEGRITY_VERIFIER_SHA256` | `PAYMENT_TARGET_INTEGRITY_VERIFIER_SHA256` | Exact 64-character SHA-256 digest of the approved integrity-verifier bytes; checked before evidence creation. |

The wrapper rejects absent authorisation, invalid references, missing/invalid runbook digest, insecure artifact root, relative or writable runner paths, non-passing result evidence, and result fields named like secrets, tokens, or private keys. It creates directories with `0750` and result/log/manifest files with `0640`; these modes supplement—not replace—encrypted storage and workload-identity policy.

## Case-runner contract

The supplied case runner is called as follows:

```text
<approved-case-runner> <case-name> <run-id>
```

It receives these environment variables:

| Variable | Meaning |
|---|---|
| `TARGET_TEST_SUITE` | `maritime-feed-target` or `regulated-payment-target`. |
| `TARGET_TEST_CASE` | The individual scenario name. |
| `TARGET_TEST_CASE_DIR` | Approved per-case redacted artifact directory. |
| `TARGET_TEST_RUN_ID` | UTC-derived run identifier. |

The runner must write `$TARGET_TEST_CASE_DIR/result.json` in this form after a **passing** test. It must not write a credential, raw payment record, restricted intelligence, private key, bearer token, or raw partner payload to the result, stdout, stderr, or the evidence directory.

```json
{
  "schema_version": "blueeconomy.target-test-result.v1",
  "suite": "maritime-feed-target",
  "case": "feed_outage_recovery",
  "target_environment": "ministry-s2-nonprod",
  "status": "passed",
  "executed_at": "2026-08-20T12:00:00Z",
  "expected_safe_outcome": "Approved retry and reconciliation completed without duplicate logical effects.",
  "observed_outcome": "Broker recovery reconciled one source identity to one logical downstream effect.",
  "evidence_references": ["change:CHG-EXAMPLE", "runbook:S2-DR-EXAMPLE", "evidence:secure-reference"]
}
```

## Integrity-verifier contract

After all cases have passed, the wrapper writes a canonical `evidence-manifest.json` containing the run identity, approved runbook digest, artifact-root identity, approved case-runner and integrity-verifier digests, and SHA-256/byte-size record for each non-integrity artifact. It then invokes:

```text
<approved-integrity-verifier> <artifact-directory> <run-id>
```

The verifier receives `TARGET_TEST_EVIDENCE_MANIFEST`, `TARGET_TEST_INTEGRITY_ATTESTATION`, `TARGET_TEST_SUITE`, `TARGET_TEST_TARGET_ENVIRONMENT`, `TARGET_TEST_RUN_ID`, `TARGET_TEST_RUNBOOK_SHA256`, and `TARGET_TEST_ARTIFACT_ROOT_ID`. It must create `integrity-attestation.json` using schema `blueeconomy.evidence-integrity.v1`, bind the exact SHA-256 of the manifest, and provide a trusted signature reference and signer key identifier. The wrapper validates the binding but does not itself hold a private key or substitute for the Ministry’s KMS/HSM verification service.

A runner that receives a scenario it does not support must fail before action. It must not replace a target case with a mock, synthetic partner, placeholder endpoint, or locally generated assertion.

## Protected-promotion closeout structural validation

The repository supplies a structural baseline schema and an offline validator for promotion closeout records. They validate only the payload’s form, candidate commit/digest bindings, required P1–P18 evidence grouping, forbidden sensitive-content markers, and explicit template/pending/approved status profiles. They deliberately **do not** fetch evidence, query a target, access a KMS/HSM, validate signer authorization, verify a cryptographic signature, or establish a Ministry approval.

```bash
# Explicitly non-authoritative template validation.
./validate-protected-promotion-closeout-attestation.sh \
  --attestation /absolute/path/to/template.json --mode template

# Pending candidate, bound to the immutable release candidate values.
./validate-protected-promotion-closeout-attestation.sh \
  --attestation /absolute/path/to/candidate.json --mode candidate \
  --expected-source-commit <40-hex> \
  --expected-overlay-commit <40-hex> \
  --expected-rendered-manifest-sha256 <64-hex> \
  --expected-external-secret-manifest-sha256 <64-hex> \
  --expected-image-chart-set-sha256 <64-hex>
```

The final audit gate must use the Ministry-approved verification service and trusted signer policy to establish cryptographic authenticity, signature validity, signer authorization, revocation/expiry state and evidence-record accessibility before accepting any asserted `approved` payload.

## Offline GitOps deployment-identity reconciliation

The Python checker consumes an absolute local closeout-attestation file and an absolute, controlled deployment-identity export. It compares the source commit, environment overlay commit, rendered manifest SHA-256, ExternalSecret manifest SHA-256, image/chart digest-set SHA-256, and GitOps reconciler reference. A mismatch emits `immutable-candidate-drift` and exits with status `1`; a match reports `immutable-candidate-match`. Both outcomes expressly report no target contact, no target mutation, no cryptographic signature verification and no Ministry approval establishment.

```bash
python3 ./reconcile_gitops_deployment_identity.py \
  --attestation /absolute/path/to/candidate.json \
  --deployment-evidence /absolute/path/to/ministry-controlled-export.json \
  --attestation-mode candidate
```

The export must be collected by the Ministry-approved GitOps evidence adapter. This repository checker never queries a cluster or reconciler itself and cannot establish live deployment identity.

For local pre-pull-request validation, use the wrapper to run its fixture self-test, then compare the approved local candidate/export files. The output directory retains non-secret result, error, invocation and hash records. Exit `0` is a local immutable-candidate match, while exit `1` is a drift block—not Ministry approval.

```bash
./run_gitops_reconciliation_pre_pr.sh --self-test
./run_gitops_reconciliation_pre_pr.sh \
  --attestation /absolute/path/to/candidate.json \
  --deployment-evidence /absolute/path/to/ministry-controlled-export.json \
  --mode candidate \
  --output-dir /absolute/path/to/local-evidence
```

## Air-gapped offline revocation-cache selection

`evaluate_offline_revocation_cache.py` is a local policy-selection control for a Ministry-controlled cache manifest. When a cached CRL is expired or not good, it can select a **previously captured** current stapled-OCSP entry only if the supplied offline policy permits that fallback. It never performs a network request, validates a CRL/OCSP signature, validates a trust path or establishes approval; the Ministry final-audit verifier must perform those operations against the approved trust/cache material.

```bash
python3 ./evaluate_offline_revocation_cache.py \
  --policy /absolute/path/to/approved-offline-revocation-policy.json \
  --cache-manifest /absolute/path/to/controlled-cache-manifest.json \
  --certificate-reference <non-secret-reference> \
  --verification-time <RFC3339-UTC>
```

A selected result is `*-requires-cryptographic-verification`; no current trusted cached record yields `revocation-status-blocked` and exit `1`. The utility never falls back to a live OCSP or CRL endpoint.

## Pre-pull-request drift telemetry

On a local immutable-candidate mismatch, `run_gitops_reconciliation_pre_pr.sh` exits `1`, writes a Prometheus text artifact and a structured critical alert JSON into its output directory, and prints a local blocking alert to stderr. It sends no notification and includes only finite field names—not candidate hashes, paths, credentials or endpoint values—in telemetry labels/alert fields. The local metrics are `blueeconomy_gitops_candidate_reconciliation_total`, `blueeconomy_gitops_candidate_binding_mismatch_total`, `blueeconomy_gitops_candidate_binding_blocking`, and `blueeconomy_gitops_candidate_external_contact_attempted`.

## Maritime rollback and DR procedure

See [maritime-feed-rollback-and-disaster-recovery-validation.md](maritime-feed-rollback-and-disaster-recovery-validation.md). The procedure covers deployment rollback, Kubernetes failure-domain recovery, PostgreSQL PITR, outbox/Kafka replay reconciliation, Delta reprocessing/lineage, object-store recovery, OIDC/source-key revocation, observability retention, final evidence validation, and owner acceptance.
