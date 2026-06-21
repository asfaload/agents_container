# AI Agents Image

Docker image containing multiple AI coding agents and development tools.
Tested and used on a Linux host with X11.

Includes Claude Code, Codex, opencode (+ codenomad and openchamber), kilocode, Antigravity, mistral-vibe, and others. Languages and tools: Node.js 24, Rust, Bun, ripgrep, git, asfald, Google Chrome.

## Configuration

### `cfg/env` — Environment variables

Copy `cfg/env.sample` to `cfg/env` and fill in your API keys:

```
export USER_NAME=$(id -u -n)
export USER_ID=$(id -u)
export USER_GROUP=$(id -g)
export IMAGE_NAME=ai_agents_${USER_NAME}
export ANTHROPIC_API_KEY=...
export GEMINI_API_KEY=...
...
```

Required by both `build.sh` and `run.sh`.

### `cfg/mounts.cfg` — Global mount manifest

Defines the files and directories to create in every profile's `mounts/` directory. Lines ending in `/` are directories, otherwise files. `#` comments are ignored.

```
.claude/
.config/
.local/
.kilocode/
claude.json
```

### `profiles/<name>/mounts.cfg` — Per-profile mount manifest

If a profile directory contains its own `mounts.cfg`, it takes precedence over `cfg/mounts.cfg`. This lets different profiles seed different mount structures.

## Profiles

Profiles live under `profiles/<name>/`. Each can have:

| Directory | Purpose |
|---|---|
| `user_scripts/` | Scripts run as the `USER` during Docker build (concatenated and fed to `RUN sh bundled_scripts.sh`) |
| `root_scripts/` | Scripts run as `root` during Docker build (concatenated and fed to `RUN sh bundled_root_scripts.sh`) |
| `mounts/<path>` | Persistent runtime data mounted into the container at `$HOME/<path>` in the container (gitignored) |
| `mounts.cfg` | Optional per-profile mount manifest (overrides `cfg/mounts.cfg`) |

The `default` profile is used when no `--profile` flag is given.

## Build

```bash
./build.sh                          # build default profile
./build.sh --profile python         # build python profile (image tagged IMAGE_NAME-python)
```

Each profile bundles its `user_scripts/` and `root_scripts/` into temporary files consumed by the Dockerfile.

## Run

```bash
./run.sh /path/to/code              # run default profile
./run.sh --profile python /path/to/code   # run python profile
```


You are dropped in a shell inside the container in `/path/to/code`.

For example, if your code is in `~/gits/myproject` running `./run.sh
~/gits/myproject` will start a container and place you in `~/gits/myproject`
inside the container, which is a volume mounted from the host.

### Mounts

1. The profile's `mounts/` directory is created if missing.
2. If `profiles/<name>/mounts.cfg` exists, it seeds the directory structure; otherwise `cfg/mounts.cfg` is used.
3. Every entry in the `mounts/` directory is mounted as `-v <entry>:/home/$user/<basename>`.
4. Infrastructure mounts are added unconditionally:
   - Code directory (first argument)
   - `~/.config/nvim`
   - X11 socket (`/tmp/.X11-unix`)
   - DRI devices (`/dev/dri/card0`, `/dev/dri/renderD128`)
   - Docker socket (`/var/run/docker.sock`)
   - `--device /dev/dri`, `--device /dev/snd`
   - `--shm-size 2gb`

The container runs as the host user (matching UID/GID from `cfg/env`) and drops you into a shell in the code directory.

## `.gitignore`

```
cfg/env                     # User-specific API keys and config
cfg/mounts.cfg              # User-customized mount manifest
profiles/*/mounts/          # Runtime agent state (credentials, caches)
profiles/*/mounts.cfg       # Per-profile mount manifest
```
