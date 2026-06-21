#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

. cfg/env
set -eux

PROFILE="default"
ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --profile)
    PROFILE="$2"
    shift 2
    ;;
  *)
    ARGS+=("$1")
    shift
    ;;
  esac
done

PROFILE_DIR="$SCRIPT_DIR/profiles/$PROFILE"
IMAGE_TAG="$IMAGE_NAME"

if [ "$PROFILE" != "default" ]; then
  IMAGE_TAG="${IMAGE_NAME}-${PROFILE}"
fi

# Ensure profile mount directory exists
PROFILE_MOUNTS="$PROFILE_DIR/mounts"
mkdir -p "$PROFILE_MOUNTS"

# Create standard mounts from manifest if they don't exist
MOUNTS_CFG="$SCRIPT_DIR/cfg/mounts.cfg"
if [ ! -f "$MOUNTS_CFG" ]; then
  MOUNTS_CFG="$SCRIPT_DIR/cfg/mounts.cfg.sample"
fi
if [ -f "$MOUNTS_CFG" ]; then
  while IFS= read -r line; do
    entry="${line%%#*}"
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    [ -z "$entry" ] && continue
    if [[ "$entry" == */ ]]; then
      mkdir -p "$PROFILE_MOUNTS/$entry"
    else
      dir=$(dirname "$PROFILE_MOUNTS/$entry")
      mkdir -p "$dir"
      [ -f "$PROFILE_MOUNTS/$entry" ] || touch "$PROFILE_MOUNTS/$entry"
    fi
  done < "$MOUNTS_CFG"
fi

# if user name is not set in env, set current user
user_name=${USER_NAME:-$(id -u -n)}

# Build docker args array
DOCKER_ARGS=()

# Mount profile-specific mounts
for mount_entry in "$PROFILE_MOUNTS"/* "$PROFILE_MOUNTS"/.*; do
  [ -e "$mount_entry" ] || continue
  rel_path=$(basename "$mount_entry")
  [ "$rel_path" = "." ] || [ "$rel_path" = ".." ] && continue
  DOCKER_ARGS+=(-v "$mount_entry:/home/${user_name}/${rel_path}")
done

# Infrastructure mounts (not profile-specific)
DOCKER_ARGS+=(
  -v "${ARGS[0]:?pass directory with code as argument}:${ARGS[0]}"
  -v ~/.config/nvim:/home/${user_name}/.config/nvim
  -v /tmp/.X11-unix:/tmp/.X11-unix
  -v /dev/dri/card0:/dev/dri/card0
  -v /dev/dri/renderD128:/dev/dri/renderD128
  -v /var/run/docker.sock:/var/run/docker.sock
  --device /dev/dri:/dev/dri
  --device /dev/snd:/dev/snd
  --shm-size '2gb'
)

# Environment variables
DOCKER_ARGS+=(
  --env "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
  --env "ANTHROPIC_AUTH_TOKEN=$ANTHROPIC_AUTH_TOKEN"
  --env "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
  --env "ANTHROPIC_DEFAULT_SONNET_MODEL=$ANTHROPIC_DEFAULT_SONNET_MODEL"
  --env "GEMINI_API_KEY=$GEMINI_API_KEY"
  --env "MISTRAL_API_KEY=$MISTRAL_API_KEY"
  --env "OPENROUTER_API_KEY=$OPENROUTER_API_KEY"
  --env "SYNTHETIC_API_KEY=$SYNTHETIC_API_KEY"
  --env DISPLAY=${DISPLAY}
  --env QT_X11_NO_MITSHM=1
  --env MISE_DATA_DIR=/tmp/mise/data
  --env MISE_CACHE_DIR=/tmp/mise/cache
  --env MISE_CONFIG_DIR=/tmp/mise/config
)

# to allow X apps to run
xhost +local:docker

docker run -it \
  "${DOCKER_ARGS[@]}" \
  --workdir "${ARGS[0]}" \
  --cap-add=SYS_ADMIN \
  --rm \
  "$IMAGE_TAG" /bin/bash

# disable when we're done
xhost -local:docker
