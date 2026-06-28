#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options]

Build a Docker image for the agents container.

Options:
  --profile PROFILE   Use profile directory (default: "default")
  --no-cache          Build without Docker cache
  -h, --help          Show this help message and exit
EOF
  exit 0
}

validate_profile_name() {
  if ! [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: invalid profile name '$1'. Use only alphanumeric characters, hyphens, and underscores." >&2
    exit 1
  fi
}

if [ ! -f cfg/env ]; then
  echo "cfg/env not found. Copy cfg/env.sample to cfg/env and configure it." >&2
  exit 1
fi

. cfg/env

PROFILE="default"
NO_CACHE_FLAG=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --no-cache)
      NO_CACHE_FLAG="--no-cache"
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

validate_profile_name "$PROFILE"

for var in USER_NAME USER_ID USER_GROUP; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is empty. Check cfg/env." >&2
    exit 1
  fi
done

PROFILE_DIR="$SCRIPT_DIR/profiles/$PROFILE"
IMAGE_TAG="$IMAGE_NAME"

if [ "$PROFILE" != "default" ]; then
  IMAGE_TAG="${IMAGE_NAME}-${PROFILE}"
fi

if [ ! -d "$PROFILE_DIR" ]; then
  echo "Error: profile directory not found: $PROFILE_DIR"
  exit 1
fi

# Create a unique, isolated build context per invocation so parallel profile builds don't collide
BUILD_DIR=$(mktemp -d "$SCRIPT_DIR/tmp/build_${PROFILE}_XXXXXXXX")
trap 'rm -rf "$BUILD_DIR"' EXIT

mkdir -p "$BUILD_DIR/tmp"
mkdir -p "$BUILD_DIR/scripts"

cp "$SCRIPT_DIR/Dockerfile" "$BUILD_DIR/"
cp "$SCRIPT_DIR/scripts/entrypoint.sh" "$BUILD_DIR/scripts/"

# Make cfg/env available inside the container for bundled scripts
cp "$SCRIPT_DIR/cfg/env" "$BUILD_DIR/tmp/env"

# Profile-specific script directories (each profile declares what it needs)
SCRIPTS_USER="$PROFILE_DIR/user_scripts"
SCRIPTS_ROOT="$PROFILE_DIR/root_scripts"
SCRIPTS_CONTAINER="$PROFILE_DIR/container_scripts"

# Bundle user scripts
USER_BUNDLE="$BUILD_DIR/tmp/bundled_scripts.sh"
printf '. ./env\n' > "$USER_BUNDLE"
if [ -d "$SCRIPTS_USER" ]; then
  for f in "$SCRIPTS_USER"/*; do
    [ -f "$f" ] && cat "$f" >> "$USER_BUNDLE"
  done
fi

# Bundle root scripts
ROOT_BUNDLE="$BUILD_DIR/tmp/bundled_root_scripts.sh"
printf '. ./env\n' > "$ROOT_BUNDLE"
if [ -d "$SCRIPTS_ROOT" ]; then
  for f in "$SCRIPTS_ROOT"/*; do
    [ -f "$f" ] && cat "$f" >> "$ROOT_BUNDLE"
  done
fi

# Bundle container startup scripts (runs as ENTRYPOINT at container start)
CONTAINER_BUNDLE="$BUILD_DIR/tmp/bundled_container_scripts.sh"
if [ -d "$SCRIPTS_CONTAINER" ]; then
  for f in "$SCRIPTS_CONTAINER"/*; do
    [ -f "$f" ] && cat "$f" >> "$CONTAINER_BUNDLE"
  done
fi

# ! keep $NO_CACHE_FLAG unquoted so it is absent if empty string!
docker build \
  -t "$IMAGE_TAG" \
  --build-arg USER_NAME="${USER_NAME}" \
  --build-arg USER_ID="${USER_ID}" \
  --build-arg USER_GROUP="${USER_GROUP}" \
  --build-arg MISE_DATA_DIR="${MISE_DATA_DIR}" \
  --build-arg MISE_CONFIG_DIR="${MISE_CONFIG_DIR}" \
  --build-arg MISE_CACHE_DIR="${MISE_CACHE_DIR}" \
  --build-arg MISE_INSTALL_PATH="${MISE_INSTALL_PATH}" \
  --progress plain \
  $NO_CACHE_FLAG \
  "$BUILD_DIR"
