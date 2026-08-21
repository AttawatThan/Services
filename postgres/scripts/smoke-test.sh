#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "${script_dir}/.." && pwd)"

export COMPOSE_PROJECT_NAME=dataplatform-postgres-smoke
export POSTGRES_VERSION=18.4
export POSTGRES_USER=smoke_user
export POSTGRES_PASSWORD=smoke-password-only
export POSTGRES_DB=smoke_db
export POSTGRES_PORT=55432

cleanup() {
  docker compose --project-directory "${project_dir}" down --volumes --remove-orphans
}
trap cleanup EXIT

docker network inspect dataplatform-metadata >/dev/null 2>&1 \
  || docker network create dataplatform-metadata >/dev/null

docker compose --project-directory "${project_dir}" up --build -d --wait

docker compose --project-directory "${project_dir}" exec -T postgres-data \
  psql -v ON_ERROR_STOP=1 -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" <<'SQL'
CREATE TABLE persistence_check (
  id integer PRIMARY KEY,
  payload text NOT NULL
);
INSERT INTO persistence_check VALUES (1, 'postgres-18.4-volume-ok');
SQL

docker compose --project-directory "${project_dir}" restart postgres-data
docker compose --project-directory "${project_dir}" up -d --wait postgres-data

persisted_value="$({
  docker compose --project-directory "${project_dir}" exec -T postgres-data \
    psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -Atqc \
    'SELECT payload FROM persistence_check WHERE id = 1;'
} | tr -d '\r')"

test "${persisted_value}" = "postgres-18.4-volume-ok"

docker compose --project-directory "${project_dir}" exec -T postgres-data \
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -Atqc \
  "SELECT current_setting('server_version'), current_setting('data_directory');"

echo "PostgreSQL persistence smoke test passed."
