#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/..
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

die() {
  echo "Error: $*" >&2
  exit 1
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") --profile PROFILE

Interactively link/unlink shared scripts from scripts/ into a profile's
script directories.

Options:
  --profile PROFILE   Profile name (required)
  -h, --help          Show this help message

EOF
  exit 0
}

script_dir_for() {
  echo "$SCRIPTS_DIR/$1"
}

profile_script_dir_for() {
  echo "$PROFILE_DIR/$1"
}

list_available_scripts() {
  local dir
  dir=$(script_dir_for "$1")
  if [ -d "$dir" ]; then
    for f in "$dir"/*.sh; do
      [ -f "$f" ] && basename "$f"
    done
  fi
}

list_linked_scripts() {
  local dir
  dir=$(profile_script_dir_for "$1")
  if [ -d "$dir" ]; then
    for f in "$dir"/*; do
      if [ -L "$f" ]; then
        basename "$f"
      fi
    done
  fi
}

is_linked() {
  local category="$1" filename="$2"
  local target
  target=$(profile_script_dir_for "$category")/"$filename"
  [ -L "$target" ]
}

link_script() {
  local category="$1" filename="$2"
  local src target

  src=$(script_dir_for "$category")/"$filename"
  target_dir=$(profile_script_dir_for "$category")
  target="$target_dir/$filename"

  mkdir -p "$target_dir"
  ln -sfr "$src" "$target"
  echo "  Linked: $filename"
}

unlink_script() {
  local category="$1" filename="$2"
  local target

  target=$(profile_script_dir_for "$category")/"$filename"

  if [ -L "$target" ]; then
    rm "$target"
    echo "  Unlinked: $filename"
  elif [ -f "$target" ]; then
    echo "  Warning: '$filename' is a regular file, not a symlink. Skipping." >&2
  fi
}

PROFILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done

if [ -z "$PROFILE" ]; then
  die "--profile is required"
fi

if ! [[ "$PROFILE" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  die "invalid profile name '$PROFILE'. Use only alphanumeric characters, hyphens, and underscores."
fi

PROFILE_DIR="$SCRIPT_DIR/profiles/$PROFILE"
if [ ! -d "$PROFILE_DIR" ]; then
  die "profile directory not found: $PROFILE_DIR"
fi
