FROM debian:trixie

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



# Create the group only if its gid isn't already taken by the base image,
# then create the user with the build-time uid/gid. useradd -g accepts a
# numeric gid even when the existing group has a different name.
RUN if ! getent group ${USER_GROUP} >/dev/null; then groupadd -g ${USER_GROUP} ${USER_NAME}; fi \
    && useradd -m -u ${USER_ID} -g ${USER_GROUP} -s /bin/bash ${USER_NAME}
USER ${USER_NAME}

# configure git globally so it doesn't mess with the repo's local config
RUN git config --global user.name "Alfred Isak"
RUN git config --global user.email "ai@example.com"


USER root
RUN curl -L -O https://github.com/asfaload/asfald/releases/download/v0.9.0/asfald-x86_64-unknown-linux-musl \
    && bash -c "sha256sum --ignore-missing -c <(curl --silent  https://gh.checksums.asfaload.com/github.com/asfaload/asfald/releases/download/v0.9.0/checksums.txt)" \
    && mv asfald-x86_64-unknown-linux-musl /usr/local/bin/asfald \
    && chmod +x /usr/local/bin/asfald
WORKDIR /tmp

# Install neovim, asfald checks checksums published by github
RUN asfald https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-x86_64.tar.gz
RUN bash -c "cd /usr/local ; tar zxvf /tmp/nvim-linux-x86_64* ; cd bin; ln -s ../nvim-linux-x86_64*/bin/nvim"

# install npm-installable agents
RUN npm install -g @kilocode/cli
RUN npm i -g @openai/codex

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
#RUN curl -LsSf https://mistral.ai/vibe/install.sh | bash
#RUN echo "PATH=$PATH:/home/${USER_NAME}/.local/bin"

USER root
# install mise
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV MISE_DATA_DIR="/mise"
ENV MISE_CONFIG_DIR="/mise"
ENV MISE_CACHE_DIR="/mise/cache"
ENV MISE_INSTALL_PATH="/usr/local/bin/mise"
ENV PATH="/mise/shims:$PATH"
RUN mkdir -p /mise/cache && chmod 777 -R /mise
RUN curl https://mise.run | sh


RUN echo "20260323"

RUN npm install -g bun
RUN bun add -g @openchamber/web
RUN apt-get update && apt-get install -y antigravity chromium
RUN npm install -g opkg
RUN cd /tmp && asfald https://github.com/agavra/tuicr/releases/download/v0.5.0/tuicr-0.5.0-x86_64-unknown-linux-gnu.tar.gz && tar zxvf tuicr* && mv tuicr /usr/local/bin
RUN echo "2" && npm i -g opencode-ai
RUN apt-get update && apt-get install -y jq
RUN npm install -g @google/gemini-cli
USER ${USER_NAME}
RUN mise use -g npm:ccusage
#RUN mise use -g npm:@ccusage/opencode
RUN mise use -g github:agavra/tuicr
RUN mise use -g npm:@playwright/cli@latest
RUN playwright-cli install --skills
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://raw.githubusercontent.com/earchibald/gemini-superpowers/main/install-superpowers.sh | bash



USER root
RUN apt-get install -y gettext libgtk-4-1 libevent-2.1  libwoff-dev
USER ${USER_NAME}
RUN mise use dotnet@8
RUN mise use npm:po2json
RUN dotnet new tool-manifest
RUN dotnet tool install Microsoft.Playwright.CLI
USER root
RUN curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
RUN usermod -aG docker $USER_NAME
RUN usermod -aG systemd-network $USER_NAME
USER root
COPY tmp/env tmp/bundled_root_scripts.sh .
RUN  sh bundled_root_scripts.sh
USER ${USER_NAME}
COPY tmp/env tmp/bundled_scripts.sh .
RUN  sh bundled_scripts.sh
