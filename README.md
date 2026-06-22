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

### `mounts.cfg` — Mount manifest

`cfg/mounts.cfg` is the global manifest. A per-profile `profiles/<name>/mounts.cfg` overrides it if present. Entries support two forms:

- **Relative paths** (no leading `/`): seeded inside `profiles/<name>/mounts/` and mounted at `$HOME/<name>` in the container. Trailing `/` creates directories, otherwise files.
- **Absolute paths** (leading `/`): bind-mounted directly from host to container at the same path. Useful for devices, sockets, or any host resource.

```
# Relative — creates in mounts/ dir, mounted at $HOME/.claude/
.claude/
.config/
claude.json

# Absolute — bind-mounted host-to-container at the same path
/var/run/docker.sock
/dev/dri/card0
/dev/dri/renderD128
```

## Profiles

Profiles live under `profiles/<name>/`. Each can have:

| Directory/File | Purpose |
|---|---|
| `mounts/` | Persistent runtime data mounted into the container at `$HOME/<path>` (gitignored) |
| `mounts.cfg` | Optional per-profile mount manifest (overrides `cfg/mounts.cfg`) |

The `default` profile is used when no `--profile` flag is given.

Scripts are shared across all profiles under `scripts/`:

| Directory | Purpose |
|---|---|
| `scripts/user_scripts/` | Scripts run as `USER` during Docker build (→ `bundled_scripts.sh`) |
| `scripts/root_scripts/` | Scripts run as `root` during Docker build (→ `bundled_root_scripts.sh`) |
| `scripts/container_scripts/` | Scripts run at container **startup** via ENTRYPOINT (→ `bundled_container_scripts.sh`) |

### `utils/init_profile.sh` — Scaffold a new profile

```bash
./utils/init_profile.sh <name>
```

Creates `profiles/<name>/` with all standard subdirectories (`mounts/`, `container_scripts/`, `root_scripts/`, `user_scripts/`) and copies `cfg/mounts.cfg.sample` as `profiles/<name>/mounts.cfg`.

## Build

```bash
./build.sh                          # build default profile
./build.sh --profile python         # build python profile (image tagged IMAGE_NAME-python)
```

All profiles share the same set of scripts from `scripts/`, bundled into temporary files consumed by the Dockerfile:

| Bundle | Runs as | When |
|---|---|---|
| `bundled_scripts.sh` | `USER` | Image build (`RUN sh bundled_scripts.sh`) |
| `bundled_root_scripts.sh` | `root` | Image build (`RUN sh bundled_root_scripts.sh`) |
| `bundled_container_scripts.sh` | `USER` | Container startup (sourced by entrypoint before `exec "$@"`) |

`cfg/env` is copied alongside root and user build bundles and sourced (`. ./env`) so scripts have access to API keys during image build. After execution, `env` and the bundle are deleted to avoid baking secrets into the image. The container startup bundle (`bundled_container_scripts.sh`) does **not** receive a copy of `env` — runtime environment variables are passed via `docker run --env` in `run.sh`.

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
2. The mount manifest is resolved: `profiles/<name>/mounts.cfg` if it exists, else `cfg/mounts.cfg`.
3. Each manifest entry is processed:
   - **Absolute paths** (starting with `/`): added as `-v /path:/path` bind mounts directly.
   - **Relative paths**: created inside `profiles/<name>/mounts/` (dirs with `mkdir`, files with `touch`) then later mounted as `-v <entry>:/home/$user/<basename>`.
4. Infrastructure mounts are added unconditionally:
   - Code directory (first argument)
   - `~/.config/nvim`
   - X11 socket (`/tmp/.X11-unix`)
   - DRI devices (`/dev/dri/card0`, `/dev/dri/renderD128`)
   - `--device /dev/dri`, `--device /dev/snd`
   - `--shm-size 2gb`

Before handing off to the shell, the ENTRYPOINT (`scripts/entrypoint.sh`) sources `bundled_container_scripts.sh`, so per-profile startup logic runs automatically and has access to `cfg/env` vars.

The container runs as the host user (matching UID/GID from `cfg/env`) and drops you into a shell in the code directory.

## `.gitignore`

```
cfg/env                     # User-specific API keys and config
cfg/mounts.cfg              # User-customized mount manifest
profiles/*/mounts/          # Runtime agent state (credentials, caches)
profiles/*/mounts.cfg       # Per-profile mount manifest
```
