# syntax=docker/dockerfile:1.2

ARG GOLANGCILINT_VERSION=v1.50.0
FROM qmcgaw/binpot:golangci-lint-${GOLANGCILINT_VERSION} AS golangci-lint
FROM ubuntu:24.04 AS base

FROM base AS go_1_19_builder
COPY --from=golangci-lint /bin /go/bin/golangci-lint

ENV GOBIN=/home/ubuntu/go/bin
ENV PATH=/usr/local/go/bin:$GOBIN:$PATH
ENV GO_VERSION=1.19.2
ENV STATICCHECK_VERSION=2023.1.2
ENV GOLANGCI_LINT_VERSION=1.50.0
RUN --mount=type=bind,target=/tmp/scripts,source=./scripts,ro \
    bash /tmp/scripts/install-packages.sh

RUN wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" &&\
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz" && \
    rm go${GO_VERSION}.linux-amd64.tar.gz 

# Stage for Go 1.22.6
FROM go_builder AS go_1_22_builder
ENV PATH=/usr/local/go/bin:$GOBIN:$PATH
ENV GO_VERSION=1.22.6
ENV STATICCHECK_VERSION=2023.1.2
ENV GOLANGCI_LINT_VERSION=1.59.0
RUN --mount=type=bind,target=/tmp/scripts,source=./scripts,ro \
    bash /tmp/scripts/install-packages.sh
RUN wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@$GOLANGCI_LINT_VERSION && \
    go install honnef.co/go/tools/cmd/staticcheck@$STATICCHECK_VERSION
