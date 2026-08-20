#!/usr/bin/env python3
"""Local contract assertions for gateway OIDC claims and OPA PBAC invariants."""
from dataclasses import dataclass

@dataclass
class Subject:
    sub: str
    tenant_id: str
    aud: str
    roles: set[str]

def allow(subject: Subject, request_tenant: str, header_tenant: str | None, path: str) -> bool:
    return bool(
        subject.sub
        and subject.tenant_id.startswith("tenant-")
        and subject.aud == "blueeconomy-api"
        and request_tenant == subject.tenant_id
        and header_tenant is None
        and ("platform-admin" in subject.roles or ("s1-operator" in subject.roles and path.startswith("/v1/port/")))
    )

a = Subject("user-a", "tenant-a", "blueeconomy-api", {"s1-operator"})
assert allow(a, "tenant-a", None, "/v1/port/calls"), "matching tenant route must allow"
assert not allow(a, "tenant-b", None, "/v1/port/calls"), "cross-tenant resource must deny"
assert not allow(a, "tenant-a", "tenant-b", "/v1/port/calls"), "caller tenant override must deny"
assert not allow(Subject("user-a", "tenant-a", "other-api", {"s1-operator"}), "tenant-a", None, "/v1/port/calls"), "wrong audience must deny"
assert not allow(Subject("user-a", "tenant-a", "blueeconomy-api", {"s2-analyst"}), "tenant-a", None, "/v1/port/calls"), "role must deny"
print("GATEWAY_PBAC_CONTRACT_TESTS_PASSED: matching tenant allowed; cross-tenant/header/audience/role violations denied")
