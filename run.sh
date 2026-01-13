#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

. .env
set -eux

mkdir -p $SCRIPT_DIR/dot_local
mkdir -p $SCRIPT_DIR/dot_config
mkdir -p $SCRIPT_DIR/kilocode_config
mkdir -p $SCRIPT_DIR/dot_claude
touch  $SCRIPT_DIR/claude.json

# to allow X apps to run
xhost +local:docker
docker run -it -v ${1:?pass directory with code as argument}:$1 \
  -v $SCRIPT_DIR/kilocode_config:/home/dotdev/.kilocode \
  -v $SCRIPT_DIR/dot_claude:/home/dotdev/.claude \
  -v $SCRIPT_DIR/claude.json:/home/dotdev/.claude.json \
  -v $SCRIPT_DIR/dot_local:/home/dotdev/.local \
  -v $SCRIPT_DIR/dot_config:/home/dotdev/.config \
  -v ~/.config/nvim:/home/dotdev/.config/nvim \
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
  -u $(id -u):$(id -g) $IMAGE_NAME bash

# disable when we're done
  xhost -local:docker
