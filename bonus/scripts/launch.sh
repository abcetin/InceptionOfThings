#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

# , \
#       \"default-address-pools\": [ \
#       {\"base\":\"172.17.0.0/16\",\"size\":24}, \
#       {\"base\":\"172.18.0.0/16\",\"size\":24}  \
#       ]

sudo mkdir /etc/docker
echo "{\"dns\": [\"8.8.8.8\", \"8.8.4.4\"]}" | sudo tee /etc/docker/daemon.json

sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker $USER

newgrp docker << e
./kube.sh
# e