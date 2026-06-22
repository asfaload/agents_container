export VERSION=0.6.0 && cd /tmp && asfald https://github.com/NeuralNomadsAI/CodeNomad/releases/download/v${VERSION}/CodeNomad-Tauri-${VERSION}-linux-x64.deb
dpkg -i /tmp/CodeNomad*.deb
asfald https://github.com/NeuralNomadsAI/CodeNomad/releases/download/v0.6.0/CodeNomad-Tauri-0.6.0-linux-x64.AppImage
mv /tmp/CodeNomad*.AppImage /usr/local/bin && chmod a+x /usr/local/bin/CodeNomad*.AppImage
