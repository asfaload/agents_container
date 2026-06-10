#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd $SCRIPT_DIR

. .env


cp ~/local/bin/asfald .
docker build \
  -t $IMAGE_NAME \
  --build-arg USER_NAME \
  --build-arg USER_ID \
  --build-arg USER_GROUP \
  .
