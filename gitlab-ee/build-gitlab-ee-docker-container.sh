#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../common/shared.sh"

IMAGE="gitlab/gitlab-ee:15.11.13-ee.0"
CONTAINER_NAME="gitlab-ee"

CONFIG_DIR="$(dirname "$0")/volumes/gitlab/config"
LOGS_DIR="$(dirname "$0")/volumes/gitlab/logs"
DATA_DIR="$(dirname "$0")/volumes/gitlab/data"

echo "Starting GitLab container: $CONTAINER_NAME"
docker run --detach \
  --name "$CONTAINER_NAME" \
  --network host \
  --env-file "$ENV_FILE" \
  --env "GITLAB_OMNIBUS_CONFIG=external_url '${GITLAB_URL}'" \
  --publish 80:80 \
  --publish 443:443 \
  --volume "$CONFIG_DIR:/etc/gitlab" \
  --volume "$LOGS_DIR:/var/log/gitlab" \
  --volume "$DATA_DIR:/var/opt/gitlab" \
  --shm-size 256m \
  "$IMAGE"

echo
echo "The initialization may take 10–15 minutes depending on machine resources."
echo "Waiting for 'gitlab Reconfigured!' to appear in logs..."
echo

for i in {1..90}; do
  if docker logs "$CONTAINER_NAME" | grep 'gitlab Reconfigured!'; then
    echo "GitLab initialized successfully."
    break
  fi
  sleep 10
done

if ! docker logs "$CONTAINER_NAME" | grep 'gitlab Reconfigured!'; then
  echo "Timeout: GitLab did not finish initializing."
  exit 1
fi

echo
echo "Admin (root) password:"
docker exec -it "$CONTAINER_NAME" bash -c 'cat /etc/gitlab/initial_root_password' | grep -i password || echo "Could not read initial_root_password."