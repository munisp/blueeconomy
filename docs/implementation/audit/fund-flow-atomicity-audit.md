# Fund-Flow Atomicity and Middleware Audit

**Verdict:** no flow-of-funds feature is implemented end to end. The repository contains a read-only TigerBeetle account-verification command. It cannot create an account, reserve funds, create/post/void a transfer, invoke Mojaloop, record a finance application, reconcile a provider statement, service a facility, reverse a payment, collect a repayment, calculate a fee, settle participants, or recover an ambiguous financial outcome.

> **No-loss and non-compromise guarantee:** impossible and not supported by the evidence. No responsible technical assurance process can guarantee that a financial platform can never be compromised or lose funds. This portfolio does not yet meet the lower threshold of an implemented, tested payment service.

## Executable financial surface

The Go command creates an official TigerBeetle client, performs exactly one `LookupAccounts` call for a runtime-supplied account ID, hashes the account reference, and writes selected account metadata to a local evidence file. There are no first-party calls to `CreateAccounts`, `CreateTransfers`, `LookupTransfers`, pending-transfer post/void operations or any Mojaloop API. There is no finance database schema or finance workflow worker.

| Control area | Required safe behavior | Actual implementation | Status |
|---|---|---|---|
| Durable intent | Generate and persist an immutable client transfer ID before any external call. | No payment intent model or durable transfer ID. | Absent |
| Authorization | Product eligibility, authority limits, maker/checker/quorum and conflict controls. | Generic stakeholder onboarding maker/checker is not a finance approval engine. | Absent |
| Ledger account model | Versioned legal-to-ledger mapping, currency/ledger/code constraints, account invariants. | Read-only account lookup; no account provisioning/mapping policy. | Absent |
| Reservation | Pending TigerBeetle transfer to reserve funds before downstream execution. | No pending transfer. | Absent |
| Payment orchestration | Mojaloop discovery, quotation/agreement, transfer, callback authentication and state machine. | No Mojaloop client, participant, scheme keys or transfer state. | Absent |
| Commit/void | Post only after authoritative success; void/expire on controlled failure. | No post/void/expiry path. | Absent |
| Idempotent retry | Reuse the same persisted transfer and payment IDs after timeout/restart. | No write path or restart-safe state. | Absent |
| Ambiguous outcome | Query provider and ledger authorities before deciding retry, post, void or investigation. | No lookup/recovery workflow. | Absent |
| Reconciliation | Match legal account, provider transfer, TigerBeetle transfer and settlement record; queue breaks. | No reconciliation data or workflow. | Absent |
| Reversal/refund | Authorized compensating transaction linked to original; never mutate history. | No reversal/refund path. | Absent |
| Repayment/fees | Fixed-point amounts, allocation order, over/under-payment and exception rules. | No facility, schedule, fee or allocation logic. | Absent |
| Settlement/liquidity | Participant positions, settlement windows, limits and settlement finality. | No participant/settlement model. | Absent |
| Fraud/AML/sanctions | Policy decisions, holds, case workflow, evidence and override controls. | No regulated financial compliance integration. | Absent |
| Accounting/reporting | Balanced sub-ledger reports tied to legal accounts and unresolved states. | Account metadata evidence only. | Absent |
| Disaster recovery | Proven restore, replay and reconciliation to authoritative state. | No financial persistence/workflow to restore. | Absent |

## Failure-scenario assessment

| Scenario | Required atomic/recovery pattern | Current outcome |
|---|---|---|
| Request is retried after client timeout | Same durable payment/transfer IDs; lookup authoritative state before retry. | No implementation. |
| Ledger reserve succeeds, provider call fails | Persist state; retry or void under a durable workflow; reconcile both systems. | No reserve, provider call or workflow. |
| Provider succeeds, local database write fails | Recover provider result by durable ID/callback; record and reconcile before further action. | No provider or finance database. |
| Mojaloop callback duplicated/out of order | Authenticate JWS/mTLS, enforce state transition and idempotency. | No callback endpoint/security/state model. |
| Service crashes between payment and ledger post | Temporal/recovery worker reconstructs state from authoritative IDs; never infer success. | Temporal is source-locked but not deployed or used. |
| Kafka delivery duplicates | Financial consumer uses idempotent business key and transactional/outbox semantics. | Kafka exists only for data-to-Delta ingestion, not fund flows. |
| Redis data is lost | Redis cannot be the financial source of truth; rebuild caches from durable stores. | Redis is not deployed or referenced by finance code. |
| Fluvio edge stream partitions | Funds must not depend on edge-stream availability; durable workflow and ledger authority govern. | Fluvio is not deployed or integrated. |
| TigerBeetle replica/failure event | Tested cluster topology, durable IDs, lookup/retry, operational recovery and reconciliation. | No deployed cluster or write test. |
| Reversal or refund requested | Compensating immutable transfer, authorization, original link and provider reconciliation. | No implementation. |
| Concurrent approval/payment attempts | Database uniqueness/locking plus workflow idempotency and ledger IDs. | No finance approval/payment model. |
| Amount/currency mismatch | Fixed-point value objects, currency-specific accounts and precondition checks. | No amount or currency logic. |

## Middleware truth table

| Middleware | Evidence | Financial atomicity role today |
|---|---|---|
| TigerBeetle | Official Go client; read-only `LookupAccounts`. | None for fund movement. |
| Mojaloop | Documentation/architecture references only; no source-lock entry in the active GitOps lock and no client code. | None. |
| Temporal | Helm artifact source-locked with explicit `source_locked_not_deployed` policy. | None. |
| Kafka | Real local data ingestion to Delta with manual post-persistence offset commit. | No finance topic, producer, consumer or atomic transaction. |
| Redis | Not deployed/integrated in the audited portfolio. | None. |
| Fluvio | Not deployed/integrated in the audited portfolio. | None. |
| Dapr | Helm artifact source-locked, not deployed; no finance components. | None. |
| APISIX/open-appsec | APISIX source-locked; no target routes or security-policy evidence. open-appsec is not deployed/integrated. | None. |
| PostgreSQL | Real local onboarding/evidence tests; no finance schema. | None. |
| Keycloak | Real local stakeholder invitation/group activation, not finance party/approval/payment authorization. | No fund authorization. |

## Authoritative comparison

TigerBeetle uses account/transfer identifiers as idempotency keys; a client should persist a generated transfer ID before submission and reuse it for retries. Pending transfers reserve amounts and can be posted, voided or expire, with immutable resolution records.[1] [2] Mojaloop uses asynchronous discovery, quotation/agreement and transfer phases, and its invariants include idempotent transfer APIs, authenticated/signed messages, fixed-point arithmetic, persistence before financially meaningful acceptance responses, deterministic finalized outcomes and recovery to consistent state.[3] [4]

None of those write-side patterns is implemented in this portfolio. Consequently, the **financial-integrity production-readiness score is 2/100**: credit is limited to using the official TigerBeetle client and failing closed when connection configuration is absent. The score is not evidence that any payment can be safely executed.

## Mandatory conditions before any money moves

No financial endpoint should be exposed until the Ministry and regulated partners approve the programme rules, legal account model, participant identities, Mojaloop scheme/security profiles, TigerBeetle chart/topology, amount/currency model, maker/checker/quorum matrix, sanctions/fraud controls, four-record reconciliation contract, settlement rules, reversal/refund policy, recovery objectives, operational ownership and independent security/financial-control assurance. A non-production environment must then pass duplicate, timeout, crash, callback-order, partial-success, ledger/provider divergence, restore and reconciliation tests before any production pilot.

## References

[1]: https://docs.tigerbeetle.com/coding/reliable-transaction-submission/ "TigerBeetle Reliable Transaction Submission"
[2]: https://docs.tigerbeetle.com/coding/two-phase-transfers/ "TigerBeetle Two-Phase Transfers"
[3]: https://docs.mojaloop.io/product/features/transaction.html "Mojaloop Transaction Flow"
[4]: https://docs.mojaloop.io/community/standards/invariants.html "Mojaloop Invariants"
