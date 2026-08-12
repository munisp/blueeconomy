# Central Administration Review and Multi-Language Test Evidence

## Reviewed implementation

The review covered the Go central administration service, including `internal/admin/http.go`, `internal/admin/store.go`, `internal/admin/model.go`, `internal/admin/keycloak.go`, `internal/admin/config.go`, `db/migrations/0001_onboarding.sql` and `db/migrations/0002_activation.sql`.

| Area | Verified behavior | Review outcome |
|---|---|---|
| API boundary | The service accepts only authenticated-subject requests, rejects unknown JSON fields and now rejects trailing JSON documents. | Corrected and covered by deterministic `http_test.go` cases. The API-edge header remains a target-environment trust boundary: APISIX must remove any client-supplied subject header and inject only verified OIDC identity. |
| Approval policy | Submit validation requires the configured Keycloak organization and declared role catalogue. Approval denies maker/checker self-approval. | Verified by Go policy tests. |
| PostgreSQL lifecycle | Onboarding requests preserve identity/access fields; immutable decision records preserve approval and external-result outcomes. | Corrected missing `provisioning` Go state and the migration decision constraint for activation outcomes. |
| External-result persistence | Provisioning/activation success or failure updates a request state and creates a decision record. | Corrected to use one serializable PostgreSQL transaction, preventing a partial internal state/decision write. |
| Keycloak synchronization | The client uses client credentials over HTTPS, optional trusted CA material, organization invitation and organization-group assignment. | Verified against actual local Keycloak 26.7.1, not a mock API. |
| Local runner | The suite starts PostgreSQL, Keycloak and Mailpit; applies the real migrations; starts the service and checks the completed lifecycle. | Corrected to build and execute the current service binary rather than risk a stale `go run` child process. |

## Remaining production design issue

The database transaction protects internal state plus evidence, but it cannot atomically include a remote Keycloak operation. If Keycloak succeeds and the subsequent PostgreSQL transaction fails, the handler returns an urgent error and the request remains in an intermediate state. A production release requires an idempotent reconciliation/outbox design, approved recovery ownership and Keycloak-side correlation evidence; it must not retry blindly.

## Local integration evidence

The current local suite ran actual containers and protocols: PostgreSQL 16, Keycloak 26.7.1 with a locally generated and verified TLS certificate, and Mailpit SMTP. It generated ephemeral local test fixtures, then removed container state at exit. The non-secret persisted result was:

```json
{
  "request_status": "submitted",
  "final_status": "active",
  "decisions": "approved,invited,active",
  "mail_count": 1,
  "keycloak_group_member_found": true
}
```

## Multi-language validation evidence

| Language | Components checked | Result |
|---|---|---|
| Go | Security verifier, maritime evidence, central administration, financial control compile checks; race detection and `go vet` for reviewed Go services. | Passed. |
| Rust | Waterway-safety `cargo fmt --check`, locked tests and Clippy with warnings denied. | Passed; two library tests passed. |
| Python | Delta Lake ingestion and traceability source/schema validation; Python package dependency consistency. | Passed; no broken requirements reported. |
| TypeScript | Credential verifier strict build/test and Ministry portal production build/test. | Passed; two credential tests and two portal runtime-configuration tests passed. |

## Completion score

The score remains **28.75%**. Review remediation and stronger source-level assurance improve confidence but do not create a new Ministry target environment, real agency/partner interface, regulated payment rail, operational data source or accountable production acceptance. The complete scoring model remains in `completion-scoring.md`.
