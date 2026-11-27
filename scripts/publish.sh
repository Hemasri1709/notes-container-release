#!/usr/bin/env bash
# Builds the notes-web image and publishes it to the local registry.
# Usage: bash scripts/publish.sh
set -euo pipefail

IMAGE="notes-web"
REGISTRY="localhost:5050"
VERSION="1.0.0"

docker build -t "$IMAGE:$VERSION" .
docker tag "$IMAGE:$VERSION" "$REGISTRY/$IMAGE:$VERSION"
docker tag "$IMAGE:$VERSION" "$REGISTRY/$IMAGE:latest"
docker push "$REGISTRY/$IMAGE:$VERSION"
docker push "$REGISTRY/$IMAGE:latest"
