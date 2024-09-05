#!/bin/bash
DEBIAN_FRONTEND=noninteractive

apt-get update && \
    apt-get install -y wget git gcc curl unzip make

curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh

## INSTALL PODMAN DEPS
apt-get install -y --no-install-recommends \
    btrfs-progs \
    crun \
    git \
    curl \
    build-essential \
    go-md2man \
    iptables \
    libassuan-dev \
    libbtrfs-dev \
    libc6-dev \
    libdevmapper-dev \
    libglib2.0-dev \
    libgpgme-dev \
    libgpg-error-dev \
    libprotobuf-dev \
    libprotobuf-c-dev \
    libseccomp-dev \
    libselinux1-dev \
    libsystemd-dev \
    pkg-config \
    uidmap

## INSTALL PYTHON
apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel

## CLEANUP
apt-get autoremove && \
    apt-get clean

if [ -z "$GO_VERSION" ]; then
    echo "Go version not provided"
    exit 1
fi
wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

go install github.com/golangci/golangci-lint/cmd/golangci-lint@$GOLANGCI_LINT_VERSION
go install honnef.co/go/tools/cmd/staticcheck@$STATICCHECK_VERSION
