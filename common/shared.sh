#!/bin/bash
set -euo pipefail

ENV_FILE="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../.env")"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE file not found."
  exit 1
fi

source "$ENV_FILE"