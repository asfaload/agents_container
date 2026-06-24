# AI Agents Image

These are the scripts I use to run AI agents in containers on a linux machine
with X11 (the X11 part is only relevant for running graphical tools, if you're
running in the terminal, it is probably irrelevant).

It started as simple scripts to un agents in containers when developing
[Asfaload](https://github.com/asfaload/asfaload), but improved when I started
using it for multiple projects under different user accounts, and using
different tech stacks.

## How to use
```
git clone https://github.com/asfaload/agents_container.git
cd agents_container/cfg
cp env.sample env
# edit env and set environment variable as needed
cd ..
./build.sh --profile default
./run.sh --profile default $PWD
# opens container
opencode
```


## Features

It supports different profiles (see `utils/init_profile.sh`), generating one image per profile (with `build.sh --profile $my_profile`).
Each profile defines:

* what the image contains by running different scripts
* the directories mounted from the host in the container (persisting configs and history)

Software installation in the container is done with 3 types of scripts (each profile has their own):

* root_scripts: these are executed as `root` at image build time.
* user_scripts: these are run as the user at image build time.
* container_scripts: these are run when the container is started. This is
needed when you install an agent plugin that is added to the agent's config
when it's persisted on the host (eg superpowers for opencode).

Sample scripts are available under `scripts/` and can be used from your profiles by soft linking them (see `utils/link-scripts.sh`).
Don't hesitate to contribute new scripts.

When using scripts in your profiles, you can order there execution by naming
them accordingly (see an example in the [Asfaload
profile](https://github.com/asfaload/agents_container/tree/master/profiles/asfaload/user_scripts))

Data persistence is done by mounting directories from the host in the
container. These are defined in the file `mounts.cfg` in each profile. Relative
paths (eg `.claude`) are created in the profile's `mounts` subdirectory, and
mounted in the container under `$HOME`. Absolute paths  (eg
`/var/run/docker.sock`) are mounted from the host to the same path in the
container.

You can create a new profile skeleton with `utils/init_profile.sh $my_profile` and tweak it in `profiles/$my_profile`.
The profile is initialised with a `mounts.cfg` copied from `cfg/mounts.cfg.sample`. Edit it in the profile to tweak it.

Environment variables are defined in `cfg/env` and are shared with all scripts (`build.sh`, `run.sh`, and profiles's scripts.)

The user name and email to be used if your agent commits to a git repo are configured in `cfg/git-config.sh` (see `cfg/git-config.sh.sample`).
A file name identically in your profile directory (`profiles/$profile_name/git-config.sh`) takes precedence.

Further documentation below was mainly written by an LLM agent.

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

### `utils/link-scripts.sh` — Manage script links in a profile

```bash
./utils/link-scripts.sh --profile <name>
```

Interactively link and unlink shared scripts from `scripts/` into a profile's `root_scripts/`, `user_scripts/`, and `container_scripts/` directories. Select a category, toggle scripts on/off by number, and confirm to apply changes. The tool creates relative symlinks (`ln -sfr`) matching the existing convention.

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
