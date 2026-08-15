# Mojaloop External Switch or Simulator Integration Runbook

## Purpose and boundary

This runbook connects the verified Blue Economy Mojaloop adapter to an **approved non-production switch or genuine protocol simulator**. It does not create a simulator, invent participant identifiers, or authorize live funds. The external environment must be supplied by the Ministry or selected regulated counterparty and recorded in the environment registry before credentials are issued.

The current adapter provides signed outbound request construction, signed callback verification, durable PostgreSQL callback persistence and the following implemented client paths:

| Adapter operation | Current route | Current implementation status |
|---|---|---|
| Quote submission | `POST /quotes/{quoteID}` | Implemented signed request builder; exact partner profile must confirm whether this route and body are accepted. |
| Transfer submission | `POST /transfers` | Implemented signed request builder; transfer orchestration remains outside this adapter boundary. |
| Transfer recovery | `GET /transfers/{transferID}` | Implemented signed request builder. |
| Transfer callback | `PUT /transfers/{transferID}` | Implemented signed HTTP callback handler and PostgreSQL state machine. |

The route profile, FSPIOP version, message bodies, error model and callback semantics must be reconciled against the selected switch/simulator contract before execution. The adapter’s local tests prove protocol and persistence behavior; they do not prove external switch conformance.

## Required inputs before connectivity

The Ministry environment owner and partner must provide a signed environment record containing the switch base URL, callback ingress URL, source and destination participant identifiers, FSPIOP version, scheme/rulebook version, test window, allowed source IPs or mTLS identities, certificate fingerprints, JWK/KID values, supported JWS algorithms, JWE requirements if applicable, timeout and retry policy, rate limits, test accounts, currencies, settlement/test-fund limits, statement format, incident contacts and expiry date.

The target runtime requires PostgreSQL with TLS and a least-privilege role, the committed financial-intent and callback migrations, a secret-manager mount for the RSA signing key and TLS keys, the approved CA bundle, DNS records, outbound network policy to the switch and inbound policy from the callback source. No credential or private key belongs in Git, shell history, test fixtures or retained evidence.

## Configuration

Copy the shape-only template and populate it only from the approved environment registry:

```bash
cd /home/ubuntu/blueeconomy-financial-controls
cp config/mojaloop.env.example /run/user/$(id -u)/blueeconomy-mojaloop.env
chmod 600 /run/user/$(id -u)/blueeconomy-mojaloop.env
```

The target process requires these values:

```text
MOJALOOP_FSPIOP_BASE_URL=https://<approved-switch-host>/<approved-base-path>
MOJALOOP_CALLBACK_BASE_URL=https://<approved-callback-host>/<approved-base-path>
MOJALOOP_FSPIOP_SOURCE=<approved-source-participant>
MOJALOOP_FSPIOP_DESTINATION=<approved-destination-participant>
MOJALOOP_SIGNING_KEY_FILE=<secret-manager-mounted-private-key>
MOJALOOP_SIGNING_KID=<registered-key-id>
MOJALOOP_SIGNATURE_ALGORITHM=RS256
MOJALOOP_CA_BUNDLE_FILE=<secret-manager-mounted-ca-bundle>
MOJALOOP_REQUEST_TIMEOUT=10s
MOJALOOP_LISTEN_ADDR=<approved-bind-address>
MOJALOOP_TLS_CERT_FILE=<secret-manager-mounted-server-certificate>
MOJALOOP_TLS_KEY_FILE=<secret-manager-mounted-server-private-key>
DATABASE_URL=<TLS PostgreSQL connection from secret manager>
MOJALOOP_MIGRATION_PATH=db/migrations/0002_mojaloop_callbacks.sql
```

The adapter rejects HTTP URLs, credentials in URLs, missing source/destination, unsupported algorithms, missing key/KID/CA, out-of-range timeouts, absent database/migration paths and absent listener/TLS values. `RS256`, `RS384` and `RS512` are accepted by the current local package; the partner profile must select and approve one.

## Local preflight

Run these checks before any external connection:

```bash
cd /home/ubuntu/blueeconomy-financial-controls
go test -race ./...
go vet ./...
govulncheck ./...
bash scripts/verify-mojaloop-local.sh
```

The local integration uses authentic PostgreSQL 16. It verifies callback reserve, exact replay, commit, terminal replay and regression rejection. It does not call a switch and therefore cannot validate participant conformance.

## Target startup sequence

First, confirm the target PostgreSQL database is reachable using TLS and apply migrations through the approved deployment process. Confirm that the runtime secret manager mounted the signing key, CA bundle, callback certificate and callback private key with the expected permissions. Verify the key’s public fingerprint and KID against the environment registry without printing private material.

Next, start the adapter with `cmd/mojaloop-adapter` in the approved non-production namespace. Verify that `/healthz` responds only on the intended listener and that the callback route is not reachable from unauthorized sources. Confirm that outbound DNS resolves only the registered switch host and that the egress policy denies unregistered destinations.

The first external call must be a non-financial capability or profile check agreed with the switch. Do not submit a transfer until the partner has confirmed source/destination headers, signature verification, body schema, test account and test-currency limits. Record request IDs, response codes, message IDs, KIDs and body hashes, but never retain credentials, raw tokens or sensitive account data.

## Conformance sequence

| Test | Action | Expected result | Gate condition |
|---|---|---|---|
| 1. TLS and identity | Establish the approved mTLS/CA connection and inspect peer certificate fingerprint. | Certificate chain, hostname and fingerprint match the registry. | Any mismatch is a Red stop. |
| 2. Outbound signature | Submit a controlled quote request using the approved profile body. | Partner accepts the FSPIOP signature and source/destination headers. | Signature mismatch blocks all further calls. |
| 3. Tamper detection | Change one signed body byte in a controlled negative test. | Partner rejects the request. | Acceptance of tampered content is a Critical failure. |
| 4. Quote response | Receive the profile-approved quote response/callback. | Request/quote IDs, source/destination and status are correlated durably. | Uncorrelated response blocks transfer tests. |
| 5. Transfer submission | Submit a sandbox-only transfer within the approved test limit. | Partner returns the documented asynchronous response. | No live-money or unbounded-value test is permitted. |
| 6. Callback signature | Partner sends `PUT /transfers/{transferID}` with the registered signature. | Callback is verified and persisted as `RESERVED`, `COMMITTED` or `ABORTED` according to the approved message. | Invalid signature or identity blocks acceptance. |
| 7. Exact replay | Deliver the same callback twice. | Second delivery is an idempotent replay, with no duplicate state effect. | Duplicate posting or duplicate audit effect is a Critical failure. |
| 8. Conflict replay | Reuse transfer ID with changed body or identity. | Adapter rejects the conflict and records evidence. | Acceptance is a Critical failure. |
| 9. Terminal regression | Send a different state after `COMMITTED` or `ABORTED`. | Adapter rejects the regression and retains the terminal state. | Any downgrade blocks the integration. |
| 10. Timeout recovery | Withhold a callback or force a controlled timeout. | Durable ambiguous/recovery state is created; no blind retry or ledger posting occurs. | Automatic duplicate settlement is a Critical failure. |
| 11. GET recovery | Query the partner’s authoritative transfer status using `GET /transfers/{transferID}`. | Response is signed, correlated and reconciled to internal state. | Unknown or conflicting status requires manual investigation. |
| 12. Reconciliation | Export the partner’s approved test statement and compare it with posted/voided internal intents. | No unexplained missing, extra, amount or currency findings. | Any finding blocks progression. |
| 13. Rate/size limits | Exercise documented rate, body-size and timeout boundaries. | Requests are bounded and errors are handled without process failure. | Unbounded behavior blocks deployment. |
| 14. Key rotation | Activate the approved next KID with overlap, then retire the old key. | New key verifies, old key remains valid only during overlap, and revocation is evidenced. | Missing rotation/revocation evidence blocks acceptance. |
| 15. Incident response | Revoke the test key or block the callback source. | Requests fail closed, alert routes fire and the runbook records containment. | No containment or alert is a Critical failure. |

## Evidence package

The test operator must retain a signed test manifest containing environment ID, switch/simulator version, adapter commit, container/image digests, test ID, UTC timestamps, request/response IDs, HTTP status, source/destination, KID, certificate fingerprints, body SHA-256 values, callback state before/after, database evidence reference, reconciliation result and operator signature. Raw tokens, private keys, unredacted account data and sensitive credentials must not be included.

The partner must countersign the conformance result. The Ministry security owner, financial-control owner, operations owner and independent reviewer must approve the evidence package before Gate 3 is considered passed. A sandbox pass does not authorize live funds.

## Failure and rollback

Any TLS, signature, source/destination, identity, replay, state regression, data-integrity, authorization, privacy or reconciliation failure stops the sequence. Disable the partner route, revoke the affected test key if compromise is suspected, preserve the signed evidence package, mark the transfer state ambiguous where necessary, and open the incident workflow. Never retry a request whose external outcome is unknown without first querying authoritative partner status and obtaining the required maker/checker decision.

Rollback means disabling the route and credentials, not deleting database evidence. PostgreSQL callback and intent records remain append-only and are retained according to the approved policy. Re-enable connectivity only after the independent reviewer verifies remediation and the accountable owners complete resume sign-off.

## References

[1]: https://docs.mojaloop.io/api/fspiop/v1.1/api-definition.html "Mojaloop FSPIOP API definition"
[2]: https://github.com/mojaloop/mojaloop-specification/blob/master/fspiop-api/documents/Signature_v1.1.md "Mojaloop FSPIOP Signature v1.1"
[3]: https://www.rfc-editor.org/rfc/rfc8705 "OAuth 2.0 Mutual-TLS Client Authentication and Certificate-Bound Access Tokens"
