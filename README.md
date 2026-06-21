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

Each profile bundles its `user_scripts/` and `root_scripts/` into temporary files consumed by the Dockerfile. `cfg/env` is copied alongside each bundle and sourced (`. ./env`) so scripts have access to API keys and other environment variables at build time.

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

The container runs as the host user (matching UID/GID from `cfg/env`) and drops you into a shell in the code directory.

## `.gitignore`

```
cfg/env                     # User-specific API keys and config
cfg/mounts.cfg              # User-customized mount manifest
profiles/*/mounts/          # Runtime agent state (credentials, caches)
profiles/*/mounts.cfg       # Per-profile mount manifest
```
