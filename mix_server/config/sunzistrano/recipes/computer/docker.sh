sun.install "ca-certificates curl"

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $CODE stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sun.update

sun.install "docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

sudo usermod -aG docker ${owner_name}

sun.copy '/etc/docker/daemon.json' 0644 root:root
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart docker
