# Implementation Gap Priorities After Source Review and Local Integration

## Evidence boundary

The platform has published and validated source foundations. It has not yet obtained Ministry-controlled target environments, partner interfaces, regulated payment rails, approved operational data or accountable production acceptance. The priorities below therefore distinguish implementation that can be strengthened locally from integration claims that must remain blocked.

| Priority | Workstream | Verified current state | Next evidence-producing work | Target-side prerequisite that cannot be substituted |
|---:|---|---|---|---|
| 1 | Central administration | Local PostgreSQL, Keycloak HTTPS, SMTP invitation and organization-group activation suite passes. | Add a durable reconciliation/outbox design for external Keycloak result uncertainty; add regression coverage for malformed API payloads and transactional outcomes. | Ministry realm, APISIX-injected identities, service account, approved organization/groups and invitation policy. |
| 2 | S1 port interoperability | Evidence schema and immutable PostgreSQL model exist. | Implement a durable receipt and exception API only against a real approved integration contract; no NSW/PCS substitute is permissible. | National Single Window/PCS and agency sandbox routes, source data contract and data-sharing approval. |
| 3 | S2/S6 intelligence and safety | Rust telemetry integrity validation, lakehouse input controls and spatial component source locks exist. | Extend parser quality checks only using explicitly provided telemetry/protocol specifications; retain event-flow testing until source access is approved. | Device registry, telemetry gateway, geofence policy, incident-owner SOP and approved operational feed. |
| 4 | S3 finance | Official TigerBeetle verifier and chart structure exist. | Add only platform-side reconciliation controls after an approved ledger chart and payment lifecycle are supplied. | Authorized TigerBeetle cluster, Mojaloop participant/switch, regulated institution sandbox and fund governance. |
| 5 | S4 credentials | TypeScript issuer/JWKS verifier passes fail-closed validation. | Implement issuer profile validation only after credential profile and issuer/JWKS policy are approved. | Certifying-authority issuer, credential schema/status/revocation policy and relying-party test identity. |
| 6 | S5 traceability | Python provenance-chain validator compiles and rejects invalid chains. | Add conformance rules only after authoritative harvest/landing/custody fields are supplied. | Fisheries, aquaculture, landing-site and custody-system integration records. |
| 7 | Shared platform | Source locks, contracts, GitOps policy and local checks exist. | Publish deployable manifests only after target storage class, cluster policy, network topology, TLS/secret system and ownership are approved. | Hybrid cluster context, namespace policy, ingress/DNS, secret manager and SRE operating model. |

## Review actions completed

The central-administration review found and corrected four source issues. The Go request-status model now includes the persisted `provisioning` state; provisioning and activation result updates now write state and immutable decision evidence inside one serializable PostgreSQL transaction; the HTTP decoder rejects trailing JSON documents; and the local runner builds and executes the current service binary rather than risking a stale `go run` child. The revised local integration suite passed after these corrections.

## Remaining high-severity design issue

A Keycloak invitation or group assignment can succeed while the subsequent PostgreSQL result transaction fails. The API intentionally returns an urgent error in that case, but production needs an authenticated, idempotent reconciliation mechanism or transactional outbox before operational acceptance. This is not solved by retrying blindly because the external Keycloak operation may already have occurred.

## Score implication

No local source change can truthfully create Ministry non-production or operational-acceptance evidence. Reaching 80% under the published rubric requires real target-environment and partner evidence across several domains; it cannot be achieved by mocks, synthetic partner records or unsupported self-certification.
