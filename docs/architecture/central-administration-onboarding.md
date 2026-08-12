# Central Administration and Stakeholder Onboarding Architecture

## Decision

The Ministry portal will become the **central administrative entry point**, but it will not create or store a competing user directory. **Keycloak remains the authoritative identity system.** A Go `admin-service`, exposed only through the approved API edge, will record onboarding requests and approvals in PostgreSQL, then invoke only the approved Keycloak Administrative REST operations through a dedicated least-privilege service account. The administrator’s own OIDC token and the admin-service’s action evidence make each outcome attributable.

Keycloak’s documented Administrative REST API supports organization creation and membership, new/existing-user invitations, user creation, and group/realm/client role mapping. The design uses those supported operations rather than undocumented browser automation or a bespoke credential path. [1]

## Control flow

| Step | Responsible actor/system | Required control |
|---|---|---|
| Submit stakeholder request | Authenticated Ministry administrator or approved organisation administrator | API edge validates OIDC token; admin service validates that the requested organisation and service-role catalogue entry are allowed. |
| Persist request | Admin service and PostgreSQL | Store only the request, requested access, approver, state and non-secret evidence; do not store passwords, refresh tokens or private keys. |
| Approve or reject | A distinct stakeholder-onboarding approver | Enforce a maker/checker rule: the requester cannot approve their own request. Record immutable decision history. |
| Invite or attach user | Admin service and Keycloak | On approval, use Keycloak organization invitation/member APIs. Keycloak sends registration or invitation flow according to its configured identity lifecycle. [1] |
| Assign access | Admin service and Keycloak | Map only pre-approved organization/service groups and roles from the published Ministry role catalogue. Group/service role assignment remains authoritative in Keycloak. [1] |
| Publish evidence | Admin service, audit contract, Wazuh/OpenSearch | Emit a privacy-minimised audit event; retain request ID, action, result, actor reference, target reference and Keycloak result metadata. |

## Role catalogue

| Role | Authority | Separation of duties |
|---|---|---|
| `platform.admin` | Manage non-identity platform configuration and view central administration status. | Cannot directly bypass onboarding approval. |
| `stakeholder.onboarding.request` | Submit a stakeholder/user access request for permitted organisations and service roles. | Cannot approve own request. |
| `stakeholder.onboarding.approve` | Approve/reject requests within delegated organisation/service scope. | Must differ from requester. |
| `identity.provision` | Held by the admin-service service account; invokes only allow-listed Keycloak administrative operations. | Not assigned to interactive users. |
| `service.access.manage` | Maintains the approved role catalogue and mappings after Ministry governance approval. | Role-catalogue changes are separately audited. |
| `audit.read` | Views redacted onboarding evidence and operational state. | Cannot create, approve or provision access. |

## Minimum runtime configuration

The deployment must provide, by approved secret delivery, the Keycloak issuer/realm and administrative API base URL, discovery metadata, admin-service client identity, client authentication method, trusted CA chain, PostgreSQL connection, role catalogue, organization identifiers, APISIX route policy, Keycloak service-account permissions and audit/event endpoint. No hard-coded realm, client, role, organization, e-mail address or API endpoint is permitted.

## Integration gate

The central administration feature is not live until the Ministry has configured a genuine non-production Keycloak realm, approved service account, real organizations/groups/roles, PostgreSQL instance, API edge route, two distinct test operators, outbound invitation delivery policy, logging/retention controls and a reviewed privacy impact assessment. The target-side test must demonstrate successful request, distinct approval, invitation, group/role assignment, self-approval denial, unauthorised request denial, audit evidence and revocation/rollback.

## Reference

[1] [Keycloak Administrative REST API](https://www.keycloak.org/docs-api/latest/rest-api/index.html)
