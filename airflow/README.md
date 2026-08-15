# Data Platform Airflow

This local stack runs Airflow as the only ingestion orchestrator for OpenMetadata.
The OpenMetadata-managed ingestion service remains disabled.

## Compatibility matrix

| Component | Version |
| --- | --- |
| Airflow | `3.2.2` |
| Python | `3.10` |
| OpenMetadata server | `1.13.3` |
| `openmetadata-ingestion` | `1.13.3.0` |
| Airflow OpenLineage provider | `2.17.0` |

The image installs the PostgreSQL, Kafka, and S3 extras. REST/OpenAPI ingestion is
part of the base `openmetadata-ingestion` package. It intentionally does not
install `openmetadata-managed-apis`, because OpenMetadata does not manage this
Airflow instance.

## Start the services

Create the shared network once so the two Compose projects can resolve each
other by service name:

```bash
docker network create dataplatform-metadata
```

Copy `.env.example` to `.env` and generate the Airflow secrets described in
that file. OpenLineage infrastructure is installed and configured but disabled
by default. To activate event delivery, set `OPENMETADATA_JWT_TOKEN` to an
OpenMetadata bot JWT, set `OPENMETADATA_OPENLINEAGE_DISABLED=false`, and restart
the Airflow services.

Build and initialize Airflow:

```bash
docker compose build
docker compose up airflow-init
docker compose up -d
```

`docker compose up -d --build` is also supported. The common Compose anchor
keeps the same build definition on every Airflow service so this workflow does
not depend on `airflow-init` being the image build owner.

Start OpenMetadata from the adjacent project:

```bash
cd ../open-metadata
docker compose up -d
```

## Service-level verification

```bash
docker compose ps -a
docker compose exec airflow-scheduler airflow db check
docker compose exec airflow-scheduler airflow dags list-import-errors --output json
docker compose exec airflow-scheduler curl --fail \
  http://openmetadata-server:8585/api/v1/system/version
```

The Airflow API health endpoint is `/api/v2/monitor/health` on port `8080`.
OpenMetadata exposes its API on port `8585` and its health endpoint on port
`8586`.

## Deferred DAG integration

Source recipes, credentials, schedules, ingestion DAGs, and the bot JWT are not
configured yet. The Apache Airflow OpenLineage provider is ready to send events
to OpenMetadata's `/api/v1/openlineage/lineage` endpoint once enabled. The
`OpenMetadataLineageOperator` remains available as an explicit per-DAG option,
with success/failure callbacks for status updates. The legacy
`OpenMetadataLineageBackend` cannot be enabled because it imports the lineage
backend API removed in Airflow 3.
