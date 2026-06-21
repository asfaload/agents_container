#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "$SCRIPT_DIR"

if [ ! -f cfg/env ]; then
  echo "cfg/env not found. Copy cfg/env.sample to cfg/env and configure it." >&2
  exit 1
fi

. cfg/env

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

# Make cfg/env available inside the container for bundled scripts
cp "$SCRIPT_DIR/cfg/env" "$SCRIPT_DIR/tmp/env"

# Bundle user scripts (only files, skip directories like 'root')
USER_BUNDLE="$SCRIPT_DIR/tmp/bundled_scripts-${PROFILE}.sh"
printf '. ./env\n' > "$USER_BUNDLE"
if [ -d "$PROFILE_DIR/user_scripts" ]; then
  for f in "$PROFILE_DIR/user_scripts"/*; do
    [ -f "$f" ] && cat "$f" >> "$USER_BUNDLE"
  done
fi

# Bundle root scripts
ROOT_BUNDLE="$SCRIPT_DIR/tmp/bundled_root_scripts-${PROFILE}.sh"
printf '. ./env\n' > "$ROOT_BUNDLE"
if [ -d "$PROFILE_DIR/root_scripts" ]; then
  for f in "$PROFILE_DIR/root_scripts"/*; do
    [ -f "$f" ] && cat "$f" >> "$ROOT_BUNDLE"
  done
fi

# Copy to fixed names expected by Dockerfile
cp "$USER_BUNDLE" "$SCRIPT_DIR/tmp/bundled_scripts.sh"
cp "$ROOT_BUNDLE" "$SCRIPT_DIR/tmp/bundled_root_scripts.sh"

cp ~/local/bin/asfald .
docker build \
  -t "$IMAGE_TAG" \
  --build-arg USER_NAME \
  --build-arg USER_ID \
  --build-arg USER_GROUP \
  .
