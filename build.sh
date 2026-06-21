#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

. .env

PROFILE="default"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
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

# Bundle user scripts (only files, skip directories like 'root')
: > "$SCRIPT_DIR/tmp/bundled_scripts.sh"
if [ -d "$PROFILE_DIR/user_scripts" ]; then
  for f in "$PROFILE_DIR/user_scripts"/*; do
    [ -f "$f" ] && cat "$f" >> "$SCRIPT_DIR/tmp/bundled_scripts.sh"
  done
fi

# Bundle root scripts
: > "$SCRIPT_DIR/tmp/bundled_root_scripts.sh"
if [ -d "$PROFILE_DIR/root_scripts" ]; then
  for f in "$PROFILE_DIR/root_scripts"/*; do
    [ -f "$f" ] && cat "$f" >> "$SCRIPT_DIR/tmp/bundled_root_scripts.sh"
  done
fi

cp ~/local/bin/asfald .
docker build \
  -t "$IMAGE_TAG" \
  --build-arg USER_NAME \
  --build-arg USER_ID \
  --build-arg USER_GROUP \
  .
