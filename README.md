# Blue Economy Platform Programme

This private repository is the **governance and bootstrap repository** for the Ministry’s Unified Blue Economy Platform. It records architecture decisions, implementation controls, integration gates and cross-repository standards. It is deliberately **not** a monorepo for all production services.

## Delivery commitment

The platform is being built as a hybrid-deployment, open-source-first system using Go, Rust, Python and TypeScript. It will use genuine non-production and production integrations only when authorised endpoint, credential, network, data-governance and operational evidence are available. The programme does not accept mock partner systems, fabricated endpoints, synthetic operational records, placeholder credentials or unsubstantiated readiness claims as delivery evidence.

## Current status

The initial release prioritises the secure platform foundation, maritime evidence and waterway-safety capability. Repository and integration prerequisites are documented before deployable source repositories are created.

## Key documents

| Document | Purpose |
|---|---|
| [Repository Strategy](docs/architecture/repository-strategy.md) | Open-source-first repository portfolio, language boundaries, release model and real-integration test policy. |
| [Verified Integration Gates](docs/implementation/integration-gates.md) | Evidence required before an external service can be represented as integrated or release-ready. |
| [Current Implementation State](docs/implementation/current-state.md) | Repository-level published source, local evidence and target-environment boundaries. |
| [Evidence-Based Completion Scoring](docs/implementation/completion-scoring.md) | The 34.00% source-and-local-integration completion calculation. |
| [Post-Remediation Production-Readiness Assessment](docs/implementation/audit/production-readiness-assessment-2026-08-13.md) | Feature scores, remediation disposition, financial-integrity boundary and residual-risk register. |
| [Audit Evidence Register](docs/implementation/audit/evidence-register-2026-08-13.md) | SHA-256 references for retained verification logs and assessed private `main` baselines. |

## Data and secret handling

This repository must not contain production or partner secrets, kubeconfigs, private keys, certificates, service-account tokens, real personal/financial/credential records, sensitive location data, restricted incident evidence or unapproved operational exports. Runtime configuration and secret delivery are introduced only after the authorised hybrid environment and secret-management approach are defined.
