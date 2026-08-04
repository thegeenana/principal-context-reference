#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

required=(
  pom.xml
  Dockerfile
  compose.yaml
  src/main/java/io/github/thegeenana/principalcontext/PrincipalContextApplication.java
  src/main/resources/application.yml
  src/main/resources/db/migration/V1__runtime_foundation.sql
  src/test/java/io/github/thegeenana/principalcontext/PrincipalContextApplicationTests.java
  .github/workflows/ci.yml
)

for path in "${required[@]}"; do
  if [[ ! -s "$path" ]]; then
    echo "missing required foundation file: $path" >&2
    exit 1
  fi
done

grep -q '<java.version>25</java.version>' pom.xml
grep -q '<version>4.1.0</version>' pom.xml
grep -q 'postgres:18-alpine' compose.yaml
grep -q '/actuator/health/readiness' compose.yaml

echo "Principal Context Phase 1 structure: PASS"
echo "Compilation and container startup: deferred to CI (Java 25, Maven and Docker required)"
