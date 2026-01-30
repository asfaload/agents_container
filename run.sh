#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
MOUNTS_DIR="$SCRIPT_DIR/mounts"

. .env
set -eux

mkdir -p $MOUNTS_DIR/dot_local
mkdir -p $MOUNTS_DIR/dot_config
mkdir -p $MOUNTS_DIR/kilocode_config
mkdir -p $MOUNTS_DIR/dot_claude
touch  $MOUNTS_DIR/claude.json

# if user name is not set in env, set current user
user_name=${USER_NAME:-$(id -u -n)}
# to allow X apps to run
xhost +local:docker
docker run -it -v ${1:?pass directory with code as argument}:$1 \
  -v $MOUNTS_DIR/kilocode_config:/home/${user_name}/.kilocode \
  -v $MOUNTS_DIR/dot_claude:/home/${user_name}/.claude \
  -v $MOUNTS_DIR/claude.json:/home/${user_name}/.claude.json \
  -v $MOUNTS_DIR/dot_local:/home/${user_name}/.local \
  -v $MOUNTS_DIR/dot_config:/home/${user_name}/.config \
  -v $MOUNTS_DIR/dot_openclaw:/home/${user_name}/.openclaw \
  -v ~/.config/nvim:/home/${user_name}/.config/nvim \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/dri/card0:/dev/dri/card0 \
  -v /dev/dri/renderD128:/dev/dri/renderD128 \
  --device /dev/dri:/dev/dri \
  --device /dev/snd:/dev/snd \
  --shm-size '2gb' \
  --env "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL" \
  --env "ANTHROPIC_AUTH_TOKEN=$ANTHROPIC_AUTH_TOKEN" \
  --env "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" \
  --env "ANTHROPIC_DEFAULT_SONNET_MODEL=$ANTHROPIC_DEFAULT_SONNET_MODEL" \
  --env "GEMINI_API_KEY=$GEMINI_API_KEY" \
  --env "MISTRAL_API_KEY=$MISTRAL_API_KEY" \
  --env "OPENROUTER_API_KEY=$OPENROUTER_API_KEY" \
  --env "SYNTHETIC_API_KEY=$SYNTHETIC_API_KEY" \
  --env DISPLAY=${DISPLAY} \
  --env QT_X11_NO_MITSHM=1 \
  --workdir $1 \
  --cap-add=SYS_ADMIN \
  --rm \
  -u $(id -u $user_name):$(id -g $user_name) $IMAGE_NAME bash

# disable when we're done
  xhost -local:docker
