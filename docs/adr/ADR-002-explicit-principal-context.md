# ADR-002 — Resolve an explicit principal context

- **Status:** Accepted
- **Date:** 2026-08-04
- **Related principle:** [Context Before Action](https://github.com/thegeenana/systems-must-not-lie/blob/main/principles/003-context-before-action.md)

## Context

A valid credential identifies a subject but does not prove tenant membership, role, entitlement or resource authority.

Allowing each controller or service to reconstruct these facts independently creates inconsistent authorization and makes decision evidence difficult to explain.

## Decision

Every protected action will require an immutable `PrincipalContext` produced by one resolution pipeline.

The resolver will derive authoritative context from:

- authenticated subject;
- active principal;
- requested tenant;
- active membership;
- action policy;
- role;
- tenant entitlement.

Client-provided roles, memberships and entitlements will never be accepted as authority.

Failure to resolve any required fact results in a stable denial decision.

## Truth preserved

No protected business action executes unless the system can identify who is acting, where they are acting, through which membership and with which relevant authority.

## Consequences

### Positive

- protected services receive one explicit context value;
- authorization decisions are consistent and auditable;
- tests can exercise resolution independently from business logic;
- correlation and decision identifiers travel with the request.

### Negative

- context resolution adds queries and latency;
- caching requires careful invalidation;
- public and system routes need explicit classification.

## Proof obligations

- [ ] Missing membership denies before business execution.
- [ ] Insufficient role denies before business execution.
- [ ] Missing entitlement denies before business execution.
- [ ] Client tenant tampering cannot create authority.
- [ ] Allowed and denied decisions are durably inspectable.
- [ ] No process-local cache is required after restart.

## Review trigger

Reconsider the shape of `PrincipalContext` when a new actor type cannot be represented without optional fields that weaken its invariants.
