#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/../common/shared.sh"

IMAGE_NAME="gitlab-utils"
CONTAINER_NAME="gitlab-utils"

VALID_TYPES=("mr" "issues")
VALID_ROLES=("guest" "reporter" "developer" "maintainer" "owner")

print_help() {
  echo "Usage:"
  echo "  $0 get --type [mr|issues] --year <YEAR>"
  echo "  $0 assign-role --username USER --repo_or_group_name NAME --role ROLE"
  echo
  echo "Available roles: ${VALID_ROLES[*]}"
  exit 1
}

# Показать справку если нет аргументов или запрошена помощь
if [[ $# -eq 0 || "$1" == "--help" ]]; then
  print_help
fi

# Сохраняем команду и оставшиеся аргументы
CMD=$1
ARGS=("${@:2}")

# Проверка аргументов
case "$CMD" in
  get)
    TYPE=""
    YEAR=""
    for ((i = 0; i < ${#ARGS[@]}; i++)); do
      case "${ARGS[$i]}" in
        --type)
          TYPE=${ARGS[$((i + 1))]:-}
          ;;
        --year)
          YEAR=${ARGS[$((i + 1))]:-}
          ;;
      esac
    done

    if [[ -z "$TYPE" || -z "$YEAR" ]]; then
      echo "Error: Missing --type or --year."
      print_help
    fi

    if [[ ! " ${VALID_TYPES[*]} " =~ " $TYPE " ]]; then
      echo "Error: Invalid --type. Must be one of: ${VALID_TYPES[*]}"
      exit 2
    fi

    if ! [[ "$YEAR" =~ ^[0-9]{4}$ ]]; then
      echo "Error: --year must be a 4-digit number."
      exit 2
    fi
    ;;

  assign-role)
    USERNAME=""
    NAME=""
    ROLE=""
    for ((i = 0; i < ${#ARGS[@]}; i++)); do
      case "${ARGS[$i]}" in
        --username)
          USERNAME=${ARGS[$((i + 1))]:-}
          ;;
        --repo_or_group_name)
          NAME=${ARGS[$((i + 1))]:-}
          ;;
        --role)
          ROLE=${ARGS[$((i + 1))]:-}
          ;;
      esac
    done

    if [[ -z "$USERNAME" || -z "$NAME" || -z "$ROLE" ]]; then
      echo "Error: Missing required parameters for assign-role."
      print_help
    fi

    if [[ ! " ${VALID_ROLES[*]} " =~ " $ROLE " ]]; then
      echo "Error: Invalid role. Must be one of: ${VALID_ROLES[*]}"
      exit 2
    fi
    ;;

  *)
    echo "Error: Unknown command '$CMD'"
    print_help
    ;;
esac

echo "Waiting for GitLab API to respond..."
for i in {1..30}; do
  if curl --silent --fail --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/version" > /dev/null; then
    echo "GitLab is up."
    break
  fi
  echo -n "."
  sleep 5
done

echo
echo "Running container: $CONTAINER_NAME"
echo "Running container with command:"
echo docker run --rm -it \
  --name "$CONTAINER_NAME" \
  --network host \
  --env-file "$ENV_FILE" \
  "$IMAGE_NAME" "$CMD" "${ARGS[@]}"

docker run --rm -it \
  --name "$CONTAINER_NAME" \
  --network host \
  --env-file "$ENV_FILE" \
  "$IMAGE_NAME" "$CMD" "${ARGS[@]}"
