# Principal Context Reference

**A public reference implementation for resolving and enforcing tenant, principal, membership, role, entitlement, route-policy and data-isolation context.**

> Authentication tells a system who presented a credential. It does not, by itself, establish where that principal may act or what that principal may do.

This project turns the [Context Before Action](https://github.com/thegeenana/systems-must-not-lie/blob/main/principles/003-context-before-action.md) principle into independently runnable technical proof.

## Status

**Current phase: design foundation**

The problem statement, invariants, system design and architecture decisions are being established before implementation. No runnable application is claimed yet.

Track implementation through the repository issues.

## The problem

Many SaaS applications authenticate a user and then trust a tenant identifier supplied in a path, header or token. That shortcut confuses identity with authority.

A protected business action may depend on:

- the authenticated principal;
- the selected tenant;
- active membership;
- role or delegated authority;
- product entitlement;
- route policy;
- resource ownership;
- the database isolation boundary.

This reference demonstrates how those facts can be resolved explicitly before business execution.

## Intended request path

~~~text
Request
  → Authentication
  → Requested tenant resolution
  → Active membership
  → Role policy
  → Entitlement
  → PrincipalContext
  → Database tenant boundary
  → Business action
  → Decision audit
~~~

## Security invariants

1. Client-supplied tenant identifiers are requests, not proof of authority.
2. Protected business code cannot execute without a resolved `PrincipalContext`.
3. Missing or ambiguous context results in denial.
4. Tenant isolation is enforced in both application logic and PostgreSQL.
5. A role does not imply every product entitlement.
6. Authorization decisions produce durable, correlatable evidence.
7. Process-local memory is never authoritative business state.
8. Cross-tenant access must fail even when an application query is incorrect.

## Planned reference journeys

| Journey | Expected result |
|---|---|
| Valid principal, membership, role and entitlement | Allowed |
| Valid principal without tenant membership | Denied |
| Active membership with insufficient role | Denied |
| Correct role without required entitlement | Denied |
| Client changes tenant identifier | Denied |
| Application attempts cross-tenant record access | Blocked by PostgreSQL |
| Service restarts after resource creation | Authoritative state survives |
| Decision is inspected by correlation identifier | Evidence explains the outcome |

## Planned technology

- Java 25
- Spring Boot 4
- PostgreSQL with row-level security
- Flyway migrations
- Maven
- OpenAPI
- Docker Compose
- JUnit and Testcontainers
- GitHub Actions

The design is deliberately a modular monolith so the example remains understandable while preserving explicit boundaries.

## Planned modules

~~~text
principal-context-reference/
├── app/             # Runtime assembly and configuration
├── identity/        # Authenticated principal boundary
├── tenancy/         # Tenant and membership model
├── authorization/   # Roles, entitlements and route policy
├── context/         # PrincipalContext resolution pipeline
├── resources/       # Example protected business capability
├── audit/           # Durable decision evidence
└── database/        # Migrations and isolation policy
~~~

## Planned API

~~~http
POST /demo/tokens
GET  /v1/context
POST /v1/tenants/{tenantId}/resources
GET  /v1/tenants/{tenantId}/resources/{resourceId}
GET  /v1/authorization-decisions/{decisionId}
~~~

The demo token endpoint will exist only in the documented demo profile. It is not a production identity provider.

## Definition of real

Version `v0.1.0` will not be declared complete until a stranger can run:

~~~bash
docker compose up --build
./scripts/prove-principal-context.sh
~~~

The proof must exercise allowed, denied, cross-tenant and restart-safe journeys against the real PostgreSQL boundary.

## Documentation

- [System Design Description](docs/SDD.md)
- [ADR-001: Use a modular monolith](docs/adr/ADR-001-modular-monolith.md)
- [ADR-002: Resolve an explicit principal context](docs/adr/ADR-002-explicit-principal-context.md)
- [ADR-003: Enforce isolation in PostgreSQL](docs/adr/ADR-003-postgresql-row-level-security.md)

## Relationship to private products

This is an independent educational reference implementation. It is not a source release, extraction or disguised copy of KTK1, Mapato or any customer system.

The repository demonstrates general engineering principles while preserving private product intellectual property.

## Author

Created by [George Wiafe](https://github.com/thegeenana), Product & Solutions Architect.

---

**Context before action. Proof before claims.**
