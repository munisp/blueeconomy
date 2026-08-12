# Bridge from 28.75% to a Defensible 80% Completion Score

## Target evidence mix

The score before this Rust/Python audit was **28.75%**. The audited traceability source foundation raises the current score to **29.25%**, leaving **50.75 additional weighted percentage points** to reach 80%. Under the published evidence rubric, the following target mix reaches **81.25%** without pretending that every service is already operationally accepted.

| Workstream | Weight | Current evidence | Target evidence | Weighted target contribution | Evidence required for target |
|---|---:|---:|---:|---:|---|
| Shared platform, security, operations, data governance and Kubernetes | 15% | 55% | 75% | 11.25 | Ministry non-production hybrid Kubernetes environment passes identity, network, observability, security, backup/recovery and cost-allocation tests. |
| S1 Port interoperability and trusted workflow | 15% | 25% | 100% | 15.00 | One accountable port/NSW/PCS operational owner accepts an end-to-end pilot with real exchanges, receipts, exceptions, recovery and audit evidence. |
| S2 Maritime domain intelligence | 15% | 20% | 75% | 11.25 | Ministry non-production integration with approved vessel/incident/geospatial feeds and analyst workflow passes security, provenance and quality tests. |
| S3 Maritime finance/CVFF operations | 15% | 15% | 75% | 11.25 | Regulated non-production workflow, TigerBeetle sub-ledger and Mojaloop/payment-participant sandbox reconcile against an authorised institution. |
| S4 Seafarer credential trust | 10% | 20% | 75% | 7.50 | Approved issuer, credential profile, status/revocation service and verifier are integrated in Ministry non-production. |
| S5 Fisheries and aquaculture traceability | 10% | 25% | 75% | 7.50 | Authorised harvest/landing/processing/custody records traverse the complete non-production traceability path. |
| S6 Inland-waterway safety telematics | 10% | 25% | 75% | 7.50 | Approved device/gateway feed, geofence/rule workflow and response case are integrated in Ministry non-production. |
| Central administration and Ministry portal | 10% | 50% | 100% | 10.00 | Ministry identity owner accepts onboarding, maker/checker approval, invitation, group activation, reconciliation, revocation, audit and recovery. |
| **Total** | **100%** | **29.25%** | — | **81.25%** | At least 80% is achieved only when the evidence above exists. |

This is not the only possible 80% mix, but it is the most coherent route because it puts the shared platform and every domain into an actual Ministry non-production environment while requiring operational acceptance for the central trust layer and one high-value business pilot.

## 1. Shared hybrid platform requirements

| Requirement group | Exact remaining components and configuration | Required evidence |
|---|---|---|
| Hybrid Kubernetes | A Ministry-controlled cloud cluster and on-premises/private-cloud cluster; supported Kubernetes versions; CNI; CSI storage classes; node pools; GPU policy if later required; namespaces; quotas; priority classes; disruption budgets; autoscaling; image registry; artifact retention; and a documented cross-site connectivity model. | Cluster inventory, version/support matrix, capacity baseline, failure-domain design, node/pod security evidence and signed ownership matrix. |
| Connectivity and edge | Private routing or approved VPN/SD-WAN, DNS, NTP, egress policy, inbound allowlists, mutual TLS trust, certificate issuance/rotation and approved connectivity to agency/partner sandboxes. | Packet-flow tests, DNS/TLS evidence, latency/loss baselines, route ownership and failover test. |
| GitOps and supply chain | Active CI credentials with workflow permission; protected branches; signed commits/tags; SBOM generation; dependency and image scanning; provenance/attestation; policy enforcement; promotion from development to non-production; rollback and release approval. | A release promoted through the real pipeline with signed provenance, scan results, approval and rollback evidence. |
| API and service integration | APISIX routes, OpenAppSec policy, Keycloak OIDC/mTLS, Dapr sidecars/components, rate limits, request-size limits, correlation IDs, standardized errors, API inventory and partner conformance harness. | Authenticated API test, malicious-request/WAF test, rate-limit test, correlation trace and conformance report. |
| Eventing and workflow | Strimzi/Kafka clusters and topics; schema compatibility policy; ACLs; dead-letter/retry/replay/reconciliation; Temporal namespaces, workers, task queues, visibility store and workflow versioning; Fluvio edge gateway where required. | Producer/consumer compatibility, restart/replay, poison-message, late-event and Temporal worker-failure tests. |
| Transactional data | CloudNativePG/PostgreSQL clusters; PostGIS where approved; PITR; encrypted backups; restore targets; connection pooling; role model; audit extension/policy; retention and legal hold. | Backup/restore test, RPO/RTO evidence, privilege test, failover and schema-migration rollback. |
| Lakehouse | Ministry object storage; Delta Lake catalogue and table ownership; Parquet conventions; bronze/silver/gold zones; Flink/Spark/Sedona execution; DataFusion/Ray workload boundaries; encryption keys; retention; quality contracts and lineage. | Real approved source ingested end to end, Delta history, quality report, lineage, access test and recovery/reprocessing result. |
| Security operations | Wazuh managers/indexers/agents, OpenSearch security domains, OpenCTI platform/connectors/feeds, Keycloak SSO for SOC, alert enrichment, incident workflow, time synchronization and evidence retention. | Endpoint/container alert, CTI enrichment, investigation, containment, chain-of-custody and recovery exercise. |
| Observability and FinOps | Metrics, logs, traces, SLO dashboards, alert routing, runbooks, on-call, Kubecost labels/allocations, shared/idle cost policy, budgets and anomaly alerts. | One service traced across edge/workflow/database, SLO alert exercise, monthly showback and resource-rightsizing decision. |
| Secrets and keys | An approved secret manager/KMS/HSM path, workload identity, short-lived credentials, encryption/signing key ownership, rotation, revocation and break-glass access. | Rotation drill, revoked-credential test, break-glass audit and key-custodian approval. |

## 2. Central administration and portal requirements

The local PostgreSQL–Keycloak integration proves protocol compatibility, but operational acceptance requires the real Ministry environment.

| Component | Exact requirement | Acceptance evidence |
|---|---|---|
| Keycloak | Ministry realm, organization model, portal client, service account, approved groups, role catalogue, MFA policy, session policy, identity federation, SMTP/invitation policy and service-account least privilege. | Identity-owner approval, invitation and activation tests with approved non-production stakeholders, access review and revocation test. |
| APISIX/OpenAppSec | Protected administration routes; the gateway must remove any client-supplied subject header and inject only verified identity; mTLS/service identity; rate/body limits; WAF policy. | Header-spoofing rejection, role-denial tests, mTLS evidence, WAF and rate-limit results. |
| PostgreSQL | High-availability database, backups/PITR, migration ownership, retention, decision-history export and restricted operator access. | Failover, restore, immutable-field test and audit export accepted by the identity owner. |
| Synchronization reliability | Durable reconciliation/outbox or equivalent idempotent mechanism for uncertain Keycloak outcomes; correlation identifiers; retry policy; manual repair procedure. | Induced post-Keycloak database failure followed by safe reconciliation without duplicate invitation or group assignment. |
| Portal | Production runtime configuration, CSP/security headers, OIDC login/logout/refresh, route authorization, onboarding status view, decision work queue, access review and accessibility validation. | Real browser/OIDC test, session expiry, unauthorized-route test, accessibility report and owner sign-off. |

## 3. S1 port interoperability and operational acceptance

| Area | Exact remaining requirement |
|---|---|
| Authoritative parties | Named Ministry/NPA/NSW/PCS and receiving-agency product owners, technical contacts, data owners and operational approvers. |
| Interfaces | Genuine non-production API/event/file endpoints; authentication certificates; source schemas; sample records approved for testing; status/acknowledgement codes; retry/reconciliation rules and maintenance windows. |
| Implementation | Canonical port-call model; source-to-canonical mappings; signed/hash receipts; immutable evidence packages; exception API and Temporal workflow; replay/reconciliation; audit export; status timeline and role-restricted portal view. |
| Tests | Schema/semantic conformance, duplicate/idempotency, unavailable receiver, retry/replay, source correction, cross-agency exception, access control, evidence export, performance, backup/restore and rollback. |
| Acceptance | A limited real pilot such as one port-call subset, one NSW/PCS route and approved receiving agencies; operational owner signs the SOP, support model, measured results and recovery evidence. |

## 4. S2 maritime domain intelligence requirements

| Area | Exact remaining requirement |
|---|---|
| Feeds and authority | Approved AIS/VMS/telemetry, weather/ocean, port, incident or other feed agreements; use purpose, licence, classification, retention and coverage limitations. |
| Data path | Authenticated ingest, Kafka topics, event-time/watermark policy, Flink rules, Delta tables, Sedona spatial joins, entity resolution, provenance and uncertainty metadata. |
| Analyst functions | Role-restricted map/timeline, alert explanation, analyst disposition, incident case, referral/redaction, after-action review and rule-quality feedback. |
| Security | Compartmented layers/indexes, export restrictions, device/session controls, security logging and controlled incident evidence. |
| Tests | Spoofed/duplicate/late/out-of-order observations, feed outage, geofence rule, false-positive disposition, classification denial, spatial accuracy and analyst recovery workflow. |

## 5. S3 maritime finance/CVFF requirements

| Area | Exact remaining requirement |
|---|---|
| Governance and legal | Written programme authority, regulated institution responsibilities, approved KYC/AML/sanctions boundary, chart of accounts, currencies, approval thresholds, segregation of duties, settlement finality and exception ownership. |
| TigerBeetle | Authorised non-production cluster, immutable cluster ID, account/ledger/code mapping, transfer flags, idempotency rules, backup/recovery design and access policy. |
| Mojaloop/payment rail | Approved Mojaloop switch or participant sandbox, participant identities, certificates, scheme rules, quote/transfer/error flows, settlement/reconciliation files and operational contacts. |
| Workflow | Application, evidence, eligibility, human underwriting, committee approval, reservation, instruction, posting, reconciliation, reversal, repayment/milestone and closure in Temporal. |
| Tests | Duplicate instruction, timeout/unknown, provider reject, reserve/commit/reverse, ledger/payment mismatch, maker/checker, limits, reconciliation, DR and audit statement. |
| Boundary | No live money, applicant decision, KYC/AML claim or statutory fund action until the authorized institution and programme owner accept the workflow. |

## 6. S4 credential trust requirements

| Area | Exact remaining requirement |
|---|---|
| Issuer | Authorised certifying authority, issuer keys/KMS, approved credential schema/profile, issuance eligibility, status/revocation endpoint and key-rotation policy. |
| Holder/verifier | Approved wallet/presentation format, relying-party registration, consent/minimization, verifier purpose and offline/degraded behavior. |
| Integration | Keycloak identity, training/certification source, credential issue/status APIs, QR/deep-link presentation and verifier audit. |
| Tests | Valid, expired, revoked, wrong issuer/audience, rotated key, replay, selective-disclosure/minimization where used and privacy/access review. |

## 7. S5 fisheries and aquaculture traceability requirements

| Area | Exact remaining requirement |
|---|---|
| Authoritative records | Approved harvest/farm, licence, landing, lot, processing, custody, cold-chain, inspection and export/compliance schemas and owners. |
| Partner environments | Landing-site, processor, logistics, laboratory/inspection and market/export sandbox interfaces with identity and connectivity. |
| Implementation | Lot genealogy, split/merge, custody transfer, handling/temperature evidence, exception/recall workflow, corrections, evidence export and quality dashboards. |
| Tests | Broken genealogy, duplicate lot, unauthorized custody change, late temperature event, split/merge balance, recall, source correction, offline sync and disclosure restriction. |

## 8. S6 inland-waterway safety requirements

| Area | Exact remaining requirement |
|---|---|
| Device and gateway | Approved device models/protocols, device identities/certificates, firmware ownership, telemetry gateway, message sequence, timestamp/coordinate precision and offline buffering policy. |
| Safety policy | Authoritative geofences, speed/proximity rules, severity thresholds, response owner, escalation ladder, emergency contacts and false-alert handling. |
| Integration | Fluvio/edge or approved gateway, Kafka, Rust integrity/normalization, Flink rules, Temporal incident workflow, geospatial store/lakehouse and portal map/case view. |
| Tests | Invalid signature/digest, replay, sequence gap, clock drift, coordinate anomaly, gateway outage, late delivery, geofence alert, operator acknowledgement, escalation and after-action evidence. |

## 9. Programme, data and acceptance requirements

| Control | Required item |
|---|---|
| Decision rights | Named Digital Steering Council, Platform Design Authority, Data Governance Council, Security/Resilience Forum and domain product owners. |
| Legal/privacy | Data-sharing agreements, controller/processor allocation, lawful purpose, DPIAs for high-risk processing, retention/legal-hold schedule, correction/appeal and cross-border/third-party assessment. |
| Data governance | Source-of-truth register, glossary, classifications, ownership/stewardship, quality thresholds, lineage, permitted uses and approved test-data handling. |
| Security assurance | Threat models, penetration test, dependency/container scans, Kubernetes posture, secrets/key review, incident tabletop and recovery exercise. |
| Operations | SLOs, support hours, incident severity model, runbooks, on-call, service catalogue, capacity plan, vendor/community support and exit/portability test. |
| Acceptance | Signed acceptance criteria, real evidence bundle, defect/waiver register, training, SOP, operational readiness review and pilot go/no-go record for each workstream. |

## 10. Required environment registry

The next execution step is a securely delivered registry containing, for every target service: environment name; owner; base URL or Kubernetes context; network route; authentication method; secret-delivery path; certificate authority; tenant/realm/participant; approved roles; test-data authority; maintenance window; logging/SOC destination; and technical contact. Credentials must not be committed to Git or pasted into ordinary chat.

## References

[1]: https://kubernetes.io/docs/home/ "Kubernetes Documentation"
[2]: https://www.keycloak.org/documentation "Keycloak Documentation"
[3]: https://apisix.apache.org/docs/ "Apache APISIX Documentation"
[4]: https://docs.mojaloop.io/ "Mojaloop Documentation"
[5]: https://docs.tigerbeetle.com/ "TigerBeetle Documentation"
[6]: https://www.imo.org/en/ourwork/facilitation/pages/maritimesinglewindow-default.aspx "IMO Maritime Single Window"
