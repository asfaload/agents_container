#!/bin/bash
set -e

if [ -f /tmp/bundled_container_scripts.sh ]; then
  cd /tmp && bash /tmp/bundled_container_scripts.sh
fi

exec "$@"
