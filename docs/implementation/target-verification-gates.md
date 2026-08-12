# Target-Side Verification Gates

> **Status:** No gate in this document is complete in the current workspace. Source-level tests do not prove a target deployment, a partner integration, a payment path, an identity flow, operational resilience or production readiness.

## Evidence rules

Each gate must run in the approved Ministry-controlled non-production hybrid environment using authorised identities, endpoints, certificates, data agreements and change records. Evidence must contain the target identifier, UTC execution time, tool/release version, approver, redacted result and retained artefact location. It must not contain secrets, raw tokens, payment data, personal records, restricted intelligence, raw device payloads or unredacted operational evidence.

| Gate | Real dependencies | Required evidence | Promotion block |
|---|---|---|---|
| Kubernetes/GitOps | Approved cloud/on-prem contexts, namespaces, storage classes, network/TLS/secret policy and component source lock. | Rendered manifests, admission-policy result, workload readiness, image/source digest, network-policy test and rollback result. | No deployment or promotion. |
| Keycloak/API edge | Actual OIDC realm/client, APISIX route inventory, certificates, scopes/audiences and test roles. | Discovery/JWKS validation, authorization-code sign-in, token audience/scope proof, route allow/deny proof and redacted audit event. | No portal/API access claim. |
| Security operations | Wazuh, OpenSearch, OpenCTI, approved feeds and incident workflow. | Endpoint verifier output, agent/workload telemetry, alert enrichment, case ownership and reviewed response drill. | No SOC coverage claim. |
| Eventing/workflow/lakehouse | Kafka, Temporal, Dapr, PostgreSQL/object store/catalog and approved source records. | Authenticated produce/consume result, workflow completion/retry/recovery proof, append-only Delta check, lineage and restore evidence. | No data-pipeline claim. |
| Maritime evidence | PostgreSQL, approved object store, evidence source, OIDC/API edge and operator role. | Migration execution, immutable-row rejection, object digest match, idempotency test and authorized retrieval/audit proof. | No evidence-service claim. |
| Waterway safety | Actual gateway/device identity, approved telemetry protocol, event topic, safety workflow and operator role. | Genuine record integrity result, source ordering/deduplication result, alert/case workflow evidence and recovery handling. | No safety-telemetry claim. |
| Financial controls | TigerBeetle cluster/account model, Mojaloop switch/participants, certificates, payment rulebook and financial approval. | Read-only verifier result, reconciliation control, maker/checker evidence, positive/negative payment conformance and settlement/compensation proof. | No financial write path. |
| Credentials | Authorised issuer/JWKS, credential profile, holder/relying-party test identities and revocation/status policy. | Signed credential verification, expired/revoked/incorrect audience rejection, holder/relying-party authorization and privacy review. | No credential claim. |
| Traceability | Approved harvest/landing/processing/custody interfaces and traceability data agreement. | Real chain validation, cross-lot/orphan rejection, source reconciliation, retention/access policy and partner acceptance evidence. | No traceability-service claim. |
| Ministry portal | Registered portal client, real runtime config, APISIX routes, approved test users/roles and CSP/TLS policy. | Sign-in/sign-out, token/session handling, configured endpoint probe, role-denied route result, accessibility/security review and rollback proof. | No UI release. |

## Resilience and recovery requirements

After functional evidence, the Ministry must approve and run fault, restore and performance exercises that use the real non-production topology. These exercises include loss of a Kubernetes worker/failure domain, database restore to the defined recovery objective, Kafka/Temporal workflow interruption and retry, OpenSearch/Wazuh retention continuity, object-storage access failure, rotated OIDC signing key/certificate and revoked role/access response. Each exercise must establish a measurable outcome from the authorised resilience target rather than a simulated success assertion.

## Release decision

A release candidate is eligible for a Ministry production decision only when the relevant gates are complete, security and data owners approve the evidence, unresolved high-risk findings have an approved disposition, change/rollback documentation is complete and the production target matches the reviewed non-production configuration through controlled infrastructure-as-code promotion.
