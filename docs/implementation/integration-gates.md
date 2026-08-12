# Verified Integration Gates

**Status:** Initial foundation; external systems are **not yet verified in this repository**.  
**Last reviewed:** 12 August 2026  
**Policy owner:** Ministry Platform Design Authority

> **Non-fabrication rule.** A service is not labelled `integrated`, `connected`, `certified`, `production-ready`, or `tested` until this repository contains reviewable evidence of a successful non-production connection, authenticated operation, functional test result, and responsible-owner approval. Placeholder URLs, static credentials, simulated partner records and local mock endpoints are prohibited for integration acceptance.

## 1. Current Verified Position

| Capability | Current verified evidence | State | Implementation constraint |
|---|---|---|---|
| GitHub bootstrap repository | `munisp/blueeconomy` is a private empty repository, converted from public visibility during this programme. | Verified. | It may contain source code, non-secret configuration templates, architecture and test evidence. It must not contain credentials, client secrets, kubeconfigs, live certificate material, regulated data or production operational exports. |
| Hybrid deployment target | Ministry selected a hybrid deployment approach. A cluster/provider, locations, network design, VPN/private-connectivity path, identity boundary and operational owner have not been recorded in this repository. | Decision confirmed; environment details pending. | No workload deployment, image publication, DNS/routing, certificate issuance, backup or disaster-recovery claim is permitted. |
| Non-production integrations | Ministry confirmed that authorised non-production environments exist. No endpoint, realm/tenant, network path, technical contact, credential or test evidence has been supplied in this task. | Authorisation declared; connections unverified. | Adapters/contracts may be built; no live integration test, health claim, conformance claim or release promotion is permitted. |
| Mojaloop | No configured Mojaloop connection was found in the current task configuration. | Unverified. | Payment-switch/fund-transfer code remains outside the first release and cannot use an assumed endpoint. |
| Keycloak, APISIX, Wazuh, OpenSearch, OpenCTI, Kafka, Temporal, PostgreSQL and object storage | No service endpoint/credential/test tenant is recorded in this repository. | Unverified. | First-release manifests may declare required external dependencies but must not include fake addresses or connection secrets. |
| Maritime evidence / waterway safety source | The business scope is approved as first-release priority, but no authorised source/gateway interface record is yet available. | Unverified. | No vessel, incident, telemetry, location or partner record may be invented for tests or demos. |

## 2. Required Integration Registry

The Ministry must provide the following through an approved secure channel. The integration registry itself should be stored in an approved secret/configuration management system—not in source control—unless it contains only non-sensitive service metadata.

| Required field | Purpose |
|---|---|
| System and environment name | Identify the actual sandbox, UAT or non-production system. |
| Base URL or cluster/API reference | Configure the integration without guessing endpoints. |
| Network path and restrictions | Confirm private link, VPN, IP allowlist, DNS, mTLS or proxy requirements. |
| Authentication type and credential delivery method | Define OAuth2/OIDC/SAML, mTLS, signed request, API key or other approved mechanism without exposing secret values. |
| Tenant, realm, participant or organisation ID | Scope operations safely to the approved non-production domain. |
| Data classification and permitted test data | Confirm which real, approved, non-production records may be processed. |
| Rate, availability and maintenance constraints | Define safe automated test and retry behaviour. |
| Test operation and expected verifiable outcome | Establish a genuine conformance/health check, not a fabricated assertion. |
| Technical and business owner | Identify approval and escalation responsibilities. |
| Evidence location and approval date | Link to signed test result, change approval and risk decision. |

## 3. Integration Acceptance Standard

An integration changes from `unverified` to `verified non-production` only when all rows below are satisfied.

| Gate | Required evidence |
|---|---|
| Contract | Versioned OpenAPI/AsyncAPI/protocol/identity contract has an identified authoritative source and a compatibility decision. |
| Security | Endpoint ownership, TLS/mTLS behaviour, credentials/secrets path, minimum scopes, audit event and data classification are reviewed. |
| Network | The required path is reachable from the authorised hybrid environment; firewall/DNS/proxy controls are evidenced. |
| Functional operation | An approved non-production request using genuine endpoint/credentials completes with an observable expected result. |
| Negative operation | A denied/invalid request is tested and audit/detection behaviour is evidenced without disclosing secrets or sensitive records. |
| Resilience | Timeout, retry, idempotency/replay and unavailable-dependency behaviour are tested against the genuine non-production system where the owner authorises it. |
| Operational readiness | Monitoring, alert ownership, runbook, change/release rollback and support contact are approved. |
| Data governance | Test-data authority, retention, deletion/cleanup and export controls are evidenced. |

## 4. First-Release Release Gate

The secure platform foundation and maritime evidence/waterway-safety release cannot be promoted beyond development until it has, at minimum: a named hybrid target; approved namespaces/network boundaries; actual Keycloak and API-edge integration; Kafka/Temporal/PostgreSQL/object-storage connectivity; Wazuh/OpenSearch security telemetry; OpenCTI curation/enrichment policy where used; and an authorised maritime evidence or safety-source test interface. These conditions are intentionally strict: unavailable dependencies are delivery risks to be resolved, not conditions to be replaced with mocks or invented outputs.
