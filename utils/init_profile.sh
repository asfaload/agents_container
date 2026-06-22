#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/..

if [ $# -eq 0 ]; then
  echo "Usage: $0 <profile-name>" >&2
  exit 1
fi

PROFILE="$1"
PROFILE_DIR="$SCRIPT_DIR/profiles/$PROFILE"

if [ -d "$PROFILE_DIR" ]; then
  echo "Error: profile directory already exists: $PROFILE_DIR" >&2
  exit 1
fi

mkdir -p "$PROFILE_DIR/mounts"
mkdir -p "$PROFILE_DIR/container_scripts"
mkdir -p "$PROFILE_DIR/root_scripts"
mkdir -p "$PROFILE_DIR/user_scripts"

cp "$SCRIPT_DIR/cfg/mounts.cfg.sample" "$PROFILE_DIR/mounts.cfg"

ln -sfr "$SCRIPT_DIR/scripts/user_scripts/ccusage.sh" "$PROFILE_DIR/user_scripts/ccusage.sh"
ln -sfr "$SCRIPT_DIR/scripts/root_scripts/opencode.sh" "$PROFILE_DIR/root_scripts/opencode.sh"
ln -sfr "$SCRIPT_DIR/scripts/container_scripts/opencode-superpowers.sh" "$PROFILE_DIR/container_scripts/opencode-superpowers.sh"

echo "Profile '$PROFILE' created at $PROFILE_DIR"
