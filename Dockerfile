# BASE_CONTAINER refers to the base Docker container for the image, default is node
# The expectation is that node is installed and available on the container already.
ARG BASE_CONTAINER=node
# BASE_CONTAINER_VERSION refers to the version of the base Docker container for the image, default is 14-stretch
ARG BASE_CONTAINER_VERSION=14-stretch
# SINOPIA_UID refers to the UID for the Sinopia registry volume
# An example UID might be 101 for a particular Debian user
# An example UID might be 501 for a particular Mac user
ARG SINOPIA_UID=101
# SINOPIA_GID refers to the GID for the Sinopia registry volume
# An example UID might be 102 for a particular Debian group
# An example UID might be 20 for a particular Mac user group, e.g. "staff"
ARG SINOPIA_GID=102
# SINOPIA_PORT refers to the TCP port for the Sinopia service port, default is 4873
ARG SINOPIA_PORT=4873
# SINOPIA_VERSION refers to the version of Sinopia that will be installed
ARG SINOPIA_VERSION=1.4.0
FROM ${BASE_CONTAINER}:${BASE_CONTAINER_VERSION}
LABEL maintainer="David A. Ball <david@daball.me>"

VOLUME [ "/app/registry", "/app/config", "/app/secrets" ]

ARG BASE_CONTAINER
ARG BASE_CONTAINER_VERSION
ARG SINOPIA_UID
ARG SINOPIA_GID
RUN echo [root] Using container base: $BASE_CONTAINER && \
    echo [root] Using container version: $BASE_CONTAINER_VERSION && \
    echo [root] Updating apt package cache. && \
    apt update && \
    echo [root] Upgrading packages from apt remote repositories. && \
    apt upgrade && \
    echo [root] Adding unprivileged sinopia group with GID $SINOPIA_GID. && \
    groupadd --system --non-unique --gid $SINOPIA_GID sinopia && \
    echo [root] Adding unprivileged sinopia user with UID $SINOPIA_UID and GID $SINOPIA_GID. && \
    useradd \
        --system \
        --comment "Service account for Sinopia." \
        --non-unique \
        --no-create-home \
        --home-dir /app \
        --shell /bin/bash \
        --uid $SINOPIA_UID \
        --no-user-group \
        --gid $SINOPIA_GID \
        --key PASS_MAX_DAYS=99999 \
        --key PASS_MIN_DAYS=0 \
        --key PASS_WARN_AGE=7 \
        sinopia && \
    echo [sinopia] Making /app directory. && \
    mkdir --parents /app && \
    echo [sinopia] Making /app/registry directory. && \
    mkdir --parents /app/registry && \
    echo [sinopia] Making /app/config directory. && \
    mkdir --parents /app/config && \
    echo [sinopia] Making /app/secrets directory. && \
    mkdir --parents /app/secrets && \
    chown -R sinopia:sinopia /app && \
    echo [sinopia] Installing Sinopia from NPM. && \
    su -l -c "npm install sinopia" sinopia && \
    echo [sinopia] Adding Sinopia config.yaml to /app/config/config.yaml.

ARG SINOPIA_UID
ARG SINOPIA_GID
ADD config.yaml /app/config/config.yaml

ARG BASE_CONTAINER
ARG BASE_CONTAINER_VERSION
RUN chown sinopia:sinopa /app/config/config.yaml; \
    echo [sinopia] Contents of /app/config/config.yaml: && \
    cat /app/config/config.yaml; \
    echo [sinopia] Using container base: && \
    echo $BASE_CONTAINER; \
    echo [sinopia] Using container version: && \
    echo $BASE_CONTAINER_VERSION; \
    echo [sinopia] Using kernel version: && \
    uname -an; \
    echo [sinopia] Using node version: && \
    node --version; \
    echo [sinopia] Using sinopia version: && \
    su -l -c "sinopia --version" sinopia; \
    echo [sinopia] Launching sinopia...

ARG SINOPIA_PORT
CMD su -l -c "sinopia -l $SINOPIA_PORT -c /app/config/config.yaml" sinopia

ARG SINOPIA_PORT
EXPOSE ${SINOPIA_PORT}/tcp
