# init_profile.sh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a utility script that scaffolds a new profile directory under `profiles/<name>/`.

**Architecture:** Single bash script in a new `utils/` directory, following the same pattern as `build.sh` and `run.sh`.

**Tech Stack:** Bash

## Global Constraints

- Script must be standalone bash, no external dependencies
- Script must use `SCRIPT_DIR` relative pathing (same pattern as `build.sh` and `run.sh`)
- Must error on missing name argument
- Must error if profile directory already exists
- Must create `mounts/`, `container_scripts/`, `root_scripts/`, `user_scripts/` subdirectories
- Must copy `cfg/mounts.cfg.sample` to `profiles/<name>/mounts.cfg`

---

### Task 1: Create `utils/init_profile.sh`

**Files:**
- Create: `utils/init_profile.sh`

**Interfaces:**
- Produces: Executable script `utils/init_profile.sh` that takes one positional arg

- [ ] **Step 1: Create the script**

```bash
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

echo "Profile '$PROFILE' created at $PROFILE_DIR"
```

- [ ] **Step 2: Make the script executable**

```bash
chmod +x utils/init_profile.sh
```

- [ ] **Step 3: Verify the script works**

```bash
./utils/init_profile.sh test-new-profile
ls -la profiles/test-new-profile/
cat profiles/test-new-profile/mounts.cfg
```

- [ ] **Step 4: Verify error cases**

```bash
./utils/init_profile.sh  # should fail with usage message
./utils/init_profile.sh test-new-profile  # should fail with "already exists"
```

- [ ] **Step 5: Clean up test profile and commit**

```bash
rm -rf profiles/test-new-profile
git add utils/init_profile.sh docs/superpowers/plans/2026-06-22-init-profile-script.md docs/superpowers/specs/2026-06-22-init-profile-script-design.md
git commit -m "feat: add utils/init_profile.sh to scaffold new profiles"
```
