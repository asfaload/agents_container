RUN curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
RUN usermod -aG docker $USER_NAME
RUN usermod -aG systemd-network $USER_NAME
