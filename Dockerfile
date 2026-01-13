FROM ubuntu:24.04

ARG USER_NAME
ARG USER_ID
ARG USER_GROUP
RUN apt-get update && apt-get install -y build-essential curl git unzip ca-certificates gnupg
# added for codenomad
RUN apt-get install -y libwebkit2gtk-4.1-dev build-essential curl wget file libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev lld

# For Google antigravity
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
  gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
  tee /etc/apt/sources.list.d/antigravity.list > /dev/null

# Install google chrome
# this will fail due to missin gdependencies, so we run apt-get -f install after it
RUN curl -L -o /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && dpkg -i /tmp/google-chrome-stable_current_amd64.deb || true
RUN apt-get -fy install



# Install Node.js (example using version 20)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN adduser -u 1002 ${USER_NAME}
USER ${USER_NAME}

# configure git globally so it doesn't mess with the repo's local config
RUN git config --global user.name "Alfred Isak"
RUN git config --global user.email "ai@example.com"


USER root
RUN curl -L -o /tmp/asfald https://github.com/asfaload/asfald/releases/download/v0.9.0/asfald-x86_64-unknown-linux-musl \
 && cd /tmp && echo "0b7e1270ecc5a4c37785511b032477ddc3a7cf718b0b2f8542229f39adf2ce6a  asfald" | sha256sum -c \
 && mv /tmp/asfald /usr/local/bin \
 && chmod +x /usr/local/bin/asfald
WORKDIR /tmp

# Install neovim, asfald checks checksums published by github
RUN asfald https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-x86_64.tar.gz
RUN bash -c "cd /usr/local ; tar zxvf /tmp/nvim-linux-x86_64* ; cd bin; ln -s ../nvim-linux-x86_64*/bin/nvim"

# install npm-installable agents
RUN npm install -g @kilocode/cli
RUN npm i -g @openai/codex
RUN npm install -g @anthropic-ai/claude-code

# install ripgrep from github release
RUN bash -c "asfald https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz && cd /tmp && tar zxvf ripgrep*.tar.gz && cp ripgrep*/rg /usr/local/bin"

USER root
RUN apt-get update && apt-get install -y \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libgbm1 \
    libxshmfence1 \
    libgl1-mesa-dri \
    && rm -rf /var/lib/apt/lists/*
# unavailable packages :
#    libgl1-mesa-glx \
#    libasound2 \

# Install codenomad, a gui for opencode
RUN export VERSION=0.6.0 && cd /tmp && asfald https://github.com/NeuralNomadsAI/CodeNomad/releases/download/v${VERSION}/CodeNomad-Tauri-${VERSION}-linux-x64.deb
RUN dpkg -i /tmp/CodeNomad*.deb
RUN asfald https://github.com/NeuralNomadsAI/CodeNomad/releases/download/v0.6.0/CodeNomad-Tauri-0.6.0-linux-x64.AppImage
RUN mv /tmp/CodeNomad*.AppImage /usr/local/bin && chmod a+x /usr/local/bin/CodeNomad*.AppImage

USER ${USER_NAME}
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN curl -sSL http://dioxus.dev/install.sh | bash
RUN bash -c "PATH=/home/${USER_NAME}/.cargo/bin:$PATH rustup component add rust-analyzer"
RUN curl -LsSf https://mistral.ai/vibe/install.sh | bash

USER root
RUN npm i -g opencode-ai
RUN npm install -g bun
RUN bun add -g @openchamber/web
RUN apt-get update && apt-get install -y antigravity
RUN npm install --global octofriend

USER ${USER_NAME}
