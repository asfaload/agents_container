# init_profile.sh Design

## Goal

A utility script that initializes a new profile scaffold under `profiles/<name>/`, creating the standard directory structure and copying the sample mount manifest.

## Usage

```bash
./utils/init_profile.sh <name>
```

## What it creates

Given `init_profile.sh python`:

```
profiles/python/
  mounts/               # Runtime data directory (gitignored)
  container_scripts/    # Startup scripts sourced by ENTRYPOINT
  root_scripts/         # Scripts run as root during Docker build
  user_scripts/         # Scripts run as USER during Docker build
  mounts.cfg            # Copied from cfg/mounts.cfg.sample
```

## Behavior

- Errors if no name argument is provided
- Errors if `profiles/<name>/` already exists (no overwrite)
- Creates all four subdirectories
- Copies `cfg/mounts.cfg.sample` → `profiles/<name>/mounts.cfg`
- Uses `SCRIPT_DIR` relative pathing consistent with `build.sh` and `run.sh`
