# Blue Economy Platform Repository Strategy

**Status:** Initial implementation decision record  
**Owner:** Ministry Platform Design Authority  
**Repository owner:** `munisp`  
**Deployment model:** Hybrid, open-source-first, private source repositories  
**First release:** Secure platform foundation, maritime evidence and waterway safety

> **Decision.** The platform will use a deliberately limited multi-repository model. A repository exists for a deployable bounded context, a governed contract set, shared deployment/security controls, or a distinct operational data platform. It will not create a repository for every microservice, every library or every technology product. This preserves independent release and security boundaries without creating unmanageable operational fragmentation.

## 1. Principles

| Principle | Required implementation rule |
|---|---|
| Open-source first | Prefer self-hostable components with published formats/protocols, source-available operational tooling and portable data stores. Managed/proprietary services require a documented exception covering the unmet operational, regulatory, resilience or support requirement. |
| Ministry ownership | Source, infrastructure definitions, configuration schemas, test evidence, build artefacts, API contracts and operational runbooks are controlled by `munisp`; production secrets and sensitive operational exports are not committed. |
| No fabricated integrations | A component does not claim a connection, partner conformance or production readiness until genuine non-production evidence exists under the integration gate standard. |
| Deployable-domain boundary | Application code is grouped by stable business capability and release cadence, not programming language alone. A deployable may contain Go, Rust, Python or TypeScript only where the boundary remains coherent. |
| Contracts before coupling | Cross-repository service interfaces are versioned OpenAPI, AsyncAPI, Protobuf or documented standards. A repository never relies on an unpublished internal interface. |
| Supply-chain integrity | Every merge is reviewed, reproducibly built, dependency-scanned, SBOM-producing and provenance-attested before it can be promoted. Pinned dependencies and image digests are mandatory. |
| Hybrid portability | Cloud and on-premises deployment differences are expressed through approved environment overlays and policy—not application forks. |
| Explicit operational ownership | Every repository has code owners, service owner, security owner, data owner where applicable, SLO/runbook reference and a named deployment path. |

## 2. Repository Portfolio

### 2.1 Bootstrap and governance repository

| Repository | Purpose | Primary contents | Technology / release boundary |
|---|---|---|---|
| `blueeconomy` | Programme bootstrap, architecture decision records, delivery governance, integration-gate record, repository catalogue and cross-repository standards. | Architecture, risk/decision records, repository strategy, compatibility policy, standard issue templates and non-secret delivery controls. | Documentation and governance only. It contains no deployment credentials, real endpoint details, regulated data or application secrets. |

The existing `blueeconomy` repository is private and is the programme’s initial control repository. It is not a monorepo for every deployable component.

### 2.2 Foundation repositories

| Proposed repository | Bounded responsibility | Principal technologies | First-release responsibility |
|---|---|---|---|
| `blueeconomy-contracts` | Authoritative external/internal API, event, identity-claim and data-product contracts; compatibility tests; generated client policy. | OpenAPI, AsyncAPI, Protobuf, JSON Schema, Buf, TypeScript/Go/Python/Rust code generation as applicable. | Define evidence, safety telemetry, incident, workflow and audit contracts. |
| `blueeconomy-platform-gitops` | Hybrid Kubernetes environments, Helm/Kustomize overlays, GitOps policy, open-source platform component declarations and deployment evidence. | Kubernetes, Helm, Kustomize, Argo CD or Flux after evaluation, OPA/Gatekeeper or Kyverno after evaluation, SOPS/age or equivalent secret-reference pattern. | Establish non-secret manifests for Keycloak, APISIX, Kafka, Temporal, PostgreSQL, OpenSearch, Wazuh, OpenCTI, observability and ingress/security policy. |
| `blueeconomy-security-operations` | Security policy-as-code, Keycloak realm/client/role definitions, detection-rule lifecycle, OpenCTI curation configuration, Wazuh/OpenSearch integration configuration and operational runbooks. | Keycloak configuration, Wazuh rules/configuration, OpenCTI connector configuration, OpenSearch security templates, policy-as-code. | Implement audited identity/role model and SOC evidence patterns only after genuine environment records are available. |
| `blueeconomy-developer-platform` | Reusable CI/CD workflows, build containers, service templates, local developer tooling, secure dependency policy and documentation generators. | GitHub Actions, Go, Rust, Python, TypeScript/Node, container build tooling, SBOM/provenance tooling. | Make every application repository reproducibly buildable and policy-checked. |
| `blueeconomy-data-platform` | Governed ingestion/processing jobs, lakehouse table definitions, quality/lineage controls and geospatial analytics. | Python, Apache Spark, Flink, Sedona, DataFusion and Ray where workload evidence warrants each runtime; Delta Lake and Parquet. | Establish only approved, real data source ingestion; no fabricated maritime data. |

### 2.3 Business-domain repositories

| Proposed repository | Bounded responsibility | Primary implementation languages | Release sequence |
|---|---|---|---|
| `blueeconomy-maritime-evidence` | Port call/evidence packages, document hash/metadata, validation status, workflow hand-off and approved partner interfaces. | Go for API/workflow service; TypeScript for schema/client support where needed. | **Release 1.** |
| `blueeconomy-waterway-safety` | Safety telemetry intake, device/gateway identity, event validation, freshness/out-of-order handling, alert/case workflow integration and approved operator experience. | Rust for high-integrity telemetry/event processor; Go for service/API coordination; TypeScript for UI. | **Release 1.** |
| `blueeconomy-financial-controls` | Account mapping, payment-intent workflow, reconciliation, TigerBeetle integration and Mojaloop adapter boundary. | Go for service/workflows; Rust where ledger-adjacent deterministic processing is justified. | Later release; requires real Mojaloop/TigerBeetle environment and financial-control approval. |
| `blueeconomy-credentials` | Issuer/verifier integration, credential status, revocation workflow, workforce/beneficiary role boundary and audit. | Go and TypeScript. | Later release; requires issuer authority, key-management and legal approval. |
| `blueeconomy-traceability` | Catch/landing/chain-of-custody events, offline capture/replay, cold-chain/quality signals and partner interface. | Go, Rust for edge/replay where justified, TypeScript for field workflow. | Later release. |
| `blueeconomy-ministry-portal` | Ministry operator, agency and partner web experience; API-client implementation; accessibility and low-bandwidth delivery. | TypeScript, React, open standards and generated typed clients. | Starts with first release, but only renders genuine non-production integration states. |

### 2.4 Repository creation policy

A repository is created only when its owner, deployable boundary, contract dependency, initial backlog and CI protection baseline are identified. The initial implementation should create the bootstrap repository content and then create only the first-release repositories: `blueeconomy-contracts`, `blueeconomy-platform-gitops`, `blueeconomy-developer-platform`, `blueeconomy-security-operations`, `blueeconomy-maritime-evidence`, `blueeconomy-waterway-safety`, and `blueeconomy-ministry-portal`. The financial, credential and traceability repositories are created at the approved start of their respective releases, not as empty repositories that could be mistaken for delivered capability.

## 3. Language and Component Allocation

| Language | Use only for | Prohibited use |
|---|---|---|
| Go | Public/internal APIs, workflow workers, integration adapters, controlled background services, concurrency-oriented domain coordination and command-line operations tools. | Browser user interface, unreviewed financial correctness logic without independent reconciliation/invariant tests. |
| Rust | Telemetry/event validation, edge agents/gateways, high-assurance deterministic parsers/processors, performance-sensitive stream handling and security-sensitive utilities when justified by a measured risk/performance need. | Creating a Rust service merely to satisfy language diversity; unapproved cryptographic implementation. |
| Python | Lakehouse ingestion/quality/geospatial/analytics jobs, scientific/spatial processing, data governance automation and carefully controlled operational tooling. | Long-lived, latency-critical public APIs where Go/Rust is the approved service runtime. |
| TypeScript | Ministry/partner portal, web integration SDKs, developer tooling and typed API/client packages. | Holding authoritative financial, identity, ledger or safety state in a browser. |

Language choice is a design decision documented per component. Business rules critical to safety, finance, authorization or data integrity must be contract-tested across the relevant interface, regardless of language.

## 4. Release and Branching Strategy

| Topic | Standard |
|---|---|
| Default branch | `main` is protected and always releasable. Direct pushes are prohibited after bootstrap protection is enabled. |
| Change path | Short-lived feature branches or release branches create pull requests. Each pull request links to a decision/issue, includes contract/version impact and carries test evidence. |
| Versioning | Semantic versioning for published contracts, libraries and deployable images. Breaking API/event changes require a documented migration path and compatibility window. |
| Release promotion | Build once; promote immutable image/chart/contract digests through development, non-production/UAT and production only with environment-specific approval evidence. Never rebuild a supposedly identical production artefact. |
| GitOps | Environment deployment happens through reviewed changes in `blueeconomy-platform-gitops`; no direct, unaudited cluster mutation is accepted as a release. |
| Emergency change | A documented break-glass process is allowed only for incident containment/recovery. It must create a retrospective pull request and evidence record. |
| End-of-life | Deprecated API/event versions, images, Helm charts and data schemas retain a published retirement date, consumer inventory and migration verification. |

## 5. Security, Quality and Supply-Chain Baseline

Every application/foundation repository receives the following before accepting a business feature:

| Control | Required implementation evidence |
|---|---|
| Repository settings | Private visibility, least-privilege team access, branch protection, required review, signed commit/tag policy where supported and no default external contribution path. |
| Secrets | No plaintext secrets in Git. A pre-commit/CI secret scan runs on all changes. Runtime secrets are referenced from the approved environment secret-management solution after the hybrid target is provided. |
| Dependency integrity | Language lockfiles committed; dependencies pinned; automated dependency update proposal and vulnerability alerting enabled; licensing review for critical dependencies. |
| Build | Reproducible build command, pinned build image/toolchain, generated code checked for drift and non-secret configuration validation. |
| Test | Unit, contract, integration and policy tests are layered. An integration test is marked `verified` only when it reaches an authorised genuine non-production dependency. |
| Supply-chain output | SBOM, image digest, provenance/attestation and vulnerability report retained with each release candidate. |
| Deployment | Kubernetes manifests are schema/policy-linted, image references use digests, resource requests/limits and network/service-account controls are defined. |
| Operational evidence | Health/readiness specification, metrics/log/trace contract, alert/runbook link, backup/recovery expectation and owner are present. |

## 6. Real-Integration Test Policy

| Test type | Permitted execution | Acceptance language |
|---|---|---|
| Unit/property test | Local or CI; validates deterministic code with in-process data structures. | `unit tested`; never `integration verified`. |
| Contract test | Validates a versioned API/event/schema reference without claiming network reachability. | `contract compatible` only if authoritative contract version is identified. |
| Deployment/policy test | Renders and validates Kubernetes/Helm/Kustomize/policy configuration without a target cluster. | `manifest validated`; never `deployed`. |
| Non-production integration test | Uses authorised endpoint, credentials and approved test data; preserves evidence while masking secrets. | `verified non-production integration`. |
| Conformance/recovery/security test | Runs an approved scenario against the real target/service and records result, evidence, owner and corrective actions. | `conformance verified`, `recovery verified` or `security test passed` only for the measured scenario/version. |

Tests may use generated values for deterministic internal unit/property testing. Such values are clearly identified as test inputs and never presented as Ministry, citizen, vessel, payment, credential, partner or operational records. No fake service endpoint is accepted as evidence of integration.

## 7. First-Release Repository Dependencies

```text
blueeconomy (governance)
   ├── blueeconomy-contracts
   ├── blueeconomy-developer-platform
   ├── blueeconomy-platform-gitops
   ├── blueeconomy-security-operations
   ├── blueeconomy-maritime-evidence ──┐
   ├── blueeconomy-waterway-safety ────┼── blueeconomy-contracts
   └── blueeconomy-ministry-portal ────┘

blueeconomy-platform-gitops consumes versioned deployable artefacts and approved
security/platform declarations; it does not embed application source code.
```

The portal consumes published, versioned contracts and APIs. It never owns authoritative evidence or safety state. The maritime evidence and waterway-safety services exchange durable events through the approved event contract and workflow boundary; neither calls the other’s database.

## 8. Decisions Requiring Ministry Confirmation Before Environment Deployment

1. Hybrid topology: cloud provider/region, on-premises sites, Kubernetes distributions, connectivity/security zones, DNS/certificate authority, backup target and disaster-recovery design.
2. Open-source operator model: Ministry-operated, approved implementation partner-operated, or a named shared-responsibility model for Kubernetes and each stateful component.
3. Source-code licensing: repository visibility is private; any future public/open-source release requires a separate Ministry-approved licence, security review and contribution policy.
4. Approved actual test environments and contacts for Keycloak, APISIX, Wazuh/OpenSearch, OpenCTI, Kafka, Temporal, PostgreSQL, object storage and maritime safety/evidence interfaces.
5. GitHub teams, CODEOWNERS, required approvers, branch-protection and security-scanning entitlements.

## 9. Initial Repository Creation Sequence

| Sequence | Repository / action | Exit evidence |
|---:|---|---|
| 1 | Populate `blueeconomy` with this strategy, integration gates, standards and security baseline. | Reviewed first commit and protected default branch. |
| 2 | Create `blueeconomy-contracts` and `blueeconomy-developer-platform`. | Versioned contract conventions, code-generation policy, reproducible multi-language CI baseline. |
| 3 | Create `blueeconomy-platform-gitops` and `blueeconomy-security-operations`. | Non-secret hybrid overlays, policy validation, platform/security component declarations; no deployment claim until target access exists. |
| 4 | Create `blueeconomy-maritime-evidence`, `blueeconomy-waterway-safety` and `blueeconomy-ministry-portal`. | Service skeletons are prohibited; each repository begins with executable business slices tied to authoritative contracts and real integration gates. |
| 5 | Connect genuine non-production environments and execute contract/integration/security tests. | Masked evidence, approval and remediation record. |
| 6 | Promote a first-release candidate only after required SLO, recovery, security and partner conformance gates pass. | Immutable release manifest, SBOM/provenance, deployment approval and operational handover package. |
