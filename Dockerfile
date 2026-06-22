FROM debian:trixie

ARG USER_NAME
ARG USER_ID
ARG USER_GROUP
RUN apt-get update && apt-get install -y build-essential curl git unzip ca-certificates gnupg
# added for codenomad
RUN apt-get install -y libwebkit2gtk-4.1-dev build-essential curl wget file libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev lld

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

USER root
RUN curl -L -O https://github.com/asfaload/asfald/releases/download/v0.9.0/asfald-x86_64-unknown-linux-musl \
    && bash -c "sha256sum --ignore-missing -c <(curl --silent  https://gh.checksums.asfaload.com/github.com/asfaload/asfald/releases/download/v0.9.0/checksums.txt)" \
    && mv asfald-x86_64-unknown-linux-musl /usr/local/bin/asfald \
    && chmod +x /usr/local/bin/asfald
WORKDIR /tmp

# Install neovim, asfald checks checksums published by github
RUN asfald https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-x86_64.tar.gz
RUN bash -c "cd /usr/local ; tar zxvf /tmp/nvim-linux-x86_64* ; cd bin; ln -s ../nvim-linux-x86_64*/bin/nvim"

# install ripgrep from github release
RUN bash -c "asfald https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep-15.1.0-x86_64-unknown-linux-musl.tar.gz && cd /tmp && tar zxvf ripgrep*.tar.gz && cp ripgrep*/rg /usr/local/bin"

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

RUN npm install -g bun
RUN cd /tmp && asfald https://github.com/agavra/tuicr/releases/download/v0.5.0/tuicr-0.5.0-x86_64-unknown-linux-gnu.tar.gz && tar zxvf tuicr* && mv tuicr /usr/local/bin
RUN apt-get update && apt-get install -y jq
USER ${USER_NAME}
RUN mise use -g github:agavra/tuicr

USER root
COPY tmp/env tmp/bundled_root_scripts.sh .
RUN  bash bundled_root_scripts.sh && rm -f env bundled_root_scripts.sh
USER ${USER_NAME}
COPY tmp/env tmp/bundled_scripts.sh .
RUN  bash bundled_scripts.sh && rm -f env bundled_scripts.sh

USER root
COPY scripts/entrypoint.sh /entrypoint.sh
COPY tmp/bundled_container_scripts.sh .
RUN chmod +x /entrypoint.sh
USER ${USER_NAME}
ENTRYPOINT ["/entrypoint.sh"]
