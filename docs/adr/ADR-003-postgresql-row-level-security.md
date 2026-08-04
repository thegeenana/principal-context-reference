# ADR-003 — Enforce tenant isolation with PostgreSQL row-level security

- **Status:** Accepted
- **Date:** 2026-08-04

## Context

Application-level tenant predicates are necessary but vulnerable to omission. A repository method, native query or later feature can accidentally read or modify rows belonging to another tenant.

The reference needs to prove that isolation survives an incorrect or incomplete application query.

## Decision

Use PostgreSQL row-level security on every tenant-owned table.

The application will set a transaction-local tenant identifier after a `PrincipalContext` is resolved and before protected repository access.

Policies will compare `tenant_id` with:

~~~sql
current_setting('app.tenant_id', true)
~~~

The database role used by the application will not bypass row-level security.

## Truth preserved

A transaction operating for one resolved tenant cannot observe or change another tenant's protected rows, even when application code omits a tenant predicate.

## Consequences

### Positive

- database isolation provides defence in depth;
- cross-tenant leakage tests can exercise the final boundary;
- application mistakes fail closed.

### Negative

- connection-pool and transaction handling require care;
- administrative operations need a separately controlled path;
- local debugging becomes more explicit;
- policy migrations become security-sensitive changes.

## Proof obligations

- [ ] All tenant-owned tables have non-null tenant identifiers.
- [ ] The application role cannot bypass row-level security.
- [ ] Tenant context is transaction-local.
- [ ] A deliberately unscoped test query cannot return another tenant's row.
- [ ] Connections do not leak tenant context between transactions.
- [ ] Migration tests verify policies exist and remain enabled.

## Review trigger

Reconsider only if the chosen database cannot enforce the invariant or a verified operational requirement demands a different isolation boundary.
