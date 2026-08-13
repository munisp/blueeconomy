# Authoritative Financial Middleware Findings

## TigerBeetle

Source: https://docs.tigerbeetle.com/coding/two-phase-transfers/

TigerBeetle pending transfers reserve amounts in pending debit/credit fields without changing posted fields. A pending transfer can be posted, voided, or expire; it can be resolved only once. Resolution creates a new immutable transfer referencing the pending transfer. Account invariants are checked when the reservation is created.

Source: https://docs.tigerbeetle.com/coding/reliable-transaction-submission/

Account and transfer IDs are idempotency keys. The initiating client should generate and persist the transfer ID before submission and reuse the same ID for retries and restarts. TigerBeetle reports whether the object was created or already existed.

## Mojaloop

Source: https://docs.mojaloop.io/product/features/transaction.html

Mojaloop transactions are asynchronous and use discovery, quotation/agreement-of-terms, and transfer phases. Transaction uniqueness/idempotency prevents duplicate processing. The hub clears payments between participants and integrates with settlement; it does not by itself implement application, underwriting, or programme-specific business rules.

Source: https://docs.mojaloop.io/community/standards/invariants.html

Relevant invariants include idempotent transfer APIs, deterministic finalized outcomes, signed and authenticated messages, mTLS plus JWS/non-repudiation controls, fixed-point arithmetic, persistence before financially meaningful acceptance responses, final-transfer record retention, and recovery to consistent state. Mojaloop separates use-case setup/business rules from policy-free transfer execution. The cited page describes the hub as the final transfer-status authority under scheme rules and requires infrastructure/deployment resilience for national payment-system use.

## Audit implication

A read-only TigerBeetle account lookup does not implement reserve/post/void, client-generated durable transfer IDs, provider/payment-rail orchestration, reconciliation, ledger-account mapping, legal-account matching, settlement, reversal, or ambiguity recovery. Source-pinning Mojaloop is not equivalent to deploying a participant, switch, scheme rules, security keys, settlement model, fraud controls, or operational governance.

## IMO Maritime Single Window

Source: https://www.imo.org/en/ourwork/facilitation/pages/maritimesinglewindow-default.aspx

Since 1 January 2024, IMO Member States have been required to use Maritime Single Windows for electronic port information exchange. Public authorities must establish, maintain and use an MSW for ship arrival, stay and departure information and coordinate transmission so data is submitted once and reused as far as possible. The IMO Compendium supplies a shared data set/reference model for interoperability. IMO also publishes authentication, integrity and confidentiality guidance for MSW exchanges.

Audit implication: an immutable evidence index and PostgreSQL receipt store are valuable S1 foundations, but they do not constitute an MSW or S1 end-to-end service without authoritative port-call schemas, ship/authority interfaces, one-time submission/reuse, signed receipts, exception workflows, role-controlled status tracking, NSW/PCS conformance, and operational acceptance.

## Verifiable Credential Lifecycle

Sources:
- https://www.w3.org/TR/vc-data-model-2.0/
- https://www.w3.org/TR/vc-bitstring-status-list/
- https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0.html

The W3C Verifiable Credentials Data Model 2.0 defines issuer, holder, subject, verifier and data-registry roles; conforming credentials/presentations require the relevant required properties and a securing mechanism. Cryptographic verifiability does not establish the truth of claims: verifier policy must evaluate the issuer, proof, subject and claims. The W3C Bitstring Status List specification defines privacy-preserving suspension/revocation status publication. OpenID4VCI defines an OAuth-protected issuance API, issuer metadata, credential endpoints, wallet authorization, credential offers, holder/key binding options and immediate/deferred issuance.

Audit implication: the current TypeScript JWT/JWKS verifier proves only a narrow issuer-signature/audience/token validation boundary. It is not a complete S4 service because it lacks an issuer trust registry, credential schema governance, authorized issuance, holder wallet, verifiable presentation flow, status/revocation/suspension processing, renewal/revalidation, selective disclosure, verifier-purpose logging, recovery and issuer/holder acceptance evidence.

## FAO Fisheries and Aquaculture Traceability

Source: https://openknowledge.fao.org/handle/20.500.14283/cc5484en

FAO's 2023 guidance is specifically concerned with advancing end-to-end traceability through agreed critical tracking events (CTEs) and key data elements (KDEs) across capture fisheries and aquaculture value chains. Regional consultations confirmed the relevance of comprehensive CTEs/KDEs while emphasizing flexibility and equivalence for developing-country and small-scale producer contexts.

Audit implication: the committed traceability schema and validator implement a bounded ordered single-lot event chain for five event types, but do not implement end-to-end fisheries/aquaculture traceability profiles, participant/facility/vessel/device registration, species and quantity KDEs, parent-child lot split/merge/transformation, mass balance, custody acknowledgements, sensor calibration/cold-chain rules, inspections, holds/recalls, offline signing/reconciliation, or agency partner conformance.
