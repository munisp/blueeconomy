# Private Repository Release Baseline — 13 August 2026

This record verifies the source-release state after the post-remediation audit. Each private repository was fetched from GitHub, had a clean local worktree, had local `main` equal to `origin/main`, exposed only a remote `main` branch, and had zero open pull requests at the time of verification.

| Repository | Remote `main` baseline | Remote branches | Open pull requests |
|---|---|---:|---:|
| `blueeconomy` | `a152bb008900ab428072cc851f853730a73a3452` | 1 (`main`) | 0 |
| `blueeconomy-administration-service` | `9832b4de91fda0a00f46d4e97ca536b112f23de0` | 1 (`main`) | 0 |
| `blueeconomy-contracts` | `b679225753f6ee08db3ca7a45759cfd6ad74fc12` | 1 (`main`) | 0 |
| `blueeconomy-credential-verification` | `6d86d73b9146395bec1e78c7b9e36e3667d4da25` | 1 (`main`) | 0 |
| `blueeconomy-data-platform` | `6e45e870e97f61c57a4a5443a4bcc138f837beb0` | 1 (`main`) | 0 |
| `blueeconomy-developer-platform` | `bcc6e34bbb682f15a8c70bc004708239935e8a8f` | 1 (`main`) | 0 |
| `blueeconomy-financial-controls` | `989ba143d5e3f3f884b8058f65a8e41b3f5f155b` | 1 (`main`) | 0 |
| `blueeconomy-maritime-evidence` | `be55345256f1412e5669ac708bbd5fc67c18c7d4` | 1 (`main`) | 0 |
| `blueeconomy-ministry-portal` | `51114e1d304f5f30d4263610943cf73cc7729444` | 1 (`main`) | 0 |
| `blueeconomy-platform-gitops` | `a7e0c608e20b5f7879b36d8860a3462d4327c482` | 1 (`main`) | 0 |
| `blueeconomy-security-operations` | `41a4a52ca035117826a7a577464e25a1c68b611c` | 1 (`main`) | 0 |
| `blueeconomy-traceability` | `395f134381c6430ecbbe6c29eaf7083056c66a36` | 1 (`main`) | 0 |
| `blueeconomy-waterway-safety` | `49a0bcd553d366172588f94a3cc84de4901ef2f9` | 1 (`main`) | 0 |

## Workflow-Publication Exception

The user requested active GitHub Actions verification for all repositories. Those workflow definitions have been written and linted locally, but GitHub refused creation or update of `.github/workflows/*` with the configured GitHub App credential because it lacks workflow-write permission. To avoid withholding security and integrity fixes, the non-workflow source changes were published to `main`; the workflow commits are retained only as local safety branches named `local/workflow-pending-20260813`.

> This is a **repository-automation gap**, not a claim that any source remediation is unpublished. Reauthorization with GitHub Actions workflow-write permission is required before the locally linted workflow files can be pushed and their GitHub-hosted runs can be treated as evidence.

The complete machine-readable verification output is retained in `blueeconomy-audit-inventory/github-convergence-2026-08-13.txt`.
