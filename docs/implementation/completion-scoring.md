# Evidence-Based Completion Scoring

## Purpose

This score measures implementation against the Unified Blue Economy Platform specification. It is intentionally **not** a measure of concept design, line count, repository count, mock demonstration or unverified vendor claim. A workstream receives credit only for the strongest evidence actually present.

| Evidence level | Credit within a workstream | Meaning |
|---|---:|---|
| Not started | 0% | No published implementation or test evidence. |
| Source foundation | 25% | Versioned source, contracts, dependency locks and deterministic unit/static validation exist. |
| Local open-source integration | 50% | Real local components interact through authentic protocols and durable stores; no external partner is represented as connected. |
| Ministry non-production integration | 75% | Actual Ministry-controlled integration environment, identity/API edge, observability and security tests have passed. |
| Operational acceptance | 100% | Accountable operational owner has accepted end-to-end workflow, recovery, security/privacy and data/partner evidence. |

## Workstream weights

| Workstream | Weight | Current pre-integration evidence | Basis |
|---|---:|---:|---|
| Shared platform, security, operations, data governance and Kubernetes | 15% | 60% | Contracts, GitOps locks and security controls exist; the official Apache Kafka broker now exchanges governed events with the Delta writer through two real consumer groups with confirmed offsets and replay idempotency. No hybrid cluster deployment or Ministry observability evidence exists. |
| S1: Port interoperability and trusted workflow | 15% | 35% | Immutable evidence controls and contracts exist; a real PostgreSQL integration now proves idempotent package creation, row immutability and one-terminal-decision enforcement. No NSW/PCS/agency adapter, exchange workflow or authoritative source is connected. |
| S2: Maritime domain intelligence | 15% | 20% | Lakehouse, geospatial component locks and telemetry integrity controls exist; no authorised feed, analyst casework or spatial intelligence workflow is connected. |
| S3: Maritime finance/CVFF operations | 15% | 15% | TigerBeetle client verifier and Helm design exist; no legal fund workflow, regulated institution, Mojaloop participant or ledger deployment is connected. |
| S4: Seafarer credential trust | 10% | 20% | Issuer/JWKS verifier exists; no approved issuer, credential profile or credential lifecycle is connected. |
| S5: Fisheries and aquaculture traceability | 10% | 25% | Versioned provenance-chain validation, complete-field chain digest, hash-locked dependencies, deterministic tests, strict static checks and security-audit evidence exist; no fisheries/aquaculture/custody source is connected. |
| S6: Inland waterway safety telematics | 10% | 50% | The Rust validator, official Kafka broker and governed Delta consumer now complete an authentic local protocol path with payload equality, two consumer-group commits and idempotent replay. No approved telemetry gateway, device identity, rules engine or safety response workflow is connected. |
| Central administration, Ministry portal and stakeholder onboarding | 10% | 50% after local integration | Real Go/PostgreSQL/Keycloak service and TypeScript portal exist. The local suite proved PostgreSQL persistence, distinct approval, Keycloak HTTPS service-account token acquisition, invitation delivery to real local SMTP, and Keycloak organization-group activation. |

## Scoring rule

The current weighted score is the sum of `workstream weight × evidence percentage`. It will be recalculated after each evidence-producing phase. The score cannot increase because a component merely builds; it must satisfy the evidence criteria above.

## Current weighted completion score: **34.00%**

The calculation is `(15×60 + 15×35 + 15×20 + 15×15 + 10×20 + 10×25 + 10×50 + 10×50) ÷ 100 = 34.00%`. The increase from 29.25% is limited to measured evidence: 0.75 points for Kafka-to-Delta shared integration, 1.50 points for the PostgreSQL evidence-store invariants, and 2.50 points for the complete local Rust-to-Kafka-to-Delta safety path. This remains a conservative source-and-local-integration score. It is **not** a production-readiness score, a partner-integration score, or an operational-acceptance score.

## Boundary

The completed local PostgreSQL–Keycloak, PostgreSQL evidence-store, Kafka-to-Delta and Rust-safety pipeline tests raise only their stated local evidence. They do not imply that the Ministry’s Keycloak, APISIX, Wazuh, OpenCTI, Kafka, Temporal, PostgreSQL, object store, partners, National Single Window, Mojaloop or TigerBeetle environments have been integrated or accepted.
