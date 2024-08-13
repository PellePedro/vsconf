# syntax=docker/dockerfile:1.2
ARG GO_VERSION=1.22
ARG DLV_VERSION=v1.22.0
ARG GOPLS_VERSION=v0.14.2
ARG GOMODIFYTAGS_VERSION=v1.16.0
FROM golang:${GO_VERSION}-bookworm AS go
FROM qmcgaw/binpot:dlv-${DLV_VERSION} AS dlv
FROM qmcgaw/binpot:gopls-${GOPLS_VERSION} AS gopls

FROM gitpod/openvscode-server:latest

ENV OPENVSCODE_SERVER_ROOT="/home/.openvscode-server"
ENV OPENVSCODE="${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server"
ENV PATH="${PATH}:/usr/local/go/bin"
ENV GOBIN=/usr/local/go/bin

USER root

COPY --from=go /usr/local/go /usr/local/go
COPY --from=gopls /bin /usr/local/bin/gopls
COPY --from=dlv /bin /usr/local/bin/dlv
RUN chmod +x /usr/local/bin/*
RUN --mount=type=bind,target=/tmp/scripts,source=./scripts,ro \
    for script in /tmp/scripts/*; do \
        bash "$script"; \
    done

SHELL ["/bin/bash", "-c"]
RUN \
    exts=(\
        gitpod.gitpod-theme \
        humao.rest-client \
        golang.go \
        ms-python.python \
        ms-python.debugpy \
    )\
    && for ext in "${exts[@]}"; do ${OPENVSCODE} --install-extension "${ext}"; done
