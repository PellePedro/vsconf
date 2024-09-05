# syntax=docker/dockerfile:1.2
FROM ubuntu:24.04 AS base

FROM base AS go_1_19_builder
ENV GOBIN=/home/ubuntu/go/bin
ENV PATH=/usr/local/go/bin:$GOBIN:$PATH
ENV GO_VERSION=1.19.2
ENV STATICCHECK_VERSION=2023.1.2
ENV GOLANGCI_LINT_VERSION=1.59.0
RUN --mount=type=bind,target=/tmp/scripts,source=./scripts,ro \
    bash /tmp/scripts/install-packages.sh

# Stage for Go 1.22.6
FROM go_builder AS go_1_22_builder
ENV PATH=/usr/local/go/bin:$GOBIN:$PATH
ENV GO_VERSION=1.22.6
ENV STATICCHECK_VERSION=2023.1.2
ENV GOLANGCI_LINT_VERSION=1.59.0
RUN --mount=type=bind,target=/tmp/scripts,source=./scripts,ro \
    bash /tmp/scripts/install-packages.sh
