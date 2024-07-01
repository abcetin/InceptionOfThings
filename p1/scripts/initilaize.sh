#!/bin/bash

HOSTNAME=$(hostname)

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install sshpass

chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub /home/vagrant/.ssh/authorized_keys

# echo "export PATH=$PATH:/usr/sbin" >> home/vagrant/.bashrc
# source home/vagrant/.bashrc

TOKEN=$(cat /home/vagrant/token)

if [ "$HOSTNAME" == "acetinS" ]; then
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 --tls-san 192.168.56.110 --node-ip 192.168.56.110" K3S_TOKEN="$TOKEN" sh -
else
    curl -sfL https://get.k3s.io | K3S_TOKEN="$TOKEN" INSTALL_K3S_EXEC="agent --server https://192.168.56.110:6443 --node-ip 192.168.56.111 --log /var/log/k3s-agent.log" sh -
fi