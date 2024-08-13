#! /bin/sh

git config --global --add safe.directory /home/workspace/skyramp
rm -f /usr/local/lib/skyramp/idl/grpc/skyramp*.*
rm -rf /etc/skyramp/runtime/*
cp /home/workspace/skyramp/scripts/skyramp-init.py /


