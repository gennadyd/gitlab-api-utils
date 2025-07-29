#!/bin/bash
set -euo pipefail

MODE=${1:-""}

source "$(dirname "$0")/../common/shared.sh"

CONTAINER_NAME="gitlab-gpt-generator"
GPT_JSON="$(dirname "$0")/gpt.json"

if [[ ! -f "$GPT_JSON" ]]; then
    echo "Error: $GPT_JSON file not found."
    exit 1
fi

if [[ -z "${GITLAB_TOKEN:-}" ]]; then
    echo "Error: GITLAB_TOKEN is not set in $ENV_FILE."
    exit 1
fi

echo "Running gpt-data-generator..."

DOCKER_CMD=(
  docker run --rm -i
  --name "$CONTAINER_NAME"
  --network host
  --env-file "$ENV_FILE"
  -e "ACCESS_TOKEN=$GITLAB_TOKEN"
  -v "$(realpath "$GPT_JSON"):/tmp/gpt.json"
  gitlab/gpt-data-generator
  --environment=/tmp/gpt.json
)

if [[ "$MODE" == "--clean-up" ]]; then
  DOCKER_CMD+=("--clean-up")
fi

if [[ "$MODE" == "--auto" ]]; then
  yes | "${DOCKER_CMD[@]}"
else
  "${DOCKER_CMD[@]}"
fi
