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

run_category_menu() {
  while true; do
    echo >&2
    echo "Select category:" >&2
    echo "  1) root_scripts" >&2
    echo "  2) user_scripts" >&2
    echo "  3) container_scripts" >&2
    echo "  4) Done — exit" >&2
    echo >&2
    read -r -p "> " choice

    case "$choice" in
      1) echo "root_scripts"; return ;;
      2) echo "user_scripts"; return ;;
      3) echo "container_scripts"; return ;;
      4|"") echo ""; return ;;
      *) echo "Invalid choice. Enter 1-4." >&2 ;;
    esac
  done
}

render_toggle_list() {
  local category="$1"
  local -n scripts_ref="$2"
  local -n toggles_ref="$3"
  local i filename

  echo
  echo "=== $category ($(profile_script_dir_for "$category")) ==="
  echo

  scripts_ref=()
  toggles_ref=()

  i=0
  while IFS= read -r filename; do
    scripts_ref+=("$filename")
    if is_linked "$category" "$filename"; then
      toggles_ref+=("1")
      printf "  [*] %2d) %s\n" $((i + 1)) "$filename"
    else
      toggles_ref+=("0")
      printf "  [ ] %2d) %s\n" $((i + 1)) "$filename"
    fi
    i=$((i + 1))
  done < <(list_available_scripts "$category")
}

run_toggle_menu() {
  local category="$1"
  local -a scripts=()
  local -a toggles=()
  local input num idx

  render_toggle_list "$category" scripts toggles

  if [ ${#scripts[@]} -eq 0 ]; then
    echo "(no scripts available in $category)"
    return
  fi

  while true; do
    echo
    read -r -p "Toggle numbers (e.g. '2 4'), 'b' back, Enter to confirm: " input

    if [ "$input" = "b" ] || [ "$input" = "B" ]; then
      echo "  (no changes applied)"
      return
    fi

    if [ -z "$input" ]; then
      break
    fi

    input=${input//,/ }
    for num in $input; do
      if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#scripts[@]}" ]; then
        idx=$((num - 1))
        if [ "${toggles[$idx]}" = "1" ]; then
          toggles[$idx]="0"
          printf "  [-] %s\n" "${scripts[$idx]}"
        else
          toggles[$idx]="1"
          printf "  [+] %s\n" "${scripts[$idx]}"
        fi
      else
        echo "  Invalid number: $num" >&2
      fi
    done
  done

  echo

  for i in "${!scripts[@]}"; do
    if [ "${toggles[$i]}" = "1" ] && ! is_linked "$category" "${scripts[$i]}"; then
      link_script "$category" "${scripts[$i]}"
    elif [ "${toggles[$i]}" = "0" ] && is_linked "$category" "${scripts[$i]}"; then
      unlink_script "$category" "${scripts[$i]}"
    fi
  done
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

main() {
  while true; do
    category=$(run_category_menu)
    if [ -z "$category" ]; then
      echo "Done."
      exit 0
    fi
    run_toggle_menu "$category"
  done
}

main "$@"
