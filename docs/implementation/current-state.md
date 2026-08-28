# Current Implementation State

**Date:** 2026-08-28

This record is regenerated from the actual workspace: nineteen programme repositories checked out as sibling directories, each summarised from its README and source on the checked-out branch. It distinguishes **published source and deterministic local validation** from a deployed, integrated or production-approved capability. No repository listed here is represented as live in a Ministry or partner environment; every service fails closed without approved target-environment configuration.

## Repository inventory

| Repository | Checked-out branch | Platform role |
|---|---|---|
| `blueeconomy` | `main` | Programme governance and bootstrap (meta) |
| `blueeconomy-administration-service` | `feature/enrollment-journeys` | Onboarding, enrollment and privacy-workflow backend |
| `blueeconomy-beneficiary-portal` | `main` | CVFF beneficiary self-service portal |
| `blueeconomy-contracts` | `feature/phase2-contracts` | Authoritative versioned protobuf contracts |
| `blueeconomy-credential-verification` | `feature/coc-wallet-vc2` | Seafarer CoC verifiable-credential issuer/verifier |
| `blueeconomy-data-platform` | `feature/cloud-agnostic-phase2` | Governed lakehouse ingestion |
| `blueeconomy-developer-platform` | `fix/reusable-workflow-truthfulness` | Reusable CI workflows and repository governance |
| `blueeconomy-ferry-ticketing` | `feature/signed-tickets` | Workstream B: ferry e-ticketing and passenger manifests |
| `blueeconomy-financial-controls` | `feature/cvff-four-party-rail` | Ledger boundary and CVFF four-party disbursement rail |
| `blueeconomy-fisheries-traceability` | `main` | Workstream E: catch-to-export traceability and cold chain |
| `blueeconomy-maritime-evidence` | `feature/azure-gov-storage` | Immutable maritime evidence persistence |
| `blueeconomy-maritime-intelligence` | `feature/deep-blue-isr` | Incident lifecycle and Workstream F ISR analytics |
| `blueeconomy-ministry-portal` | `main` | Ministry service-entry portal |
| `blueeconomy-mobile` | `feature/api-contract-fixes` | Offline-first field-operations app |
| `blueeconomy-platform-gitops` | `feature/phase2-layer` | Kubernetes policy, charts, source locks, Argo CD layer |
| `blueeconomy-port-interoperability` | `feature/ecallup-booking-service` | Workstream A: port-call workflow and eCallUp 2.0 booking |
| `blueeconomy-security-operations` | `feature/envelope-contract-alignment` | Security policy, detection engineering, integration verification |
| `blueeconomy-waterway-safety` | `feature/corridor-safety-hardening` | Rust telemetry-integrity and signed-device validation |

`munisp/singlewindow` (branch `main`) is also present in the workspace as a **reviewed domain-donor**, not a programme repository: it is the TradeGateway™ NGSWTP trade-facilitation single window whose declaration-engine domain material was imported into `blueeconomy-port-interoperability`. The fit review and gap analysis is retained in `SINGLEWINDOW_REVIEW.md` at the review-workspace root.

## Per-repository state

### `blueeconomy` (meta)

The governance and bootstrap repository for the Ministry's Unified Blue Economy Platform. It records architecture decisions, repository strategy, integration gates, completion scoring, audit evidence registers and release baselines; it is deliberately not a monorepo for production services and must not contain production or partner secrets, kubeconfigs, credentials or personal records. Its own most recent work adds air-gapped revocation chaos test cases. On `main`.

### `blueeconomy-administration-service`

Go/PostgreSQL approval-controlled backend for Ministry user and stakeholder onboarding. It stores onboarding requests and decisions only (Keycloak remains the authoritative identity system), enforces its own service-side authorization in both `jwt` and `trusted_proxy` modes with a default-deny route table over eight approved realm roles, and now includes the enrollment-journeys surface on the checked-out branch: self-service enrollment with rate-limited public submission, officer KYC identity proofing that records a SHA-256 digest of the document reference rather than the raw number, and agent-assisted batches (1–500 rows) with database-enforced proposer ≠ confirmer dual control, plus the privacy processing-activity workflow with independent DPO decision. On `feature/enrollment-journeys`.

### `blueeconomy-beneficiary-portal`

TypeScript/React self-service portal for vessel operators applying for CVFF loans: OIDC Authorization Code + PKCE sign-in, an application dashboard with status badges mapped one-to-one to the backend state machine and per-tier underwriting SLA countdowns (PRIMARY 5 / SECONDARY 3 / TERTIARY 2 business days, mirroring `internal/cvff` in financial-controls), a new-application wizard with IMO check-digit validation, idempotency-keyed submission and document upload, and four-party approval-chain status tracking with bounded backoff polling that stops on terminal states. It is runtime-configured via a fail-closed `/platform-config.json` and contains no seeded users, mock data or default endpoints. On `main`.

### `blueeconomy-contracts`

The authoritative source for versioned API, event, identity-claim and data-product contracts — protobuf only, no endpoints or credentials. The checked-out branch adds the Phase-2 domain contracts: the FHIR R4-aligned `EventEnvelope` integration backbone (with `google.protobuf.Any` resources, detached-signature provenance and a `FIDUCIARY_SEGREGATED` classification for CVFF flows) plus workstream contracts for e-Call-Up (A), ferry manifests (B), CVFF (C), seafarer credentials (D), fisheries/cold-chain/export (E) and ISR (F), alongside the common, audit, evidence, safety and mobile-observation boundaries. Validation covers protoc descriptor compilation, Buf `STANDARD` lint/format/breaking checks, a `buf generate` freshness gate and a generated-Go compile gate. On `feature/phase2-contracts`.

### `blueeconomy-credential-verification`

TypeScript seafarer Certificate of Competency wallet credentialing: a W3C Verifiable Credentials Data Model 2.0 **issuer and offline-capable verifier** for NIMASA-issued, STCW-aligned CoC credentials — it is no longer a stateless JWT verifier. It issues credentials with Data Integrity proofs (eddsa-jcs-2022: JCS canonicalization, SHA-256, Ed25519, multibase proofValue), stores holder-bound credentials, and revokes via W3C Bitstring Status List v1.0 whose signed snapshot is served at `GET /v1/status-list/{id}` with revocations pushed to wallets as `seafarer.revocation.v1` events. Issuance is gated on the Temporal `SeafarerCredentialWorkflow` lifecycle (`exam-registration → exam-result → training-completion → credential-eligibility → issuance`) with SLA timers and the `nimasa-approver` role; the checked-out branch adds the wallet/issuer-key read surface (`GET /v1/wallet/credentials/current`, `GET /v1/issuers/{issuer}/key`) and status-list identity work. On `feature/coc-wallet-vc2`.

### `blueeconomy-data-platform`

Python governed ingestion for the platform lakehouse: `blueeconomy-ingest-events` validates an explicitly supplied real-source NDJSON file against the committed event-envelope schema and writes append-only to Delta Lake with `event_id`-keyed idempotent insertion; `blueeconomy-ingest-kafka` consumes with auto-commit disabled, persists then synchronously commits offsets so replays stay idempotent. Reports are secret-safe (hashed source/table references). The checked-out branch carries the cloud-agnostic Phase-2 work including the canonical envelope schema and S2 GeoJSON geofence evaluation. On `feature/cloud-agnostic-phase2`.

### `blueeconomy-developer-platform`

Reusable, language-specific build and assurance workflows (Go, Rust, Python, TypeScript) consumed via `workflow_call`, standardising dependency lockfiles, race-enabled tests, lint, vulnerability scanning, SPDX SBOM generation and verified-secret scanning. All third-party actions are pinned to full commit SHAs; the govulncheck install is pinned to a released version. Tool steps skip only when the tool or its manifest is genuinely absent — the Python workflow splits manifest detection from execution so a present-but-failing install or compile fails the run. The `ci/github-actions/` template copies are CI-enforced byte-identical to the installed workflows by `repository-governance.yml`. On `fix/reusable-workflow-truthfulness`.

### `blueeconomy-ferry-ticketing`

Go service for Workstream B: NGN-denominated per-passenger e-ticketing with DB-enforced capacity (no overbooking by construction), two-phase reserve/post fare settlement on TigerBeetle, FHIR-aligned anonymized NIMASA/NIWA passenger manifests, and a transactional outbox publishing every state change to `ferries.ticketing.v1`/`ferries.manifest.v1` with the platform envelope. Issued tickets are Ed25519-signed, QR-encodable artifacts with a TOTP-style rotating anti-screenshot window code, verified offline against a distributed public key set (the checked-out branch adds the verification-keys distribution endpoint) and consumed first-scan-wins in PostgreSQL. Processes refuse to start without PostgreSQL, TigerBeetle, the manifest salt, an explicit auth mode and the completeness KPI. On `feature/signed-tickets`.

### `blueeconomy-financial-controls`

Go financial boundary: real TigerBeetle integration (account creation, two-phase pending/post/void transfers), durable financial intent with maker/checker approval in PostgreSQL, statement reconciliation that fails closed on discrepancies, and a protocol-grounded Mojaloop FSPIOP adapter with signed quotes/transfers/callbacks. It is no longer a read-only verifier: `internal/cvff` implements the full **CVFF four-party disbursement rail** as a state machine (`SUBMITTED → three PLI underwriting tiers at 50/35/15 → NIMASA_APPROVAL → BANK_CONFIRMATION → DISBURSEMENT_PENDING → DISBURSED → AUDITED`, with fail-closed `REJECTED`/`RECONCILIATION_REQUIRED` branches), database-enforced separation of duties, immutable approval entries and per-tier business-day SLAs that escalate but never auto-approve. The branch adds the Temporal `CVFFDisbursementWorkflow`, dual-control CBN FX reference-rate capture, dual-ledger NGN/USD pass-through postings, outbox publication as `FIDUCIARY_SEGREGATED` envelope events, and the beneficiary-facing CVFF applications API consumed by the beneficiary portal. On `feature/cvff-four-party-rail`.

### `blueeconomy-fisheries-traceability`

Workstream E: end-to-end fisheries and aquaculture traceability from catch to export. Idempotency-keyed catch entry (offline-created catches accepted as `PENDING_SYNC` and reconciled on reconnect, conflicts to `REVIEW_REQUIRED`), gateway-authenticated Ed25519-signed cold-chain telemetry with a species/handling-profile breach detector (FMMA-visible alerts, KPI ≤ 60 s detection latency), a Temporal `ChainOfCustodyWorkflow` from catch through landing, transit, processor and exporter to import receipt with fail-closed `HOLD` on quantity divergence, TigerBeetle double-entry attestation per traceability event, per-tonnage NGN fees, and export consignment bundling with fraud flags. On `main`.

### `blueeconomy-maritime-evidence`

Go/PostgreSQL immutable maritime evidence persistence: `evidence_packages` protected against update/delete by database trigger, append-only validation history, idempotent creation on caller UUID, and domain-layer rejection of absent provenance, malformed digests, insecure content locations and invalid validation transitions. Raw evidence stays in an approved object store; the service keeps only SHA-256 digests and credential-free locations. The checked-out branch adds the Azure Government posture: `abfs://` ADLS Gen2 `usgovcloudapi.net` content locations accepted, `s3://` deprecated and rejected unless an explicit legacy-migration flag is set, with a matching `NOT VALID` database constraint. On `feature/azure-gov-storage`.

### `blueeconomy-maritime-intelligence`

Go/PostgreSQL maritime-intelligence incident lifecycle (version-checked `OPEN → … → CLOSED` transitions, exact idempotent replay, Ed25519-signed feed admission with revocation and bounded-grace key rotation, append-only outbox) plus Workstream F Deep Blue Project ISR analytics under national-security control: mandatory classification labels enforced at validation, service and DB-CHECK layers with clearance-constrained reads, multi-modal signed detection ingest (AIS, SAR, RF, acoustic, optical), track fusion by MMSI or spatial-temporal correlation, behaviour anomaly rules (dark vessel, speed outlier, rendezvous, loitering), a Temporal ISR response workflow and a dual-control TigerBeetle outcome ledger. The checked-out branch carries Deep Blue ISR restart, scanner and envelope fixes. On `feature/deep-blue-isr`.

### `blueeconomy-ministry-portal`

TypeScript/React Ministry entry portal: OIDC sign-in, central stakeholder request form against the administration service, a service-entry directory and a real-endpoint probe client. Runtime-configured through a fail-closed `/platform-config.json`; it ships no seeded users, sample vessels, mock payments, synthetic telemetry or default API addresses. On `main`.

### `blueeconomy-mobile`

Offline-first React Native (Expo SDK 52, strict TypeScript) field-operations app: one Keycloak OIDC login fronting six role-aware modules — trucker eCallUp booking/queue/gate status with journaled idempotency-keyed sync, ferry passenger tickets with QR of the signed artifact, fully offline gate/inspector Ed25519 verification against cached public keys, seafarer CoC wallet with offline eddsa-jcs-2022 verification against cached status-list snapshots, offline catch entry with `PENDING_SYNC` reconciliation, and cached CVFF beneficiary timelines. The checked-out branch aligns the wallet status-list fetcher with the singular API contract. Native binaries are produced via EAS Build; tests, typecheck and lint run locally and in CI. On `feature/api-contract-fixes`.

### `blueeconomy-platform-gitops`

Non-secret Kubernetes policy, source locks and deployment-source declarations for the hybrid platform, reconciled by Argo CD (pinned in the upstream-components lock). The Phase-2 layer on the checked-out branch versions workstream service charts (ferry-ticketing, port-interoperability, financial-controls, security-operations) with fail-closed values, digest-pinned images, restricted PSA, default-deny NetworkPolicies and ExternalSecrets-only credentials, plus the fisheries gateway role and PKCE public-client additions, alongside the TigerBeetle StatefulSet pattern, Mojaloop release-control overlay and Sedona Spark job pattern. Charts fail rendering when required approved environment values are absent; a rendered manifest is not represented as a deployment. On `feature/phase2-layer`.

### `blueeconomy-port-interoperability`

Go/PostgreSQL service implementing the S1 port-call workflow and the eCallUp 2.0 per-truck port access booking service: HS256 gateway-token authentication with tenant middleware and row-level security on every store, NSW authority ingestion of port calls via RS256 JWS with pinned JWKS and a replay store, transactional outbox events to Kafka, Temporal orchestration, a Mojaloop NGN payment boundary and a TigerBeetle double-entry settlement ledger. The checked-out branch hardens the booking worker with a multi-tenant call-up sweeper. The declaration-engine domain material imported from the reviewed `singlewindow` donor informs its customs/declaration surface; it does not claim IMO Maritime Single Window or partner conformance without approved interface profiles. On `feature/ecallup-booking-service`.

### `blueeconomy-security-operations`

Non-secret security-operating policy, role-model requirements, threat-intelligence curation rules, detection-engineering lifecycle controls and runbooks, plus two Go components: the read-only `integration-verifier` that validates only explicitly authorised non-production endpoints and emits redacted evidence, and `cmd/detection-engine`, which consumes the platform event envelope from the `ports.*`/`ferries.*`/`cvff.*` Kafka topics and generates correlated OpenCTI + Wazuh detection signals across workstreams with durable PostgreSQL window state. The checked-out branch aligns the envelope consumer with the platform contract. On `feature/envelope-contract-alignment`.

### `blueeconomy-waterway-safety`

Unsafe-free Rust telemetry-integrity validator and signed-device validation path: strict RFC 3339 timestamp ordering, canonical device/gateway identifiers, base64 and real-byte SHA-256 verification, a versioned device registry enforcing registered device/gateway/key tuples and Ed25519 domain-separated signature verification, emitting redacted metadata only. The checked-out branch adds the vessel-side edge gateway with buffered intermittent connectivity — the signed-frame pattern reused shore-side by the fisheries cold-chain path. It has no default gateway, device, certificate, topic, database or geofence. On `feature/corridor-safety-hardening`.

## Boundary

Local verification across the workspace uses real PostgreSQL, Keycloak, SMTP, Kafka, Temporal, TigerBeetle and Delta Lake interactions where each repository documents them, but these do not replace agency sources or Ministry environments. The programme still has no authorised endpoint registry, cluster contexts, network routes, credentials, target-side data agreements or partner sandbox configuration attached to this task. No component above is represented as live without target-environment evidence; source continues to fail closed rather than use assumed endpoints, fabricated agency data, default participants or invented credentials.
