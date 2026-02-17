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

docker run --rm \
    -v "$(pwd):${CONTAINER_WORKDIR}" \
    -w "${CONTAINER_WORKDIR}" \
    "${KESTRA_IMAGE}" \
    "$@"
