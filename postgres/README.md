# Data Platform PostgreSQL

Dedicated PostgreSQL 18.4 image and Compose project for persistent application
and business data. It is independent from Airflow's PostgreSQL metadata database.

## Image and storage

| Item | Value |
| --- | --- |
| Image | `dataplatform-postgres:18.4` |
| Base image | `postgres:18.4` |
| Service hostname | `postgres-data` |
| Container port | `5432` |
| Persistent volume | `dataplatform-postgres_postgres-data` |
| PostgreSQL data directory | `/var/lib/postgresql/18/docker` |

PostgreSQL 18 changed the official image volume to `/var/lib/postgresql` and
uses a versioned cluster directory below it. The Compose file follows that layout.

## Start

Create the shared network once if it does not already exist:

```bash
docker network inspect dataplatform-metadata >/dev/null 2>&1 || \
  docker network create dataplatform-metadata
```

Create the local environment file and set a strong password:

```bash
cp .env.example .env
```

Then build and start the database:

```bash
docker compose up --build -d --wait
docker compose ps
```

Host applications connect to `localhost:5432` by default. Containers attached
to `dataplatform-metadata` connect to `postgres-data:5432`. Override
`POSTGRES_PORT` in `.env` if port 5432 is already occupied on the host.

## Verify

```bash
docker compose exec postgres-data \
  psql -U dataplatform -d dataplatform -c 'select version();'
```

Run the isolated persistence test with:

```bash
./scripts/smoke-test.sh
```

The test uses its own Compose project and volume, writes a row, restarts the
container, verifies the row, and removes only its temporary test resources.

## Backup and restore

Create a compressed logical backup on the host:

```bash
docker compose exec -T postgres-data \
  pg_dump -U dataplatform -d dataplatform -Fc > backups/dataplatform.dump
```

Restore it into an initialized database:

```bash
docker compose exec -T postgres-data \
  pg_restore -U dataplatform -d dataplatform --clean --if-exists \
  < backups/dataplatform.dump
```

`docker compose down` stops and removes the container while preserving the named
volume. Never use `docker compose down -v` unless all stored data may be deleted.
Major PostgreSQL upgrades require `pg_upgrade`, logical replication, or a logical
dump and restore; data files from different major versions are not interchangeable.
