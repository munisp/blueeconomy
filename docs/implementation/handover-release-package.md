# Blue Economy Platform — Source Foundation Handover

**Release designation:** Source Foundation Baseline 0.1.0  
**Date:** 12 August 2026  
**Ownership:** `munisp` private repository portfolio  
**Deployment status:** **Not deployed.** The source foundation has passed the available local validation suite; target-side integration, recovery and production gates are intentionally pending authorised Ministry environments.

## Exact repository baseline

| Repository | Commit | Responsibility |
|---|---:|---|
| `blueeconomy` | `7b474bc7d601eb2af7b42f83585245a08cabd7ac` | Programme governance, repository strategy, integration gates and verification gates. |
| `blueeconomy-contracts` | `b679225753f6ee08db3ca7a45759cfd6ad74fc12` | Shared Protocol Buffers contracts for metadata, evidence, waterway safety and audit events. |
| `blueeconomy-developer-platform` | `bcc6e34bbb682f15a8c70bc004708239935e8a8f` | Developer assurance and platform engineering foundation. |
| `blueeconomy-platform-gitops` | `9416ffd719985e48c9d40965e3133f8434fa4e84` | Kubernetes base policy and reproducible open-source component lock. |
| `blueeconomy-security-operations` | `28ea74effd41f6495d9c43339b5eac37e0c248db` | Go security/OIDC endpoint verifier and security operating controls. |
| `blueeconomy-data-platform` | `250c9321dc1cd8043af70ad380e665ea9e134b98` | Python real-input append-only Delta Lake ingestion control. |
| `blueeconomy-maritime-evidence` | `3ce375eabac629b1ff31c043949a8c3958cc33a2` | Go/PostgreSQL immutable evidence schema and guarded migration command. |
| `blueeconomy-waterway-safety` | `497abf853c375db0f8f0817e60860940c8484cb1` | Rust telemetry integrity validator. |
| `blueeconomy-financial-controls` | `f4bcbac83728ab41fd4338f97b97d00c471e2142` | Go fail-closed, read-only TigerBeetle verifier. |
| `blueeconomy-credential-verification` | `1c82874fe1a93cf21608e90d7f4b1a5e0c522788` | TypeScript issuer/JWKS credential verifier. |
| `blueeconomy-traceability` | `0f66622e499e5acc2f1e0b46676da38a2cd02e08` | Python real-record traceability-chain validator. |
| `blueeconomy-ministry-portal` | `79fc84240476cc7a3056d12eb857817883549345` | Runtime-configured React/OIDC Ministry portal. |

## Validation baseline

`/home/ubuntu/validate_blueeconomy_portfolio.sh` completed successfully against this source foundation. It ran the Protocol Buffers contract checks, GitOps/source-lock checks, Go unit/static checks, Python source/schema checks, Rust format/test/lint checks and TypeScript build/test checks. The result proves only that the published source compiles and passes the listed local deterministic validations.

It does **not** prove a live identity integration, API route, Kubernetes deployment, database/object store, Kafka/Temporal/Dapr workload, telemetry gateway, financial cluster, payment participant, credential issuer, traceability partner, resilience exercise or production release.

## Required handover inputs

The Ministry implementation owner must provide the approved non-production integration registry, including Kubernetes contexts, network routes, TLS/trust chain, secret-delivery process, Keycloak realm/client configuration, APISIX route inventory, Wazuh/OpenSearch/OpenCTI endpoints, Kafka/Temporal/PostgreSQL/object-storage configuration, real source/partner interfaces, TigerBeetle/Mojaloop configuration, credential issuer/JWKS data and traceability/data-sharing approvals.

The owner must then run the component-specific gates in [`target-verification-gates.md`](target-verification-gates.md). The implementation team must retain approved redacted evidence for each completed gate, with security, data, operational and business-owner approval as applicable.

## First execution sequence

1. Confirm the authoritative hybrid non-production target and supply the registry through approved secret delivery.
2. Render and apply the locked GitOps sources under the Ministry change process; complete storage, network, certificate, workload-identity and backup configuration.
3. Configure Keycloak/APISIX and run the Go security verifier against authorised endpoints.
4. Configure Kafka, Temporal, Dapr, PostgreSQL/object storage and Delta Lake; prove authenticated append-only/event/workflow operation with authorised records.
5. Apply the maritime-evidence migrations; connect safety, evidence, traceability, credential and financial controls to the real non-production dependencies in the defined priority order.
6. Deploy the Ministry portal with its deployment-provided `platform-config.json`, registered OIDC client and approved route inventory; conduct sign-in, role-denial and endpoint-probe verification.
7. Complete recovery, security, performance and partner conformance gates before any production decision.

## Non-fabrication assurance

No repository contains default external endpoints, partner credentials, default users, payment participants, ledger accounts, sample catch records, device telemetry records, credentials, fake service responses or claims of target deployment. Any currently unavailable target capability is documented as a gate rather than represented as implemented or verified.
