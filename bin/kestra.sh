#!/bin/bash

set -euo pipefail

KESTRA_IMAGE="${KESTRA_IMAGE:-kestra/kestra:latest}"
CONTAINER_WORKDIR="${KESTRA_CONTAINER_WORKDIR:-/ephemeral-kestra-cli-workdir}"

if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker is not installed."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running."
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: ./bin/kestra.sh <kestra-cli-args>"
    echo "Example: ./bin/kestra.sh flow validate --local kestra/flows/example.yml"
    exit 1
fi

# Create temporary config file
TEMP_CONFIG=$(mktemp)
trap "rm -f $TEMP_CONFIG" EXIT

cat > "$TEMP_CONFIG" << EOF
kestra:
  repository:
    type: memory
  queue:
    type: memory
  storage:
    type: local
    local:
      base-path: /tmp/kestra-storage
EOF

docker run --rm \
    -v "$(pwd):${CONTAINER_WORKDIR}" \
    -v "$TEMP_CONFIG:/tmp/kestra-config.yml:ro" \
    -w "${CONTAINER_WORKDIR}" \
    -e MICRONAUT_CONFIG_FILES=/tmp/kestra-config.yml \
    "${KESTRA_IMAGE}" \
    "$@"
