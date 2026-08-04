# Phase 1 implementation status

This branch implements the runtime foundation for issue #1.

## Locally verified

- required file structure;
- declared Java 25 and Spring Boot 4.1.0 baseline;
- database and application configuration alignment;
- readiness probe wiring;
- Flyway baseline presence;
- CI workflow coverage.

Run:

~~~bash
bash ./scripts/verify-foundation.sh
~~~

## CI obligations

The following claims require Java 25, Maven and Docker and must pass in GitHub Actions before issue #1 is closed:

~~~bash
mvn --batch-mode verify
docker compose config --quiet
docker compose up --build --wait
curl --fail --silent http://localhost:8080/actuator/health/readiness
~~~

This document intentionally distinguishes structural verification from executable runtime proof.
