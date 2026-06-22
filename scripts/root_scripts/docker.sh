curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh\nusermod -aG docker "$USER_NAME"\nusermod -aG systemd-network "$USER_NAME"
