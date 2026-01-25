# AI Agents Image

Docker image containing multiple AI coding agents and development tools.
Tested and used on a Linux host with X11.

This is the image I use daily to work on [Afasign](https://github.com/asfaload/asfasign), so it includes
tools I need that you might not need. If there is interest, I can make it more generally useful, so let me know in the issues.
Until then, I'll keep my personal needs as the defaults in this config.

Includes Claude Code, Codex, opencode(+ codenomad and openchamber), kilocode , Antigravity, mistral-vibe, possibly others if they
were added after this README's last update.

With some languages and tools: Node.js 24, Rust, Bun, ripgrep, git, asfald (downloader), google chrome

# How to use

The file `env.sample` has a list of environent variables that are used.
Copy it to `.env` and edit it with your keys and information, notably the
 API keys for the AI agents you want to use.


## Build the Docker image

```bash
./build.sh
```


## Run

```bash
./run.sh /absolute/path/to/your/code
```

You get a shell in the container in the souce code directory. From there you can start the agent you want.

The container mounts:
- Your code directory at the same location as on your host
- Agents config directories (persisted locally)
- X11/DRI for GUI applications

The container matches host user permissions via `USER_NAME`, `USER_ID`, `USER_GROUP` (defaults to current user).
