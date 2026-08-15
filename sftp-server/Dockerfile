# syntax=docker/dockerfile:1
ARG ALPINE_VERSION=3.22.5
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST}

ARG OPENSSH_VERSION=10.0_p1-r10
ARG SFTP_SERVER_VERSION=1.0.0

LABEL org.opencontainers.image.title="sftp-server" \
      org.opencontainers.image.description="A chrooted, SFTP-only OpenSSH server" \
      org.opencontainers.image.version="${SFTP_SERVER_VERSION}"

RUN apk add --no-cache \
        "openssh-server=${OPENSSH_VERSION}" \
        "openssh-sftp-server=${OPENSSH_VERSION}"

COPY sshd_config /etc/ssh/sshd_config
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

EXPOSE 22

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD nc -z 127.0.0.1 22 || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
