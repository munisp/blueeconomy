# Maritime-Feed Pipeline Rollback and Disaster-Recovery Validation Procedure

**Scope:** Ministry-controlled non-production S2 maritime-feed pipeline: authorised feed ingress, feed-source identity/key controls, incident/outbox persistence, Kafka publication, event-time/rule processing, Delta/lakehouse persistence, spatial/analyst workflows, object storage, identity edge, and observability.

## Control boundary

This procedure is executable only after the Ministry, the feed owner, the platform SRE owner, the data owner, the security/SOC owner, and the analyst owner approve the test window, fault scope, rollback plan, RPO/RTO, contact tree, data set, and evidence location. The tests must use the real authorised non-production topology; a local replay or simulated assertion is not acceptable evidence.[1] [2]

All target actions must be invoked through the approved case runner used by `run-maritime-feed-target-tests.sh`. The runner must not receive credentials from Git or write raw feed payloads, tokens, private keys, or restricted operational evidence to the result bundle.

> **Rollback principle:** freeze new promotion, preserve immutable evidence and source/event identities, restore service availability through approved GitOps/versioned configuration, then reconcile from durable state. Do **not** delete Delta rows, rewrite source evidence, silently reset Kafka offsets, or replay an event without retaining provenance and idempotency evidence.

## 1. Pre-execution validation

| Step | Required action | Passing criterion | Retained evidence |
|---:|---|---|---|
| 1 | Record approved change/fault authorisation, runbook reference, target identifier, UTC window, escalation contacts, and stop authority. | All accountable owners approve the scope and abort criteria. | Change record, manifest, approval references. |
| 2 | Confirm immutable release identities for service, publisher, Kafka/Flink rules, schemas, infrastructure, and data-product configuration. | Current and rollback release digests/versions are known and compatible with retained events. | Release manifest, image/source digests, migration/schema compatibility decision. |
| 3 | Establish measurable RPO/RTO and baseline health: feed admission latency, Kafka topic/consumer lag, outbox backlog, workflow state, Delta version/count/hash, map/analyst availability, alert route. | Baseline is within approved service objective and all dependencies are healthy. | Time-stamped baseline dashboard/export and readiness checklist. |
| 4 | Verify backup/PITR points, object-store recovery location, Kafka topic/ACL/schema configuration, and approved rollback/replay operators. | Recovery assets are reachable and authority is assigned without exposing secrets. | Backup catalog/PITR checkpoint, ACL/access review, recovery contact confirmation. |
| 5 | Select only approved non-production feed records and classify them. | Data-use, retention, cleanup, and export conditions are approved. | Data-authority approval and redacted fixture/reference list. |

## 2. Deployment rollback validation

| Step | Required action | Passing criterion | Required automated case |
|---:|---|---|---|
| 1 | Trigger a controlled failed/canary release or explicit operator abort according to the approved change plan. | Release is halted before unapproved propagation; change is traceable. | `deployment_rollback` |
| 2 | Freeze further promotion and record the last known-good GitOps revision, service image digest, rule/schema version, and config revision. | The rollback target is deterministic and approved. | `deployment_rollback` |
| 3 | Use the approved GitOps rollback mechanism to restore the last known-good compatible release. Never roll back a schema/state migration unless its approved reverse/forward recovery plan is executed. | Kubernetes readiness, network policy, API route, mTLS, OIDC, and workload identity return to the approved state. | `deployment_rollback` |
| 4 | Run feed admission, outbox publication, Kafka consumer, Delta persistence, spatial rule, and analyst-readiness probes using the approved record set. | All probes return expected allow/deny results; no bypass route or unauthorised source is admitted. | `post_rollback_contract_validation` |
| 5 | Compare baseline with post-rollback state and decide either controlled continuation or incident escalation. | RTO achieved; any data exposure, data loss, duplicate, or inconsistent rule output is a failed test and blocks promotion. | `post_rollback_contract_validation` plus owner decision. |

## 3. Failure-domain and service recovery validation

| Scenario | Controlled action | Expected safe result | Required measurement |
|---|---|---|---|
| Kubernetes worker/failure-domain loss | Remove one approved worker/failure domain or simulate its unavailability through the authorised platform mechanism. | Disruption budgets, scheduling, service discovery, and workload recovery meet the approved availability objective; no unauthorised route opens. | Recovery time, ready replicas, error rate, Kafka lag, workload events. |
| Feed gateway or partner route outage | Disable the authorised test route for the approved period. | Alerting, retry/backoff/circuit policy, and operator escalation activate; admitted events are neither silently lost nor duplicated when connectivity returns. | Outage timeline, alert/case, retry count, backlog, reconciliation. |
| Publisher/consumer/rule interruption | Stop the approved outbox publisher, Kafka consumer, or Flink/rule component at a controlled point. | Durable state preserves event identity; restart resumes safely; offset/checkpoint and idempotency controls prevent double case/Delta effects. | Outbox state, offsets/checkpoints, post-restart counts/hashes, trace. |
| Object-storage access failure | Deny the approved workload access to the non-production object store. | Access denial is detected and alerted; no unapproved fallback or plaintext export occurs; recovery restores controlled access and lineage. | IAM/access event, alert, recovery trace, access review. |
| OIDC/key/revocation event | Rotate an approved signing key/certificate and revoke a source/role in accordance with policy. | Valid rotated identity works; expired/revoked key/source/role is denied and audited; no cached authorisation permits unauthorised access. | Key/role change record, positive/negative results, audit/SOC evidence. |
| Observability retention continuity | Interrupt/recover an approved log/telemetry path or node while preserving the test boundary. | Wazuh/OpenSearch/SOC evidence remains queryable as required; gap is detected, owned, and reconciled. | Retention/ingestion status, alert, search result, remediation record. |

## 4. PostgreSQL recovery to the approved RPO

The PostgreSQL recovery exercise must use the approved CloudNativePG/PostgreSQL backup and PITR process. It must restore to a **separate authorised recovery target** unless the Ministry change authority explicitly approves an in-place non-production recovery. No test may overwrite the only retained test evidence or the live target used by another team.[1]

| Step | Required action | Passing criterion |
|---:|---|---|
| 1 | Record pre-fault incident IDs, source-event identities, admission evidence, outbox rows, case status, and timestamp/LSN boundary. | A reconciliation ledger exists before inducing the fault. |
| 2 | Create a controlled failure after an approved event is durably admitted and at a separately recorded outbox/publication point. | The precise recovery boundary is known; no uncontrolled data is introduced. |
| 3 | Restore backup/PITR to the approved recovery point and measure elapsed time. | Recovery meets approved RPO/RTO; immutable source/evidence fields remain unchanged. |
| 4 | Re-run only the authorised reconciliation logic against durable identities. | Missing durable items are identified; no existing incident or evidence row is mutated; exact replay is idempotent; conflicting replay is rejected. |
| 5 | Obtain database/platform/data-owner comparison and disposition. | Counts, identifiers, hashes, outbox state, and audit records reconcile, or a defect/waiver is formally opened. |

The automated case name is `postgresql_restore_to_rpo`. Its result must include redacted evidence references for pre-fault state, backup/PITR point, elapsed recovery time, reconciliation output, and owner approval.

## 5. Kafka, outbox, and replay reconciliation

The existing service boundary establishes durable incident/outbox state before Kafka publication and records publication completion only after broker acknowledgement. Target validation must prove that a delivery interruption does not cause an untracked loss or duplicate downstream business effect.[3]

| Step | Required action | Passing criterion |
|---:|---|---|
| 1 | Capture outbox identity, source event ID, incident ID, Kafka topic/partition/offset where available, consumer group/checkpoint, and downstream Delta identity before the controlled interruption. | A unique end-to-end reconciliation key exists. |
| 2 | Interrupt publication after durable outbox claim or broker hand-off using the approved test mechanism. | State is visible as pending/claimed/unknown under approved policy; no manual offset reset or unrecorded retry occurs. |
| 3 | Restart publisher/consumer using the approved runbook. | Event is delivered/replayed according to the idempotency contract; broker acknowledgement and outbox result become consistent. |
| 4 | Reconcile source admission → incident/outbox → Kafka → consumer/rule → Delta/case using immutable identity and content hash. | Exactly one authorised logical effect; duplicates are accounted for as replays, and conflict is fail-closed. |
| 5 | Review lag, retry age, dead-letter/quarantine, and exception queue. | No unowned item exceeds the approved threshold; recovery outcome has owner sign-off. |

The automated case name is `kafka_replay_reconciliation`.

## 6. Delta/lakehouse reprocessing and lineage validation

Delta tables are append-only evidence stores. Recovery therefore requires a controlled reprocessing run, not destructive correction. Reprocessing should use the approved bronze/silver/gold boundary and preserve the original source/event identity, input hash, rule version, and lineage link.[1]

| Step | Required action | Passing criterion |
|---:|---|---|
| 1 | Select the authorised recovery range by durable event identity/time boundary and record the baseline Delta table version, row count, content hashes, lineage, and quality result. | Scope is explicit and export/disclosure conditions are approved. |
| 2 | Reprocess to the approved recovery target or versioned staging output using the approved code/rule/schema versions. | Original data is not overwritten; reprocessing is traceable and access controlled. |
| 3 | Compare counts, event IDs, immutable content, event-time handling, geospatial joins, rule outputs, and uncertainty/provenance fields. | Exact replay has no duplicate logical result; any incompatible content is rejected/quarantined. |
| 4 | Promote/merge only through the approved data-governance change process after review. | Delta history, lineage, quality report, and owner approval are retained. |

The automated case name is `delta_reprocessing_lineage`.

## 7. Identity, source-key, and access rollback validation

| Step | Required action | Passing criterion |
|---:|---|---|
| 1 | Register/confirm the authorised source identity and current verification key through the approved source lifecycle. | Valid source is admitted only with approved identity and signature. |
| 2 | Rotate to an approved replacement key/certificate with a documented grace window, where policy permits. | New key succeeds; previous key works only through its explicit grace period. |
| 3 | Expire/revoke the old key, source, or operator role and try a formerly valid request/access path. | Revoked identity is denied; no durable feed event, map layer, export, or case update occurs; audit/SOC evidence exists. |
| 4 | Roll back only the identity configuration change that was approved for the test, if needed. | Restored identity configuration is explicit, audited, and does not re-enable a compromised/revoked credential. |

The automated case name is `oidc_key_rotation_and_revocation`.

## 8. Final acceptance and evidence validation

Run `validate-maritime-feed-dr-evidence.sh --artifact-dir <authorised-run-artifact-directory>` after the approved runner has completed every required DR case. The validator verifies structural completeness, expected case identities, passed status, evidence references, and the absence of sensitive field names. It does not replace owner acceptance.

The final review must include the feed owner, Ministry platform SRE owner, database owner, data governance owner, security/SOC owner, and analyst/service owner. Acceptance requires measured RPO/RTO, reconciliation proof, no unresolved critical security/data integrity finding, updated runbooks, retained artefacts, and a signed go/no-go or defect/waiver record.[1] [2]

## References

[1]: https://github.com/munisp/blueeconomy/blob/25f31be3ea5a8ada470e8a4b2838bc488a9f1d42/docs/implementation/target-verification-gates.md "Target-Side Verification Gates"
[2]: https://github.com/munisp/blueeconomy/blob/25f31be3ea5a8ada470e8a4b2838bc488a9f1d42/docs/implementation/integration-gates.md "Verified Integration Gates"
[3]: https://github.com/munisp/blueeconomy-maritime-intelligence/blob/cc00b9a/scripts/verify-kafka-outbox.sh "Maritime Kafka Outbox Verification Harness"
