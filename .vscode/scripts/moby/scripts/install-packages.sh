#!/bin/bash

DEBIAN_FRONTEND=noninteractive

apt-get update && \
apt-get install -y  \
        build-essential  \
        protobuf-compiler \
        curl \
        git  \
        net-tools \
        dnsutils \
        iputils-ping \
        iproute2 \
        jq \
        netcat \
        socat \
        nnn \
        procps \
        ripgrep \
        sudo \
        sqlite \
        wget \
        zsh



