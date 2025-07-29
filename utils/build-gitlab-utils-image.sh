#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../common/shared.sh"

IMAGE_NAME="gitlab-utils"
DOCKERFILE_DIR="$(dirname "$0")"

if [[ ! -f "$DOCKERFILE_DIR/Dockerfile" ]]; then
    echo "Error: Dockerfile not found in $DOCKERFILE_DIR"
    exit 1
fi

echo "Building image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" "$DOCKERFILE_DIR"
