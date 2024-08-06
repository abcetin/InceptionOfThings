#!/bin/bash

#SCRIPT_DIR=$(dirname "$(realpath "$0")")
#cd "$SCRIPT_DIR"

#vagrant up

sudo apt-get update
sudo apt-get upgrade -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 --tls-san 192.168.56.110 --node-ip 192.168.56.110 --snapshotter=fuse-overlayfs" sh -


# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker vagrant
newgrp docker
sudo systemctl start docker

cd /p2
kubectl apply -f .
