# Resolve the effective services config file for a profile.
# The profile's own services.cfg replaces the global one; they are never merged.
# Prints the path on success, returns 1 when neither file exists.
resolve_services_file() {
  local profile_dir="$1" script_dir="$2"
  if [ -f "$profile_dir/services.cfg" ]; then
    printf '%s\n' "$profile_dir/services.cfg"
    return 0
  fi
  if [ -f "$script_dir/cfg/services.cfg" ]; then
    printf '%s\n' "$script_dir/cfg/services.cfg"
    return 0
  fi
  return 1
}
