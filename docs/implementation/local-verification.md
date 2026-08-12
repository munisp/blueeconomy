# Local Verification Instructions

These commands validate source, contract, schema and policy behaviour only. They **do not** create user accounts, contact Keycloak, send invitations, connect to Mojaloop/TigerBeetle, ingest partner records or claim a live deployment. Those operations require the approved non-production integration registry and target-side gates.

## 1. Prerequisites

Run these checks on Linux with the following toolchain baseline.

| Tool | Required baseline | Check command |
|---|---:|---|
| Git and GitHub CLI | Authenticated to `munisp` private repositories | `git --version && gh auth status` |
| Go | 1.22 or later | `go version` |
| Rust/Cargo | 1.75 or later, including `rustfmt` and `clippy` | `rustc --version && cargo --version && rustfmt --version && cargo clippy --version` |
| Python | 3.11 or later | `python3 --version` |
| Node.js/npm | Node 22 or later | `node --version && npm --version` |
| Protocol Buffers compiler | Available for contract descriptor checks | `protoc --version` |

## 2. Clone the private portfolio

```bash
mkdir -p "$HOME/blueeconomy-workspace"
cd "$HOME/blueeconomy-workspace"

for repository in \
  blueeconomy \
  blueeconomy-contracts \
  blueeconomy-developer-platform \
  blueeconomy-platform-gitops \
  blueeconomy-security-operations \
  blueeconomy-data-platform \
  blueeconomy-maritime-evidence \
  blueeconomy-waterway-safety \
  blueeconomy-financial-controls \
  blueeconomy-credential-verification \
  blueeconomy-traceability \
  blueeconomy-administration-service \
  blueeconomy-ministry-portal
do
  gh repo clone "munisp/${repository}"
done
```

If a directory already exists, use `git -C <directory> pull --ff-only` rather than cloning over it.

## 3. All available local source checks

Create the following file at `$HOME/blueeconomy-workspace/validate-all.sh`, make it executable, then run it. It deliberately contains no target endpoint, secret, account, partner or sample business data.

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/blueeconomy-workspace"

(
  cd "$ROOT/blueeconomy-contracts"
  ./scripts/validate-contracts.sh
)
(
  cd "$ROOT/blueeconomy-platform-gitops"
  ./scripts/validate-manifests.sh
)
(
  cd "$ROOT/blueeconomy-security-operations"
  GOTOOLCHAIN=local go test ./...
  GOTOOLCHAIN=local go vet ./...
)
(
  cd "$ROOT/blueeconomy-data-platform"
  python3 scripts_validate.py
)
(
  cd "$ROOT/blueeconomy-maritime-evidence"
  GOTOOLCHAIN=local go test ./...
  GOTOOLCHAIN=local go vet ./...
)
(
  cd "$ROOT/blueeconomy-waterway-safety"
  cargo fmt --check
  cargo test --locked
  cargo clippy --all-targets -- -D warnings
)
(
  cd "$ROOT/blueeconomy-financial-controls"
  GOTOOLCHAIN=local go test ./...
  GOTOOLCHAIN=local go vet ./...
)
(
  cd "$ROOT/blueeconomy-administration-service"
  GOTOOLCHAIN=local go test ./...
  GOTOOLCHAIN=local go vet ./...
)
(
  cd "$ROOT/blueeconomy-credential-verification"
  npm ci
  npm run verify
)
(
  cd "$ROOT/blueeconomy-traceability"
  python3 scripts_validate.py
)
(
  cd "$ROOT/blueeconomy-ministry-portal"
  npm ci
  npm run build
  npm test
)
```

```bash
chmod +x "$HOME/blueeconomy-workspace/validate-all.sh"
"$HOME/blueeconomy-workspace/validate-all.sh"
```

## 4. Language-specific commands

### Go

```bash
cd "$HOME/blueeconomy-workspace/blueeconomy-security-operations"
GOTOOLCHAIN=local go test ./... && GOTOOLCHAIN=local go vet ./...

cd "$HOME/blueeconomy-workspace/blueeconomy-maritime-evidence"
GOTOOLCHAIN=local go test ./... && GOTOOLCHAIN=local go vet ./...

cd "$HOME/blueeconomy-workspace/blueeconomy-financial-controls"
GOTOOLCHAIN=local go test ./... && GOTOOLCHAIN=local go vet ./...

cd "$HOME/blueeconomy-workspace/blueeconomy-administration-service"
GOTOOLCHAIN=local go test ./... && GOTOOLCHAIN=local go vet ./...
```

### Rust

```bash
cd "$HOME/blueeconomy-workspace/blueeconomy-waterway-safety"
cargo fmt --check
cargo test --locked
cargo clippy --all-targets -- -D warnings
```

### Python

The Python checks use the real source, installed Delta Lake/Parquet libraries and declared schemas, but do not generate any domain data.

```bash
cd "$HOME/blueeconomy-workspace/blueeconomy-data-platform"
python3 scripts_validate.py

cd "$HOME/blueeconomy-workspace/blueeconomy-traceability"
python3 scripts_validate.py
```

### TypeScript

```bash
cd "$HOME/blueeconomy-workspace/blueeconomy-credential-verification"
npm ci
npm run verify

cd "$HOME/blueeconomy-workspace/blueeconomy-ministry-portal"
npm ci
npm run build
npm test
```

## 5. Central administration source validation

The central administration service will correctly fail to start until the real Keycloak, PostgreSQL and role-map configuration is injected. Confirm this fail-closed behaviour without entering a secret:

```bash
cd "$HOME/blueeconomy-workspace/blueeconomy-administration-service"
env -i PATH="$PATH" HOME="$HOME" GOTOOLCHAIN=local go run ./cmd/admin-service
```

The expected outcome is a non-zero exit that identifies a missing required configuration variable. Do **not** use placeholder Keycloak URLs, fabricated organizations or guessed service-account credentials to force a start.

## 6. Target-side tests after the Ministry supplies the approved registry

Follow [`target-verification-gates.md`](target-verification-gates.md) after the Ministry provides actual cluster contexts, APISIX routes, Keycloak realm/client/service-account configuration, PostgreSQL/object storage, Kafka/Temporal/Dapr endpoints, partner interfaces, certificates, role mappings and approved non-production data. Real target-side tests must use redacted evidence and must not be replaced by local mocks.
