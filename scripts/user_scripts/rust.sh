curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
curl -sSL http://dioxus.dev/install.sh | bash
bash -c "/home/${USER_NAME}/.cargo/bin/rustup component add rust-analyzer"
/home/$USER_NAME/.cargo/bin/cargo install --locked cargo-nextest
echo 'export PATH="$PATH:/home/'"${USER_NAME}"'/.local/bin:/home/'"${USER_NAME}"'/.cargo/bin"' >> "/home/${USER_NAME}/.bashrc"
/home/${USER_NAME}/.cargo/bin/cargo install mdbook
