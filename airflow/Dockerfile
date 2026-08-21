# syntax=docker/dockerfile:1.7

# AIRFLOW_VERSION is supplied by Docker Compose from .env.
ARG AIRFLOW_VERSION
FROM apache/airflow:slim-${AIRFLOW_VERSION}-python3.10

ARG AIRFLOW_VERSION

LABEL org.opencontainers.image.title="Data Platform Airflow" \
      org.opencontainers.image.description="Custom Apache Airflow LocalExecutor image" \
      org.opencontainers.image.version="${AIRFLOW_VERSION}" \
      org.opencontainers.image.base.name="apache/airflow:slim-${AIRFLOW_VERSION}-python3.10"

# Install Airflow-side dependencies with the constraints shipped by the official
# image. OpenMetadata is installed separately because its supported dependency
# set intentionally differs from the Airflow constraints. Repeating the exact
# Airflow requirement in the second transaction prevents an implicit version
# change while resolving the connector packages.
RUN --mount=type=bind,source=requirements.txt,target=/tmp/requirements.txt,readonly \
    uv pip install --no-cache \
        "apache-airflow==${AIRFLOW_VERSION}" \
        --constraint "${HOME}/constraints.txt" \
        --requirement /tmp/requirements.txt \
    && python -c "import asyncpg, psycopg2; from airflow.providers.fab.auth_manager.fab_auth_manager import FabAuthManager; import airflow.providers.openlineage"

RUN --mount=type=bind,source=requirements-openmetadata.txt,target=/tmp/requirements-openmetadata.txt,readonly \
    uv pip install --no-cache \
        "apache-airflow==${AIRFLOW_VERSION}" \
        --requirement /tmp/requirements-openmetadata.txt \
    && uv pip check \
    && test "$(airflow version)" = "${AIRFLOW_VERSION}" \
    && test "$(python -c 'import sys; print("%d.%d" % sys.version_info[:2])')" = "3.10" \
    && python -c "from importlib.metadata import version; assert version('openmetadata-ingestion') == '1.13.3.0'; assert version('apache-airflow-providers-openlineage') == '2.17.0'; assert version('boto3') == '1.41.5'" \
    && python -c "import boto3; from botocore.config import Config; from metadata.workflow.metadata import MetadataWorkflow; from metadata.ingestion.source.database.postgres.metadata import PostgresSource; from metadata.ingestion.source.messaging.kafka.metadata import KafkaSource; from metadata.ingestion.source.api.rest.metadata import RestSource; from metadata.ingestion.source.storage.s3.metadata import S3Source; from airflow_provider_openmetadata.lineage.operator import OpenMetadataLineageOperator; from airflow_provider_openmetadata.lineage.callback import failure_callback, success_callback"

USER airflow
WORKDIR /opt/airflow
