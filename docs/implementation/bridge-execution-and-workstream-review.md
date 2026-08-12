# Bridge Execution, Go/Rust Verification, and Python Workstream Review

**Author:** Manus AI  
**Evidence date:** 12 August 2026  
**Programme baseline before this stage:** 29.25%  
**Verified baseline after this stage:** **34.00%**

## Executive result

This stage implemented four additional evidence-producing paths: a real PostgreSQL integration for immutable maritime evidence, a versioned runtime schema for traceability, a governed Apache Kafka-to-Delta consumer, and a complete Rust-safety-to-Kafka-to-Delta conformance pipeline. Apache Kafka 4.3.1 was selected from the project’s supported release list and run from the official image; this is a local integration artifact, not a Ministry cluster.[1] [2]

| Evidence area | Verified result | Published baseline |
|---|---|---|
| Central administration | PostgreSQL, Keycloak HTTPS and SMTP lifecycle; denial/idempotency branches; **76.1% statement coverage** | `blueeconomy-administration-service@d4168fa119b7` |
| Maritime evidence | Real PostgreSQL idempotent insert, immutable-row trigger and one-terminal-decision enforcement; **68.4% statement coverage** | `blueeconomy-maritime-evidence@f3474864149d` |
| Waterway safety | 8 library tests, 5 CLI tests, Clippy/release checks and **87.90% line coverage** | `blueeconomy-waterway-safety@49a0bcd553d3` |
| Kafka-to-Delta | Two real consumer groups each committed offset `1`; replay retained one Delta row | `blueeconomy-data-platform@7b169ea41f12` |
| Combined safety pipeline | Rust-normalized payload equalled the Delta payload exactly; Kafka replay remained idempotent | `blueeconomy@81eb44661793` |
| Traceability | Draft 2020-12 runtime schema, six tests, strict typing/lint/security and hash-locked dependencies | `blueeconomy-traceability@395f134381c6` |

## Go and Rust verification details

The central administration integration exercises request validation, authentication-header absence, unsupported role denial, maker/checker separation, duplicate decisions, Keycloak service-account token acquisition, organization invitation, SMTP receipt, organization-group activation and durable PostgreSQL decision history. Coverage is collected from the instrumented service binary after termination, so handler, store and Keycloak-client execution contributes to the measured **76.1%** statement result.

The maritime-evidence integration applies both PostgreSQL migrations and verifies three independent database guarantees. Repeating the same package key is idempotent; the trigger prevents mutation of an evidence package; and the unique terminal-history index permits only one accepted or rejected terminal decision. Its current aggregate statement coverage is **68.4%**. This validates the durable evidence substrate but not a National Single Window, Port Community System or agency adapter.

The Rust service now has executable-boundary tests for valid input, absent arguments, symlink input, oversized files and invalid telemetry. LLVM coverage includes both instrumented test objects and the actual application binary. The measured totals are **78.60% regions, 86.79% functions and 87.90% lines**. No unsafe Rust is permitted by either crate root. The combined pipeline then runs the release binary, publishes its normalized output through Kafka, consumes it into Delta through two groups, and verifies exact payload equality and idempotent replay.[8]

## Exact traceability implementation and schema change

The new `traceability-event.schema.json` is a versioned JSON Schema Draft 2020-12 document. It sets `additionalProperties: false` and requires `event_id`, `event_type`, `lot_id`, `occurred_at`, `actor_reference`, `source_record_reference` and `data_classification`. `event_type` is restricted to `harvest`, `landing`, `processing`, `dispatch` or `receipt`; classification uses the five platform classifications; and `previous_event_id` is optional and nullable. Identifier and reference lengths are explicitly bounded.[3] [4]

The command now requires `--schema`; it rejects symlinks, non-regular files, empty files and files exceeding 256 MiB. Each NDJSON line is bounded to 1 MiB, decoded as UTF-8, parsed with non-finite values prohibited and validated against the committed schema before domain parsing. Runtime semantic validation remains a second layer: each lot must start with one harvest root; a predecessor must occur earlier in the input, belong to the same lot and have a timestamp no later than the child; and event identifiers must be unique.[5]

The v2 chain digest is the SHA-256 of a canonical JSON array containing **all retained fields** for every event: identifier, type, lot, normalized UTC timestamp, actor reference, source-record reference, classification and predecessor. Validation evidence contains input SHA-256, record/lot counts, event-type counts and the chain digest, but not the records themselves. Evidence is atomically written with mode `0640`.

No database migration was introduced for traceability. The change is a source/schema contract change. The schema intentionally does **not** invent quantity, unit, species, licence, catch area, split/merge, transformation yield, temperature, inspection, correction or regulatory-document fields. Those require authoritative fisheries and custody-system owners before the domain contract can be expanded.

## Exact data-platform implementation and schema behavior

The committed lakehouse event envelope was not broadened during this stage. It still forbids undeclared top-level fields and requires event identity/type, producer, occurred/recorded timestamps, classification, source system, source-record reference and a payload object; `correlation_id` remains optional.[6]

The Delta row schema is produced by normalization and contains `event_id`, `event_type`, `producer`, UTC `occurred_at`, UTC `recorded_at`, `data_classification`, `source_system`, `source_record_reference`, nullable `correlation_id`, canonical `payload_json` and `ingested_at`. The writer creates the table with `delta.appendOnly=true`. Existing tables are checked for the same property and use an insert-only merge on `event_id`; commit conflicts are retried within a fixed bound.[6]

The new `blueeconomy-ingest-kafka` command adds authentic Kafka consumption. Automatic offset commit and automatic offset storage are disabled. Messages are bounded, decoded as UTF-8 JSON, validated against the same envelope schema and normalized through the same code path as file ingestion. A batch is written to Delta before offsets are synchronously committed and confirmed per partition. If persistence succeeds but offset acknowledgement fails, replay remains safe because insertion is idempotent on `event_id`.[7]

Transport policy is fail closed. `PLAINTEXT` is allowed only when the operator explicitly enables the localhost-only integration gate and every bootstrap address is loopback. Non-local runs require `SSL` or `SASL_SSL`, trusted CA material and environment-delivered SASL credentials. Reports hash broker, group and table references, record committed offsets and exclude payloads and credentials.[7]

The local broker test used `apache/kafka:4.3.1` at digest `sha256:77e3df9054047a88b520d0cc46e16696d3b22022e1d580aeccd2632df6532837`. Two independent consumer groups each reached offset `1` with lag `0`; the first inserted one event and the second reported one already-present event while the Delta table retained one row.

## Score effect and remaining 80% gates

The score is now **34.00%**. The increase is limited to 0.75 weighted points for shared Kafka/Delta integration, 1.50 points for S1’s durable PostgreSQL evidence substrate and 2.50 points for S6’s complete local Rust/Kafka/Delta path. Local conformance fixtures do not create agency, Ministry or operational-acceptance credit.

| Highest-impact remaining gate | Evidence still required |
|---|---|
| Ministry hybrid platform | Approved cloud/on-premises Kubernetes contexts, private networking, APISIX/OpenAppSec, Keycloak, Wazuh/OpenCTI/OpenSearch, KMS/secrets, Kafka/Temporal/Dapr, object storage, backup/restore, SLO and Kubecost evidence |
| S1 port workflow | Genuine NSW/PCS/agency sandbox, canonical mapping, Temporal exception/reconciliation, signed receipts and operational pilot acceptance |
| S2 intelligence | Approved maritime feeds, Flink event-time rules, Sedona spatial processing, analyst cases and quality/security acceptance |
| S3 finance | Legal authority, regulated institution, Mojaloop participant/switch, TigerBeetle model, reconciliation and disaster-recovery evidence |
| S4 credentials | Approved issuer/profile/status service, holder/verifier lifecycle, privacy controls and Ministry non-production tests |
| S5 traceability | Authoritative lot genealogy and split/merge contract, partner sandboxes, real records, recall/correction and disclosure tests |
| S6 target safety | Approved devices/gateway, device PKI, durable replay/sequence state, geofences/rules, Temporal response and owner acceptance |
| Administration acceptance | Ministry identity/APISIX deployment, reconciliation/revocation, browser/OIDC/accessibility and recovery acceptance |

## References

[1]: https://kafka.apache.org/community/downloads/ "Apache Kafka Downloads"
[2]: https://kafka.apache.org/41/getting-started/docker/ "Apache Kafka Docker Documentation"
[3]: https://json-schema.org/draft/2020-12 "JSON Schema Draft 2020-12"
[4]: https://github.com/munisp/blueeconomy-traceability/blob/395f134381c6/schemas/traceability-event.schema.json "Traceability Event Schema"
[5]: https://github.com/munisp/blueeconomy-traceability/blob/395f134381c6/src/blueeconomy_traceability/validate.py "Traceability Validator"
[6]: https://github.com/munisp/blueeconomy-data-platform/blob/7b169ea41f12/src/blueeconomy_data_platform/ingest.py "Governed Delta Ingestion"
[7]: https://github.com/munisp/blueeconomy-data-platform/blob/7b169ea41f12/src/blueeconomy_data_platform/kafka_ingest.py "Kafka-to-Delta Consumer"
[8]: https://github.com/munisp/blueeconomy/blob/81eb44661793/integration/local-safety-kafka-delta/run.sh "Rust-to-Kafka-to-Delta Conformance Runner"
