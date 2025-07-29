#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../common/shared.sh"

for user_id in {1..5}; do
    username="devtest_${user_id}"
    echo -n "Creating user: $username... "

    response=$(curl --silent --show-error --fail \
      --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      --header "Content-Type: application/json" \
      --data "{
        \"email\": \"${username}@gitlab\",
        \"username\": \"${username}\",
        \"name\": \"Dev Test ${user_id}\",
        \"password\": \"Dev123456!\",
        \"skip_confirmation\": true
      }" \
      "$GITLAB_URL/api/v4/users") || {
        echo "already exists or failed"
        continue
    }

    id=$(echo "$response" | grep -o '"id":[0-9]*' | head -n1 | cut -d: -f2)
    echo "done (id=$id)"
done
