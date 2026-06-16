#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd $SCRIPT_DIR

. .env

cat $SCRIPT_DIR/active_scripts/* >$SCRIPT_DIR/tmp/bundled_scripts.sh

cat $SCRIPT_DIR/active_scripts/root/* >$SCRIPT_DIR/tmp/bundled_root_scripts.sh

cp ~/local/bin/asfald .
docker build \
  -t $IMAGE_NAME \
  --build-arg USER_NAME \
  --build-arg USER_ID \
  --build-arg USER_GROUP \
  .
