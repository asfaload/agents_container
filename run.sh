#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] <work-directory>

Run the agents container with the given work directory mounted.

Options:
  --profile PROFILE   Use profile directory (default: "default")
  --debug             Enable debug output
  -h, --help          Show this help message and exit
EOF
  exit 0
}

if [ ! -f cfg/env ]; then
  echo "cfg/env not found. Copy cfg/env.sample to cfg/env and configure it." >&2
  exit 1
fi

. cfg/env
set -eu

# docker env vile don't accept comment lines, so we strip them
DOCKER_ENV_FILE=$(mktemp)
trap 'rm -f "$DOCKER_ENV_FILE"' EXIT
grep -v '^#' cfg/env | grep -v '^[[:space:]]*$' >"$DOCKER_ENV_FILE"

PROFILE="default"
ARGS=()

validate_profile_name() {
  if ! [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: invalid profile name '$1'. Use only alphanumeric characters, hyphens, and underscores." >&2
    exit 1
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --profile)
    PROFILE="$2"
    shift 2
    ;;
  --debug)
    set -x
    shift
    ;;
  -h|--help)
    show_help
    ;;
  *)
    ARGS+=("$1")
    shift
    ;;
  esac
done

if [[ ! "${#ARGS[@]}" -gt 0 ]]; then
  echo "The script needs the work directory as argument. Give the absolute path to the directory to be mounted in the container"
  exit 1
fi

validate_profile_name "$PROFILE"

PROFILE_DIR="$SCRIPT_DIR/profiles/$PROFILE"
IMAGE_TAG="$IMAGE_NAME"

if [ "$PROFILE" != "default" ]; then
  IMAGE_TAG="${IMAGE_NAME}-${PROFILE}"
fi

# Ensure profile mount directory exists
PROFILE_MOUNTS="$PROFILE_DIR/mounts"
mkdir -p "$PROFILE_MOUNTS"

# Create standard mounts from manifest if they don't exist
# Per-profile mounts.cfg takes precedence over cfg/mounts.cfg
if [ -f "$PROFILE_DIR/mounts.cfg" ]; then
  MOUNTS_CFG="$PROFILE_DIR/mounts.cfg"
else
  MOUNTS_CFG="$SCRIPT_DIR/cfg/mounts.cfg"
fi
if [ ! -f "$MOUNTS_CFG" ]; then
  echo "mounts.cfg not found (tried $MOUNTS_CFG). Copy cfg/mounts.cfg.sample to cfg/mounts.cfg and customize it." >&2
  exit 1
fi

# git config env vars
if [ -f "$PROFILE_DIR/git-config.sh" ]; then
  GIT_CFG="$PROFILE_DIR/git-config.sh"
else
  GIT_CFG="$SCRIPT_DIR/cfg/git-config.sh"
fi

GIT_VAR_FLAGS=()
if [ ! -f "$GIT_CFG" ]; then
  echo "git-config.sh not found. Agent will not be able to commit. See cfg/git-config.sh.sample" >&2
else
  echo "Using git config from $GIT_CFG"
  . "$GIT_CFG"
  if [[ -n "$GIT_USER_EMAIL" && -n "$GIT_USER_NAME" ]]; then
    GIT_VAR_FLAGS=(--env "GIT_USER_NAME=$GIT_USER_NAME" --env "GIT_USER_EMAIL=$GIT_USER_EMAIL")
  else
    echo "Incomplete git configuration!"
  fi
fi


# Build docker args array early so absolute-path mounts can add to it
DOCKER_ARGS=()

while IFS= read -r line; do
  entry="${line%%#*}"
  entry="${entry#"${entry%%[![:space:]]*}"}"
  entry="${entry%"${entry##*[![:space:]]}"}"
  [ -z "$entry" ] && continue
  if [[ "$entry" == /* ]]; then
    # Absolute path: bind-mount host path at the same path in the container
    DOCKER_ARGS+=(-v "${entry}:${entry}")
  elif [[ "$entry" == */ ]]; then
    mkdir -p "$PROFILE_MOUNTS/$entry"
  else
    dir=$(dirname "$PROFILE_MOUNTS/$entry")
    mkdir -p "$dir"
    [ -f "$PROFILE_MOUNTS/$entry" ] || touch "$PROFILE_MOUNTS/$entry"
  fi
done <"$MOUNTS_CFG"

# if user name is not set in env, set current user
user_name=${USER_NAME:-$(id -u -n)}

# Mount profile-specific mounts (all files/dirs under mounts/ are mounted — not just those from mounts.cfg)
for mount_entry in "$PROFILE_MOUNTS"/* "$PROFILE_MOUNTS"/.*; do
  [ -e "$mount_entry" ] || continue
  rel_path=$(basename "$mount_entry")
  [ "$rel_path" = "." ] || [ "$rel_path" = ".." ] && continue
  DOCKER_ARGS+=(-v "$mount_entry:/home/${user_name}/${rel_path}")
done

# Infrastructure mounts (not profile-specific)
DOCKER_ARGS+=(
  -v "${ARGS[0]:?pass directory with code as argument}:${ARGS[0]}"
  -v /tmp/.X11-unix:/tmp/.X11-unix
  -v /dev/dri/card0:/dev/dri/card0
  -v /dev/dri/renderD128:/dev/dri/renderD128
  --device /dev/dri:/dev/dri
  --device /dev/snd:/dev/snd
  --shm-size '2gb'
)

# Environment variables
DOCKER_ARGS+=(
  --env-file "$DOCKER_ENV_FILE"
  --env DISPLAY=${DISPLAY}
  --env QT_X11_NO_MITSHM=1
  --env MISE_DATA_DIR="$MISE_DATA_DIR"
  --env MISE_CACHE_DIR="$MISE_CACHE_DIR"
  --env MISE_CONFIG_DIR="$MISE_CONFIG_DIR"
  --env MISE_INSTALL_PATH="$MISE_INSTALL_PATH"
  "${GIT_VAR_FLAGS[@]}"
)

# to allow X apps to run
xhost +local:docker

# GIT_VAR_FLAGS is an array; empty array expands to nothing when quoted with [@]
docker run -it \
  "${DOCKER_ARGS[@]}" \
  --workdir "${ARGS[0]}" \
  --cap-add=SYS_ADMIN \
  --rm \
  "$IMAGE_TAG" /bin/bash

# disable when we're done
xhost -local:docker
