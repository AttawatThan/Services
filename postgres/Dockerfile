# syntax=docker/dockerfile:1.7

ARG POSTGRES_VERSION=18.4
FROM postgres:${POSTGRES_VERSION}

ARG POSTGRES_VERSION

LABEL org.opencontainers.image.title="Data Platform PostgreSQL" \
      org.opencontainers.image.description="Persistent PostgreSQL database for application and business data" \
      org.opencontainers.image.version="${POSTGRES_VERSION}" \
      org.opencontainers.image.base.name="postgres:${POSTGRES_VERSION}"

# Compose overrides this check with the configured bootstrap user/database. This
# image-level check also keeps plain `docker run` deployments observable.
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
  CMD pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" || exit 1
