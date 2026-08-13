# Business-Rule Coverage Matrix

**Assessment basis:** published `main` source, local integration evidence, the Unified Blue Economy Platform specification, and authoritative IMO, W3C/OpenID, FAO, Mojaloop and TigerBeetle documentation. “Partial” means a real control exists but the business requirement is not complete end to end. “Not implemented” means there is no executable business path satisfying the acceptance condition.

## S1 — Port Interoperability and Trusted Workflow

| Requirement | Current executable evidence | Assessment |
|---|---|---|
| S1-FR-01 canonical port-call model | Common event envelope and generic evidence package only; no IMO port-call/ship-port canonical model or source mapping. | Not implemented |
| S1-FR-02 NSW/PCS/NPA adapters | No approved agency adapter, secure-file interface, API mapping, retry/replay or reconciliation implementation. | Not implemented |
| S1-FR-03 immutable exchange receipt | PostgreSQL evidence packages are immutable and idempotent, with one terminal validation decision; they do not cover every exchange state or create signed sender/receiver receipts. | Partial foundation |
| S1-FR-04 role-controlled status tracking | Portal lists runtime-configured services; there is no port-call/document status timeline. | Not implemented |
| S1-FR-05 exception cases | No S1 exception model, Temporal workflow, ownership, SLA or escalation. | Not implemented |
| S1-FR-06 source-preserving correction | Immutable source metadata prevents overwrite, but no correction/resubmission/version-mapping workflow exists. | Partial foundation |
| S1-FR-07 operational measures | No port timeliness/completeness/rejection/reconciliation dashboards or definitions. | Not implemented |
| S1-FR-08 partner sandbox/conformance | Local component tests exist, but no port-partner identity, sandbox or conformance certification. | Not implemented |

## S2 — Maritime Domain Intelligence

| Requirement | Current executable evidence | Assessment |
|---|---|---|
| S2-FR-01 approved multi-source ingestion | A bounded Kafka-to-Delta consumer and one local Rust telemetry path exist; no authorized maritime feeds or source-level agreements. | Partial foundation |
| S2-FR-02 canonical entity/event model | A generic governed event envelope and telemetry metadata exist; vessel/voyage/device/organization/location/incident/rule/evidence entity relationships do not. | Partial foundation |
| S2-FR-03 spatial/temporal quality | Timestamp ordering, input bounds and integrity checks exist; precision, gap, duplicate-position, late-arrival and identifier-resolution policies do not. | Partial foundation |
| S2-FR-04 restricted maps/timelines | No operational map, layer/field authorization or entity timeline. | Not implemented |
| S2-FR-05 versioned explainable rules/models | No Flink rule engine, model registry, alert feature explanation or human disposition path. | Not implemented |
| S2-FR-06 alert/incident lifecycle | No maritime intelligence incident workflow, tasking, escalation or recovery evidence. | Not implemented |
| S2-FR-07 controlled sharing/redaction | Data classifications and digested references exist; no policy-checked export/referral/revocation flow. | Partial control only |
| S2-FR-08 approved aggregate risk products | No governed risk methodology, aggregation product or release approval. | Not implemented |

## S3 — Maritime Finance and CVFF Operations

| Requirement | Current executable evidence | Assessment |
|---|---|---|
| S3-FR-01 versioned programme/product rules | No product, eligibility, authority-limit, fee or reporting configuration engine. | Not implemented |
| S3-FR-02 verified applicant/party/vessel onboarding | Stakeholder invitation/group activation exists, but no finance applicant, beneficial-owner, vessel, supplier or financial-partner verification. | Not implemented |
| S3-FR-03 segregated underwriting/approval | Generic onboarding maker/checker exists; no underwriting, quorum, delegation, conflict, ceiling or credit-decision workflow. | Not implemented |
| S3-FR-04 finance evidence controls | Generic immutable evidence metadata exists; no finance document access-purpose, legal-hold, tamper/download event or finance identity integration. | Partial foundation |
| S3-FR-05 idempotent payment instructions | No payment instruction, Mojaloop call, provider state machine, durable client-generated transfer ID or retry/ambiguity recovery. | Not implemented |
| S3-FR-06 balanced sub-ledger | The only TigerBeetle call is `LookupAccounts`; there is no account model, reserve/post/void/reversal/repayment/fee/adjustment transfer path. | Not implemented |
| S3-FR-07 reconciliation | No statement ingest, legal-account/provider/sub-ledger match, break queue, aging, ownership or recovery. | Not implemented |
| S3-FR-08 facility servicing | No facility, covenant, milestone, schedule or escalation model. | Not implemented |
| S3-FR-09 finance statements/reports | Read-only TigerBeetle evidence reports account metadata only; no legal/sub-ledger/pending/unreconciled statement model. | Not implemented |
| S3-FR-10 complaint/appeal/investigation | No finance appeal/correction/investigation workflow. | Not implemented |

## S4 — Seafarer Credential Trust

| Requirement | Current executable evidence | Assessment |
|---|---|---|
| S4-FR-01 issuer trust registry | Verifier accepts a caller-supplied HTTPS issuer and JWKS URL; no approved issuer registry, authority scope, status or expiry. | Not implemented |
| S4-FR-02 credential schema templates | No approved maritime credential schema catalogue or version governance. | Not implemented |
| S4-FR-03 authorized issuance/wallet | No issuer API, authorization workflow, holder binding, wallet or offline channel. | Not implemented |
| S4-FR-04 verification | Compact JWT signature, issuer, audience and standard JWT time claims are checked through remote JWKS; no VC conformance, issuer trust, credential status, requested-claim policy or presentation proof. | Partial foundation |
| S4-FR-05 status lifecycle | No suspension, revocation, correction, renewal, revalidation or status-list processing. | Not implemented |
| S4-FR-06 privacy/minimal disclosure | Evidence hashes token/subject and avoids claim persistence; no selective disclosure, verifier-purpose policy, bulk-enumeration control or access log. | Partial control only |
| S4-FR-07 training/certification ingest | No provider records, identity match, provenance, duplicate resolution or review. | Not implemented |
| S4-FR-08 fraud/integrity analytics | No issuer anomaly, QR replay, verification behavior or enrollment detection. | Not implemented |
| S4-FR-09 support/recovery/grievance | No lost-device recovery, step-up holder proof, re-key or grievance workflow. | Not implemented |

## S5 — Fisheries and Aquaculture Traceability

| Requirement | Current executable evidence | Assessment |
|---|---|---|
| S5-FR-01 versioned traceability profiles | One fixed Draft 2020-12 schema is runtime enforced; no species/product/market profiles, optional/mandatory variants or controlled exceptions. | Partial foundation |
| S5-FR-02 participant/asset/device registry | No participant, facility, vessel/farm, cold asset, device ownership, calibration or status service. | Not implemented |
| S5-FR-03 CTE capture/offline | Five event types can be validated from bounded NDJSON; no mobile/assisted capture, signatures, device ordering, offline conflict resolution or receipt. | Partial foundation |
| S5-FR-04 lot genealogy | Linear predecessor chains within one lot are checked; split, merge, transformation, multiple parents/children, quantities, units, yield/mass balance, custody and disposition are absent. | Partial and materially incomplete |
| S5-FR-05 cold-chain evaluation | No temperature/location/power/door/device-health model, calibration checks or Flink rules. | Not implemented |
| S5-FR-06 inspections/holds/recalls | No inspection authority, affected-descendant traversal, notifications, acknowledgements or corrective-action workflow. | Not implemented |
| S5-FR-07 methodology-governed dashboards | Validation evidence reports counts and a chain digest only; no loss/compliance methodology or dashboard. | Not implemented |
| S5-FR-08 controlled views | No B2B/regulator/consumer projection, field-level disclosure or export log. | Not implemented |
| S5-FR-09 partner onboarding/conformance | Runtime schema and deterministic tests exist; no partner identity, idempotent production publishing, sandbox or certification. | Partial foundation |

## S6 — Waterway Safety Telematics

| Requirement | Current executable evidence | Assessment |
|---|---|---|
| S6-FR-01 vessel/device/operator enrollment | No registry, authority verification, credential provisioning, assignment history or expiry service. | Not implemented |
| S6-FR-02 telemetry ingest | Rust validates bounded payload bytes, SHA-256, canonical identifiers and timestamp ordering; Kafka-to-Delta transport is real locally. Device signatures, sequence state, source authority, precision and multi-protocol gateways are absent. | Partial foundation |
| S6-FR-03 current/replay maps | Historical Delta row exists locally; no map, replay API, coverage/freshness/confidence display or authorization. | Not implemented |
| S6-FR-04 safety rules/geofences | No Flink rules, geofence store, rule version, severity/confidence or disposition lifecycle. | Not implemented |
| S6-FR-05 distress/notifications | No distress intake, redundant notification, acknowledgement, escalation or drill. | Not implemented |
| S6-FR-06 incident lifecycle | No Temporal incident workflow, tasks, evidence, referrals or closure. | Not implemented |
| S6-FR-07 operator acknowledgement | No operator notification/response model. | Not implemented |
| S6-FR-08 safety analytics | No hazard, near-miss, coverage or response analytics; only integrity/conformance evidence. | Not implemented |
| S6-FR-09 intermittent connectivity | Local Kafka replay and Delta idempotency are proven; no edge buffer, Fluvio bridge, durable device sequence reconciliation or manual/radio fallback test. | Partial foundation |

## Cross-cutting administration and platform controls

The central administration service has the most complete local lifecycle: PostgreSQL request/decision state, maker/checker denial, Keycloak organization invitation, group activation, SMTP delivery and idempotency assertions. It is still not production complete because target APISIX enforcement, real federation, revocation/deprovisioning, reconciliation after external-success/database-failure, operations SLOs and Ministry acceptance are absent.

Kafka and Delta have authentic local execution. Temporal, Dapr, Fluvio, Redis, Mojaloop, APISIX, open-appsec, Wazuh, OpenCTI, OpenSearch, Spark, Flink, Sedona, DataFusion, Ray and Kubecost are not demonstrated as deployed and integrated services. Source locks and architecture documents do not satisfy business acceptance conditions.
