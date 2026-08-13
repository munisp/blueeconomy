# Audit Evidence Register — 13 August 2026

This register identifies the retained non-secret evidence used by the post-remediation assessment. The raw logs are held in the controlled audit workspace at `/home/ubuntu/blueeconomy-audit-inventory/`; they are not committed because they include transient container/runtime output and build artefacts. The SHA-256 values below permit integrity checking of the retained copies.

| Evidence artifact | SHA-256 | Purpose |
|---|---|---|
| `full-production-readiness-suite-post-remediation.log` | `8a45d19fcd37a55703786a911488907fcadeed8c5f63a4225493c4f1b58cd052` | Cross-language post-remediation suite: Go, Rust, Python, TypeScript, GitOps and contracts. |
| `go-real-integrations-post-remediation.log` | `fcba4934f443d794a8451cfa3ce1c7fd8b4edd6f1313c8cd2294b50cb79a5e9e` | Local PostgreSQL–Keycloak–SMTP and PostgreSQL maritime-evidence integration evidence. |
| `gitops-helm-validation-post-import.log` | `533a5b133a9107bf523aea8bfd98336260373cd3b5302cc48e0eb7822da90ffd` | GitOps source locks, chart source, fail-closed gate and umbrella dependency validation. |
| `portfolio-validation-post-remediation.log` | `9d035044ebe480199afe7fb3e69e27874ea57e6f62c7e3bb4f72ced6b5da6260` | Strict local portfolio verification after source remediation. |
| `weighted-production-readiness-index.txt` | `f4463d01ea7482bc0667d3d030e00fb90e35c1b514bdc444d12e975913b7700d` | Reproducible arithmetic for the 16.60% weighted production-readiness index. |

## Assessed Private `main` Baselines

| Repository | Assessed `main` commit |
|---|---|
| `blueeconomy` | `4f2b4dde7bf90146f5ae3cdbfc5fa524c2be18f7` |
| `blueeconomy-administration-service` | `9832b4de91fda0a00f46d4e97ca536b112f23de0` |
| `blueeconomy-contracts` | `b679225753f6ee08db3ca7a45759cfd6ad74fc12` |
| `blueeconomy-credential-verification` | `6d86d73b9146395bec1e78c7b9e36e3667d4da25` |
| `blueeconomy-data-platform` | `6e45e870e97f61c57a4a5443a4bcc138f837beb0` |
| `blueeconomy-developer-platform` | `bcc6e34bbb682f15a8c70bc004708239935e8a8f` |
| `blueeconomy-financial-controls` | `989ba143d5e3f3f884b8058f65a8e41b3f5f155b` |
| `blueeconomy-maritime-evidence` | `be55345256f1412e5669ac708bbd5fc67c18c7d4` |
| `blueeconomy-ministry-portal` | `51114e1d304f5f30d4263610943cf73cc7729444` |
| `blueeconomy-platform-gitops` | `a7e0c608e20b5f7879b36d8860a3462d4327c482` |
| `blueeconomy-security-operations` | `41a4a52ca035117826a7a577464e25a1c68b611c` |
| `blueeconomy-traceability` | `395f134381c6430ecbbe6c29eaf7083056c66a36` |
| `blueeconomy-waterway-safety` | `49a0bcd553d366172588f94a3cc84de4901ef2f9` |

> The baselines identify source assessed by this audit. They are not evidence that a Ministry target environment, agency partner, production workflow, regulated payment participant, or operational owner accepted the capability.
