# Current Implementation State

This record distinguishes **published source and deterministic local validation** from a real deployed, integrated or production-approved capability. No component in this table is represented as live without target-environment evidence.

| Repository | Published implementation | Verified locally | Real target required before live claim |
|---|---|---|---|
| `blueeconomy-contracts` | Versioned Protocol Buffers contracts for common metadata, maritime evidence, waterway safety and immutable audit events. | Contract descriptor validation. | Schema registry/topic and consumer-producer compatibility evidence. |
| `blueeconomy-platform-gitops` | Kubernetes base policy plus reproducible source lock for APISIX, OpenSearch, OpenCTI, Keycloak, Wazuh, Kafka, Temporal, Dapr and CloudNativePG. | Manifest/source-lock validation. | Ministry hybrid cluster, secrets, sizing, storage, network/TLS and approved component configuration. |
| `blueeconomy-security-operations` | Go read-only security endpoint/OIDC verifier with redacted evidence. | Go tests and static analysis. | Approved Keycloak, APISIX, Wazuh/OpenSearch and OpenCTI non-production endpoints/credentials. |
| `blueeconomy-data-platform` | Python real-input NDJSON validation and append-only Delta Lake ingestion. | Package/schema validation using installed Delta Lake and Parquet libraries. | Approved data source, object store/catalog and authorised non-production records. |
| `blueeconomy-maritime-evidence` | Go immutable evidence model and PostgreSQL migrations, including idempotency and one-terminal-decision invariant. | Go tests and static analysis. | Approved PostgreSQL/object store, identity/API edge and authorised evidence source. |
| `blueeconomy-waterway-safety` | Rust integrity validator that decodes real supplied telemetry bytes and verifies SHA-256, timestamps and classification. | Rust formatting, tests and linting. | Approved telemetry gateway/device identity/protocol, event path and safety workflow. |
| `blueeconomy-financial-controls` | Go read-only TigerBeetle verifier built against the official `v0.17.9` client. | Go build/static analysis and fail-closed missing-configuration execution. | Approved TigerBeetle cluster, financial data model, Mojaloop participant/switch, controls and non-production payment evidence. |

## Pending prerequisites

The programme has no authorised endpoint registry, cluster contexts, network routes, credentials, target-side data agreements or partner sandbox configuration attached to this task. The next genuine integration step is the Ministry-controlled non-production environment. Until it is supplied, source will continue to fail closed rather than use mock endpoints, fabricated data, default accounts, default participants or invented credentials.
