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
| S2: Maritime domain intelligence | 15% | 35% | Real maritime-position validation and authenticated PostgreSQL incident lifecycle with source-event idempotency, transitions and outbox evidence exist. No authorised feed or analyst acceptance exists. |
| S3: Maritime finance/CVFF operations | 15% | 30% | Real TigerBeetle account/pending/post/void primitives and PostgreSQL financial-intent maker/checker, ambiguity and outbox controls exist. No approved ledger deployment, Mojaloop participant, settlement or regulated operating approval exists. |
| S4: Seafarer credential trust | 10% | 25% | Real JWT/JWKS verification with explicit algorithm allowlisting and protected evidence output exists. No approved issuer or credential lifecycle partner exists. |
| S5: Fisheries and aquaculture traceability | 10% | 30% | Runtime schema enforcement, chain digest, custody transitions and recall validation exist. No custody source, split/merge genealogy or operational recall integration exists. |
| S6: Inland waterway safety telematics | 10% | 50% | The Rust validator, official Kafka broker and governed Delta consumer now complete an authentic local protocol path with payload equality, two consumer-group commits and idempotent replay. No approved telemetry gateway, device identity, rules engine or safety response workflow is connected. |
| Central administration, Ministry portal and stakeholder onboarding | 10% | 60% | Real PostgreSQL/Keycloak/SMTP lifecycle, verified caller boundary and durable Keycloak side-effect evidence exist. No Ministry Keycloak/APISIX deployment or operational acceptance exists. |

## Scoring rule

The current weighted score is the sum of `workstream weight × evidence percentage`. It will be recalculated after each evidence-producing phase. The score cannot increase because a component merely builds; it must satisfy the evidence criteria above.

## Current weighted completion score: **43.50%**

The current calculation is `(15×65 + 15×50 + 15×35 + 15×30 + 10×25 + 10×30 + 10×50 + 10×60) ÷ 100 = 43.50%`. The previous 34.00% score remains the historical pre-increment baseline. The new score credits only real source and local integration evidence from the authenticated port-call service, maritime incident service, durable financial-intent store, TigerBeetle primitives, maritime-position validation and hardened shared controls. It is **not** a production-readiness score, a partner-integration score, or an operational-acceptance score.

## Boundary

The completed local PostgreSQL–Keycloak, PostgreSQL evidence-store, PostgreSQL port-call, PostgreSQL maritime-intelligence, PostgreSQL financial-intent, Kafka-to-Delta and Rust-safety pipeline tests raise only their stated local evidence. They do not imply that the Ministry’s Keycloak, APISIX, Wazuh, OpenCTI, Kafka, Temporal, PostgreSQL, object store, partners, National Single Window, Mojaloop or TigerBeetle environments have been integrated or accepted.
