curl -L -o /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && dpkg -i /tmp/google-chrome-stable_current_amd64.deb || true
apt-get -fy install
apt-get update && apt-get install -y \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libgbm1 \
    libxshmfence1 \
    libgl1-mesa-dri
