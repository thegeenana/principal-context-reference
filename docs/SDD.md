# System Design Description

## 1. Purpose

Principal Context Reference demonstrates how a multi-tenant application can resolve and enforce the full operating context required for a protected business action.

The design separates four questions:

1. **Identity:** Who presented the credential?
2. **Context:** For which tenant and membership is the principal acting?
3. **Authority:** Which roles, entitlements and route policies permit the action?
4. **Isolation:** Which database rows may the action observe or change?

Authentication answers only the first question.

## 2. Scope

### In scope

- locally issued demo JWTs for repeatable proof;
- principals, tenants and active memberships;
- membership roles;
- tenant product entitlements;
- route-policy evaluation;
- explicit principal-context resolution;
- one protected resource capability;
- durable authorization-decision evidence;
- PostgreSQL row-level security;
- allowed, denied, cross-tenant and restart-safe proof journeys.

### Out of scope

- production identity-provider integration;
- user registration and password management;
- organization invitations;
- complex role administration;
- billing or subscription management;
- a general-purpose policy language;
- distributed microservices;
- private KTK1 or Mapato implementation details.

## 3. Actors

| Actor | Description |
|---|---|
| Demo issuer | Creates signed demonstration tokens in the demo profile only. |
| Principal | Authenticated human or machine identity. |
| Tenant member | Principal connected to a tenant through an active membership. |
| Operator | Principal permitted to inspect decision evidence. |
| Protected API | Example business capability requiring resolved context. |

## 4. Domain model

### Principal

Represents the stable authenticated subject.

Key fields:

- `principal_id`
- `subject`
- `display_name`
- `status`

### Tenant

Represents the organization boundary within which protected business activity occurs.

Key fields:

- `tenant_id`
- `tenant_key`
- `display_name`
- `status`

### Membership

Authoritatively connects one principal to one tenant.

Key fields:

- `membership_id`
- `principal_id`
- `tenant_id`
- `role`
- `status`
- `valid_from`
- `valid_until`

### Entitlement

Represents a capability currently available to a tenant.

Key fields:

- `tenant_id`
- `entitlement_key`
- `status`
- `valid_from`
- `valid_until`

### Route policy

Maps an application action to required roles and entitlements.

The first version uses policies declared in application code and covered by tests. A database-driven or external policy engine is intentionally out of scope.

### PrincipalContext

An immutable request-scoped value produced after resolution.

Planned fields:

- `correlationId`
- `decisionId`
- `principalId`
- `tenantId`
- `membershipId`
- `roles`
- `entitlements`
- `action`
- `resolvedAt`

### AuthorizationDecision

Durable evidence describing why an action was allowed or denied.

Key fields:

- `decision_id`
- `correlation_id`
- `principal_id`
- `tenant_id`
- `membership_id`
- `action`
- `outcome`
- `reason_code`
- `decided_at`

Sensitive credential material is never stored in the decision record.

### ProtectedResource

A deliberately small business record used to prove tenant isolation.

Key fields:

- `resource_id`
- `tenant_id`
- `name`
- `created_by_principal_id`
- `created_at`

## 5. Request resolution

For a protected request:

1. Validate the JWT and resolve its subject to an active principal.
2. Parse the requested tenant identifier.
3. Resolve the authoritative active tenant.
4. Resolve an active membership between principal and tenant.
5. Identify the route action.
6. Evaluate required role.
7. Evaluate required tenant entitlement.
8. Persist an authorization decision.
9. If denied, return the stable reason code.
10. If allowed, create an immutable `PrincipalContext`.
11. Begin the business transaction.
12. set a transaction-local PostgreSQL tenant context;
13. execute the protected repository operation;
14. commit the authoritative business result.

The client cannot supply membership, roles or entitlements as authority.

## 6. Denial model

Stable reason codes:

| Code | Meaning |
|---|---|
| `UNAUTHENTICATED` | No valid authenticated subject. |
| `PRINCIPAL_INACTIVE` | Subject resolves to an inactive principal. |
| `TENANT_NOT_FOUND` | Requested tenant does not exist or is inactive. |
| `MEMBERSHIP_REQUIRED` | No active membership connects principal and tenant. |
| `ROLE_REQUIRED` | Membership lacks the action's required role. |
| `ENTITLEMENT_REQUIRED` | Tenant lacks the required product capability. |
| `RESOURCE_NOT_ACCESSIBLE` | Resource is absent from the resolved tenant boundary. |

Responses must not disclose whether a cross-tenant resource exists.

## 7. Database isolation

Every tenant-owned table contains a non-null `tenant_id`.

PostgreSQL row-level-security policies compare each row's tenant identifier with a transaction-local setting:

~~~sql
current_setting('app.tenant_id', true)
~~~

The application sets the value inside the same transaction that performs business queries. Connections returned to the pool must not retain authoritative tenant context.

Application predicates remain useful for clarity and query planning, but row-level security is the final isolation boundary.

## 8. Transactions and evidence

An allowed decision and its business outcome require correlatable identifiers but do not necessarily belong in one table.

The implementation must make the ordering explicit:

- denial decisions are durable without a business transaction;
- allowed decisions are recorded before or with business execution;
- failed business execution must not be represented as successful;
- correlation connects the request, decision and outcome;
- restart must not require an in-memory relationship map.

The detailed transaction strategy will be finalized during implementation and captured in a follow-up ADR.

## 9. API behaviour

Every response includes a correlation identifier.

Denied responses use a stable envelope:

~~~json
{
  "correlationId": "uuid",
  "decisionId": "uuid",
  "outcome": "DENY",
  "reason": "MEMBERSHIP_REQUIRED"
}
~~~

Allowed resource creation returns the authoritative resource identifier and decision identifier.

## 10. Demonstration identity

The `demo` Spring profile exposes a token endpoint using predefined demonstration principals.

The endpoint:

- is disabled outside the demo profile;
- signs short-lived tokens;
- does not accept roles, memberships or entitlements as token authority;
- exists only to make the proof self-contained.

All authorization facts are resolved from PostgreSQL.

## 11. Verification strategy

### Unit tests

- policy matching;
- membership validity;
- entitlement validity;
- denial reason selection;
- principal-context immutability.

### Integration tests

- Flyway migrations;
- repositories against PostgreSQL;
- row-level-security policies;
- transaction-local tenant setting;
- decision persistence.

### End-to-end proof

The proof script must verify:

1. allowed create and retrieve;
2. missing membership denial;
3. missing role denial;
4. missing entitlement denial;
5. cross-tenant resource access blocked;
6. authorization evidence retrievable;
7. authoritative state survives restart.

## 12. Operability

The runtime will expose:

- liveness;
- readiness;
- build information;
- structured logs containing correlation and decision identifiers;
- no credentials or token contents in logs.

A healthy process is not treated as proof of a healthy business journey.

## 13. Delivery phases

### Phase 1 — Runtime foundation

Spring Boot, Maven, configuration, Docker Compose, PostgreSQL, Flyway and CI.

### Phase 2 — Authoritative model

Schema and domain model for principals, tenants, memberships, entitlements, resources and decisions.

### Phase 3 — Context resolution

JWT authentication, route actions, policy evaluation and immutable principal context.

### Phase 4 — Isolation and protected capability

PostgreSQL row-level security plus resource APIs.

### Phase 5 — Evidence and proof

Decision inspection, restart-safe script, negative journeys and release certification.

## 14. Definition of done

The design is implemented only when:

- the documented commands run from a clean checkout;
- all automated tests pass;
- the proof exercises real PostgreSQL;
- cross-tenant access fails at the database boundary;
- decision evidence explains allowed and denied outcomes;
- state and correlation survive runtime restart;
- documentation matches observed behaviour.
