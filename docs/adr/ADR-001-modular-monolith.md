# ADR-001 — Use a modular monolith

- **Status:** Accepted
- **Date:** 2026-08-04

## Context

The reference must demonstrate identity, tenancy, authorization, context resolution, audit evidence and database isolation without hiding the important relationships behind distributed infrastructure.

Microservices would introduce network boundaries, deployment coordination and eventual-consistency concerns that are not required to prove the central principle.

A single unstructured application, however, would make the boundaries difficult to inspect.

## Decision

Implement the reference as a Spring Boot modular monolith.

Modules will have explicit responsibilities and dependencies:

- identity;
- tenancy;
- authorization;
- context;
- protected resources;
- audit;
- application assembly.

Internal APIs and package boundaries will prevent business modules from bypassing context resolution.

## Truth preserved

The runtime topology must not imply stronger modular independence than the code actually enforces.

## Consequences

### Positive

- one command starts the reference;
- transactions and database isolation remain visible;
- tests can exercise the real boundary with lower operational cost;
- module responsibilities remain explicit.

### Negative

- the example does not demonstrate distributed authorization;
- process boundaries cannot enforce module ownership;
- discipline and architecture tests are required.

## Proof obligations

- [ ] Architecture tests enforce permitted module dependencies.
- [ ] Protected repositories are not reachable from unauthorised entry points.
- [ ] Docker Compose starts one application runtime and PostgreSQL.
- [ ] End-to-end proof runs from a clean checkout.

## Review trigger

Reconsider only if a required proof cannot be expressed honestly without a process boundary.
