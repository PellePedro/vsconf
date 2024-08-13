#!/bin/bash

set -e

mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |  gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" |  tee /etc/apt/sources.list.d/nodesource.list

apt update
apt install -y ca-certificates gnupg
apt install python3.11 \
    python3.11-venv \
    nodejs -y

ln -s /usr/bin/python3.11 /usr/local/bin/python
ln -s /usr/bin/python3.11 /usr/local/bin/python3
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py
rm get-pip.py


go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.27.1

mkdir -p /etc/skyramp
chmod 777 /etc/skyramp

mkdir -p /usr/local/lib/skyramp/idl/grpc
mkdir -p /usr/local/lib/skyramp/idl/thrift
chmod -R 777 /usr/local/lib/skyramp
