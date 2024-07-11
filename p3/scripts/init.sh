#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

bash docker.sh

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl

alias k=kubectl

wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

k3d cluster create p3 
server=$(sudo docker ps -a | grep rancher | awk '{print $1}')
sudo docker exec -it $server sh -c "echo \"nameserver 8.8.8.8\" >> /etc/resolv.conf"
sudo docker exec -it $server sh -c "echo \"nameserver 8.8.4.4\" >> /etc/resolv.conf"

kubectl create namespace dev
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

cd ..

kubectl apply -f confs/application.yaml
kubectl apply -f confs/playground/deployment.yaml

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

USERNAME=$(whoami)

kubectl create secret generic p3-secret \
    --from-literal=type=git \
    --from-literal=url=git@github.com:abcetin/InceptionOfThings.git \
    --from-file=sshPrivateKey=/home/$USERNAME/.ssh/id_rsa \
    -n argocd
kubectl label secret p3-secret argocd.argoproj.io/secret-type=repo-creds -n argocd
newgrp docker