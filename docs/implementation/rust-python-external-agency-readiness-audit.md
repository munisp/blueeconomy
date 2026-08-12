# Rust and Python Microservice External-Agency Readiness Audit

**Author:** Manus AI  
**Audit date:** 12 August 2026  
**Repositories:** `munisp/blueeconomy-waterway-safety`, `munisp/blueeconomy-data-platform`, `munisp/blueeconomy-traceability`

## Executive conclusion

The three repositories now satisfy a materially stronger **source-foundation** standard: bounded and fail-closed inputs, deterministic tests, strict formatting/lint/type checks, package builds, locked dependencies where applicable, security scanning and vulnerability evidence. The audited commits are:

| Repository | Audited commit | Source-readiness conclusion |
|---|---|---|
| `blueeconomy-waterway-safety` | `1125240` | Ready to serve as a stateless integrity-validation library/CLI behind an approved gateway. It is **not** a live agency telemetry integration. |
| `blueeconomy-data-platform` | `a05a869` | Ready for controlled, approved NDJSON-to-Delta ingestion testing. It is **not** a connected Kafka/object-store/catalog agency data pipeline. |
| `blueeconomy-traceability` | `b360502` | Ready to validate the currently declared linear provenance-chain contract. It is **not** an authoritative fisheries/aquaculture traceability service. |

> **Readiness distinction:** “source-ready” means the committed component and its local verification controls are coherent and reproducible. It does not mean that an agency has supplied its contract, authenticated endpoint, records, legal authority, operational owner or acceptance evidence.

## Audit method and evidence

The audit covered source code, manifests, dependency locks, package contents, validation scripts, tests, error behavior, filesystem boundaries, data minimization and documented integration assumptions. Rust dependencies were checked against the current OSV batch API because the locally buildable older `cargo-audit` release could not parse the advisory database’s newer CVSS 4 records. OSV’s API is the authoritative query mechanism used by the saved audit helper.[1]

| Check | Rust result | Lakehouse Python result | Traceability Python result |
|---|---:|---:|---:|
| Deterministic tests | 8 passed | 5 passed | 5 passed |
| Formatting/linting | `cargo fmt`; Clippy with warnings denied | Ruff passed | Ruff passed |
| Type/static analysis | Rust compiler and Clippy passed | Strict mypy passed | Strict mypy passed |
| Security source scan | Unsafe Rust forbidden | Bandit: 0 findings across 296 LOC | Bandit: 0 findings across 258 LOC |
| Dependency audit | 25 locked registry packages; OSV: 0 findings | 11 runtime and 26 development packages; `pip-audit`: 0 findings | 15 development packages; `pip-audit`: 0 findings |
| Package build | Locked optimized Rust release build passed | Wheel and source distribution built and inspected | Wheel and source distribution built and inspected |
| Full portfolio regression | Passed | Passed | Passed |

Vulnerability results are point-in-time evidence, not a permanent safety claim. Advisory databases and dependency versions must be rescanned on every pull request and before each release.[1] [2]

## Rust waterway-safety findings

### Remediated findings

| Severity | Finding before remediation | Remediation and evidence |
|---|---|---|
| High | The CLI read an entire input file and decoded base64 before a reliable encoded-input bound, allowing avoidable memory pressure. | The CLI now rejects symlinks, non-regular files, empty files and JSON above 1,500,000 bytes before reading. Encoded and decoded payload limits are enforced before and after decoding. |
| Medium | Digest syntax accepted any lowercase letter, not only hexadecimal `a-f`. | Validation now accepts exactly 64 lowercase hexadecimal characters; a deterministic regression test rejects `g`. |
| Medium | RFC 3339 values were parsed independently but `observed_at > received_at` was accepted. | The validator now rejects reversed observation/receipt chronology. |
| Medium | Device and gateway identifiers allowed leading/trailing whitespace and control characters. | Identifiers must now be canonical, bounded, non-control text. |
| Medium | Only two negative tests existed. | Eight tests now cover a valid record, digest mismatch, non-hex digest, classification, canonical identifier, timestamp order, unknown JSON fields and oversized input. |
| Low | The crate did not explicitly forbid unsafe code. | `#![forbid(unsafe_code)]` now protects the library and binary. |
| Supply chain | The initial scanner version could not parse current CVSS 4 advisory records, so a failed scan could be mistaken for a clean scan. | A saved standard-library OSV audit helper now queries every `Cargo.lock` registry package through the fixed HTTPS OSV API and fails if findings exist. |

### Residual agency-integration blockers

The Rust component verifies integrity but not authenticity. SHA-256 confirms that decoded bytes match a declared digest; it does not prove that an authorised device created the payload. An external integration still requires the agency’s gateway protocol, device/gateway certificate model, mTLS or signature verification, registry/status lookup, firmware and key-rotation policy, sequence/replay persistence, clock-skew policy, approved payload schema, topic contract, geofence/rule service, incident workflow, observability and recovery behavior.

The validator is therefore suitable as a hardened processing primitive, not as a standalone external-facing microservice. A network adapter must enforce authenticated transport, bounded concurrency, backpressure, rate limits, structured telemetry, durable delivery and agency-specific schema/version negotiation.

## Python lakehouse findings

### Remediated findings

| Severity | Finding before remediation | Remediation and evidence |
|---|---|---|
| High | Duplicate detection was a read-before-append check; concurrent writers could pass the check independently. | Existing tables now use a real insert-only Delta merge keyed by `event_id`. Fully repeated batches are no-ops; local Delta integration confirms one retained row and no second commit. Delta Lake remains the actual storage engine.[3] |
| High | NDJSON lines, canonical payloads and total input were not independently bounded. | The implementation now limits files, lines, records and canonical payload bytes and rejects symlink/non-regular inputs. |
| Medium | Broad backend exception text was inspected to infer a missing table, risking misclassification of authorization or storage failures. | The implementation now catches the pinned library’s explicit `TableNotFoundError`; other backend failures propagate. |
| Medium | JSON `NaN`/infinity values could be accepted by Python’s permissive decoder. | Non-finite constants and nonstandard payload output now fail closed. |
| Medium | `occurred_at > recorded_at` was accepted. | Timestamp ordering is enforced after UTC normalization. |
| Medium | Run evidence exposed raw local input paths and table URIs. | The v2 report stores the input-file SHA-256 and table-reference SHA-256 instead of paths/URIs. |
| Medium | The report path could overwrite the input or schema. | Explicit path-separation validation is now tested. |
| Medium | No real Delta transaction test existed. | Five tests include a real local Delta table and idempotent retry, plus timestamp, non-finite JSON, URI-secret and path-safety cases. |
| Supply chain | Direct dependencies were pinned but transitive graphs and development tools were not hash locked. | Runtime and development locks now include hashes. A vulnerable pytest 8.4.1 audit finding was discovered and remediated to the reported fixed 9.0.3 release before publication. |

### Residual agency-integration blockers

The component remains a controlled batch-ingestion command. It has no authenticated Kafka/Fluvio consumer, schema registry, Dapr component, agency adapter, dead-letter path, source acknowledgement, Temporal workflow, object-store workload identity, catalogue/lineage publication, data-quality owner, retention/legal-hold policy, cross-site replication or operational SLO.

Insert-only merge supplies event-ID idempotency at the table boundary. Production still needs object-store-specific concurrency/load tests, bounded commit retry and alerting, partition/layout design, schema-evolution governance, event-contract compatibility and an accountable replay/reconciliation procedure.

## Python traceability findings

### Remediated findings

| Severity | Finding before remediation | Remediation and evidence |
|---|---|---|
| High | The chain digest omitted actor, source-record reference and classification, so those validated provenance fields could change without changing the evidence digest. | The v2 digest now canonicalizes and binds every validated event field. A regression test changes the actor and proves the digest changes. |
| High | Files and individual NDJSON lines were unbounded. | Regular-file, symlink, file-size and line-size controls now fail closed before record processing. |
| Medium | Evidence disclosed the input path and could overwrite the input. | Evidence now records the input-file SHA-256 and rejects a colliding destination path. |
| Medium | Text was trimmed silently, allowing transport changes to become invisible. | Identifiers and references must arrive in canonical non-control form; whitespace-altered identifiers are rejected. |
| Medium | Only source compilation and empty-chain rejection were exercised. | Five deterministic tests now cover a valid chain, complete-field digest binding, chronology, cross-lot references, canonical identifiers and output safety. |
| Supply chain | No dependency lock or reproducible assurance toolchain existed. | Hash-locked development dependencies, strict mypy/Ruff/Bandit/pytest checks and package builds are committed. The pytest advisory was remediated before publication. |

### Residual agency-integration blockers

The current vocabulary is deliberately narrow. It does not define quantity conservation, lot split/merge, product transformation, species/product master data, licensing, vessel/farm identity, cold-chain measurements, inspection/laboratory outcomes, recall status, signatures, corrections, jurisdiction or disclosure policy. These rules must come from the authoritative fisheries and custody partners; inventing them would create false compliance.

The validator also lacks authenticated event transport, durable storage, partner acknowledgements, reconciliation, privacy filters, portal casework, offline synchronization and operational acceptance. It is ready to receive an approved contract extension, not to be declared live.

## External-agency readiness verdict

| Component | Source quality | Local behavior | Direct external connection now? | Required next gate |
|---|---|---|---|---|
| Rust telemetry integrity | Hardened and reproducibly validated | Stateless real-byte digest and metadata checks pass | **No** | Authoritative protocol/schema, device trust, gateway, replay state and incident workflow |
| Delta ingestion | Hardened; real Delta tests and locked dependencies pass | File-to-local-Delta idempotency passes | **No** | Ministry object storage/IAM, event transport, schema governance, lineage, replay and SRE evidence |
| Traceability validator | Hardened and complete for its declared narrow model | Provenance/chronology and full-field digest tests pass | **No** | Authoritative fisheries/custody contract, identities, quantities/split-merge rules, endpoints and partner acceptance |

## Score implication

The conservative platform score moves from **28.75% to 29.25%**. S5 now meets the full 25% source-foundation definition because versioned code, complete-field evidence, dependency locks, deterministic tests, static analysis and security/vulnerability evidence all exist. S6 was already at 25% source foundation, and the lakehouse hardening does not create an authorised S2 feed or a Ministry hybrid environment. No other workstream receives integration credit.

The quantified path to at least 80% is documented in `bridge-to-80-percent.md`. It requires actual Ministry non-production integration across all major workstreams and operational acceptance for central administration plus at least one high-value business pilot. Source hardening alone cannot create that evidence.

## References

[1]: https://google.github.io/osv.dev/api/ "OSV API"
[2]: https://pip-audit.readthedocs.io/ "pip-audit Documentation"
[3]: https://delta-io.github.io/delta-rs/ "Delta Lake delta-rs Documentation"
[4]: https://doc.rust-lang.org/cargo/commands/cargo-test.html "Cargo Test Documentation"
[5]: https://docs.pytest.org/ "pytest Documentation"
