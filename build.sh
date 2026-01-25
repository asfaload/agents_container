#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd $SCRIPT_DIR

. .env

# read user info from env, with default values set to current user
export USER_NAME=${USER_NAME:-$(id -un)}
export USER_ID=${USER_ID:-$(id -u)}
export USER_GROUP=${USER_GROUP:-$(id -g)}

cp ~/local/bin/asfald .
docker build \
  -t $IMAGE_NAME \
  --build-arg USER_NAME \
  --build-arg USER_ID \
  --build-arg USER_GROUP \
  .
