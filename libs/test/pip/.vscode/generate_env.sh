#! /bin/bash

cat <<-EOF >.env
SHA=$(docker images | grep worker | head -n 1 | awk '{print $2}')
PYTHONPATH=../../pip/src
EOF
