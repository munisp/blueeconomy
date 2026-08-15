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

| Workstream | Weight | Post-implementation evidence | Basis |
|---|---:|---:|---|
| Shared platform, security, operations, data governance and Kubernetes | 15% | 65% | Real authentication hardening, durable external-operation records, source-locked GitOps and Kafka-to-Delta controls exist. No hybrid cluster deployment or Ministry observability evidence exists. |
| S1: Port interoperability and trusted workflow | 15% | 50% | Real authenticated PostgreSQL-backed port-call state machine, idempotency/conflict control, optimistic transitions, transactional outbox and OpenAPI contract exist. No NSW/PCS/agency adapter is connected. |
| S2: Maritime domain intelligence | 15% | 45% | Real maritime-position validation, strict GeoJSON Polygon/MultiPolygon geofence evaluation, authenticated PostgreSQL incident lifecycle, durable spatial-correlation evidence with exact replay/conflict control, maker-checker analyst assignment, transitions and outbox evidence exist. No authorised feed, Sedona/PostGIS deployment, escalation/notification integration or analyst acceptance exists. |
| S3: Maritime finance/CVFF operations | 15% | 45% | Real TigerBeetle account/pending/post/void primitives, PostgreSQL financial-intent maker/checker and ambiguity/outbox controls, PostgreSQL-backed external statement reconciliation, signed FSPIOP outbound client, callback HTTP boundary and durable PostgreSQL callback state exist. No approved ledger deployment, connected participant/switch, settlement authority or regulated operating approval exists. |
| S4: Seafarer credential trust | 10% | 50% | Real JWT/JWKS verification with explicit algorithm allowlisting, protected evidence output, mandatory JTI hash evidence and a local append-only signed status registry with active/suspended/revoked lifecycle, sequence integrity and tamper verification. No approved issuer, Ministry status endpoint or credential lifecycle partner exists. |
| S5: Fisheries and aquaculture traceability | 10% | 35% | Runtime schema enforcement, chain digest, custody transitions, recall validation and explicit split/merge genealogy exist. No custody source or operational recall integration exists. |
| S6: Inland waterway safety telematics | 10% | 50% | The Rust validator, official Kafka broker and governed Delta consumer now complete an authentic local protocol path with payload equality, two consumer-group commits and idempotent replay. No approved telemetry gateway, device identity, rules engine or safety response workflow is connected. |
| Central administration, Ministry portal and stakeholder onboarding | 10% | 60% | Real PostgreSQL/Keycloak/SMTP lifecycle, verified caller boundary and durable Keycloak side-effect evidence exist. No Ministry Keycloak/APISIX deployment or operational acceptance exists. |

## Scoring rule

The current weighted score is the sum of `workstream weight × evidence percentage`. It will be recalculated after each evidence-producing phase. The score cannot increase because a component merely builds; it must satisfy the evidence criteria above.

## Current weighted completion score: **50.25%**

The current calculation is `(15×65 + 15×50 + 15×45 + 15×45 + 10×50 + 10×35 + 10×50 + 10×60) ÷ 100 = 50.25%`. The previous 48.25% score remains the historical pre-S4-registry baseline; 47.50% remains the historical pre-S2-casework baseline, 46.75% remains the pre-S2 geofence baseline, 44.75% remains the pre-Mojaloop/JTI baseline, 44.00% remains the post-genealogy baseline, 43.50% remains the prior pre-genealogy baseline, and 34.00% remains the prior major baseline. The new 2.00-point increase credits only the real signed local credential-status registry and its filesystem/cryptographic lifecycle tests. S2 outbox lease code is not credited as Kafka integration until an authentic broker test is recorded. It is **not** a production-readiness score, a partner-integration score, or an operational-acceptance score.

## Boundary

The completed local PostgreSQL–Keycloak, PostgreSQL evidence-store, PostgreSQL port-call, PostgreSQL maritime-intelligence casework, PostgreSQL financial-intent, PostgreSQL statement-reconciliation, Kafka-to-Delta, Rust-safety and traceability genealogy tests raise only their stated local evidence. They do not imply that the Ministry’s Keycloak, APISIX, Wazuh, OpenCTI, Kafka, Temporal, PostgreSQL, object store, partners, National Single Window, Mojaloop or TigerBeetle environments have been integrated or accepted.
