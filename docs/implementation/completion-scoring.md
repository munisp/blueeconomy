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
| Shared platform, security, operations, data governance and Kubernetes | 15% | 55% | Contracts, GitOps locks, security verifier, Delta Lake ingestion and validation exist; no hybrid cluster deployment or Ministry observability evidence exists. |
| S1: Port interoperability and trusted workflow | 15% | 25% | Immutable evidence controls and contracts exist; no NSW/PCS/agency adapter or source exchange is connected. |
| S2: Maritime domain intelligence | 15% | 20% | Lakehouse, geospatial component locks and telemetry integrity controls exist; no authorised feed, analyst casework or spatial intelligence workflow is connected. |
| S3: Maritime finance/CVFF operations | 15% | 15% | TigerBeetle client verifier and Helm design exist; no legal fund workflow, regulated institution, Mojaloop participant or ledger deployment is connected. |
| S4: Seafarer credential trust | 10% | 20% | Issuer/JWKS verifier exists; no approved issuer, credential profile or credential lifecycle is connected. |
| S5: Fisheries and aquaculture traceability | 10% | 20% | Real-record provenance-chain validation exists; no fisheries/aquaculture/custody source is connected. |
| S6: Inland waterway safety telematics | 10% | 25% | Rust payload-integrity validation exists; no telemetry gateway, device identity or safety response workflow is connected. |
| Central administration, Ministry portal and stakeholder onboarding | 10% | 50% after local integration | Real Go/PostgreSQL/Keycloak service and TypeScript portal exist. The local suite proved PostgreSQL persistence, distinct approval, Keycloak HTTPS service-account token acquisition, invitation delivery to real local SMTP, and Keycloak organization-group activation. |

## Scoring rule

The current weighted score is the sum of `workstream weight × evidence percentage`. It will be recalculated after each evidence-producing phase. The score cannot increase because a component merely builds; it must satisfy the evidence criteria above.

## Current weighted completion score: **28.75%**

The calculation is `(15×55 + 15×25 + 15×20 + 15×15 + 10×20 + 10×20 + 10×25 + 10×50) ÷ 100 = 28.75%`. This is a conservative source-and-local-integration score. It is **not** a production-readiness score, a partner-integration score, or an operational-acceptance score.

## Boundary

The completed local PostgreSQL–Keycloak integration raises only the **central administration** workstream to local-open-source integration evidence. It does not imply that the Ministry’s Keycloak, APISIX, Wazuh, OpenCTI, Kafka, Temporal, PostgreSQL, object store, partners, National Single Window, Mojaloop or TigerBeetle environments have been integrated or accepted.
