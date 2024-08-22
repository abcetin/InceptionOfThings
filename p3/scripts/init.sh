#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

argocd=8081
will=8080

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl

alias k=kubectl

wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
IP=$(ip addr show enp0s3 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
k3d cluster create p3 --k3s-arg '--disable=traefik@server:*' --api-port $IP:6550
server=$(sudo docker ps -a | grep rancher | awk '{print $1}')

kubectl create namespace dev
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment/argocd-server -n argocd
kubectl rollout status deployment/argocd-redis -n argocd

kubectl apply -f ../confs/application.yaml
kubectl apply -f ../confs/deployment.yaml

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

USERNAME=$(whoami)

kubectl create secret generic p3-secret \
    --from-literal=type=git \
    --from-literal=url=git@github.com:abcetin/acetin.git \
    --from-file=sshPrivateKey=/home/$USERNAME/.ssh/id_rsa \
    -n argocd

kubectl label secret p3-secret argocd.argoproj.io/secret-type=repo-creds -n argocd

argo_passwd=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojsonpath='{.data.password}' | base64 --decode)

kubectl port-forward -n argocd --address 127.0.0.1 svc/argocd-server 8081:443 > /dev/null 2>&1 &
kubectl port-forward -n dev --address 127.0.0.1 svc/wil-playground 8080:8888 > /dev/null 2>&1 &

sleep 10
argocd login --insecure --username "admin" --password $argo_passwd 127.0.0.1:8081
argocd repo add --insecure-skip-server-verification https://github.com/abcetin/acetin.git
echo -e "Argocd: http://127.0.0.1:8081"
echo -e "Will: http://127.0.0.1:8080"
echo -e "Argocd Password: $argo_passwd "
