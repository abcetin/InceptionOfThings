#!/bin/bash

BLUE='\033[0;34m'
gitlab=8181
will=8080
argocd=8081
token=glpat-q1tdxDFFNz_NZ9MtyJxz

echo  -e "${BLUE}--------------------- kubectl kurulumu başladı ---------------------${BLUE}"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl
echo  -e "${BLUE}--------------------- kubectl kurulumu tamamlandı ---------------------${BLUE}"
alias k=kubectl

echo  -e "${BLUE}--------------------- helm kurulumu başladı ---------------------${BLUE}"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
echo  -e "${BLUE}--------------------- helm kurulumu tamamlandı ---------------------${BLUE}"

echo  -e "${BLUE}--------------------- k3d kurulumu başladı ---------------------${BLUE}"

wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash


k3d cluster create bonus --wait --k3s-arg '--disable=traefik@server:*' --api-port 6550 -p "443:443@loadbalancer" -a 5 #-p "$IP:23:22@loadbalancer" -p "$IP:80:80@LoadBalancer"

echo  -e "${BLUE}--------------------- k3d kurulumu tamamlandı ---------------------${BLUE}"


kubectl create namespace gitlab
kubectl create namespace dev
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo  -e "${BLUE}--------------------- argocd cli kurulumu başladı ---------------------${BLUE}"
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
echo  -e "${BLUE}--------------------- argocd cli kurulumu tamamlandı ---------------------${BLUE}"
USERNAME=$(whoami)

domain=$(hostname)
echo  -e "${BLUE}--------------------- gitlab kurulumu başladı ---------------------${BLUE}"
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
    --set certmanager-issuer.email="cetin.ab@outlook.com" \
    --set global.hosts.https=false \
    --set global.hosts.gitlab.name=$domain \
    -f confs/values.yaml \
    -n gitlab --create-namespace 
echo  -e "${BLUE}--------------------- gitlab kurulumu tamamlandı ---------------------${BLUE}"


toolbox=$(kubectl get pod -n gitlab | grep toolbox | awk '{print $1}')

webservice1=$(kubectl get pod -n gitlab | grep webservice | awk 'NR==1 {print $1}')
webservice2=$(kubectl get pod -n gitlab | grep webservice | awk 'NR==2 {print $1}')

echo  -e "${BLUE}toolbox başlatılması bekleniyor... ${BLUE}"
kubectl wait -n gitlab --for=condition=Ready pod/$toolbox --timeout=660s
echo  -e "${BLUE}webservice1 & webservice2 kurulumu bekleniyor ${BLUE}"
kubectl wait -n gitlab --for=condition=Ready pod/$webservice1 --for=condition=Ready pod/$webservice2 --timeout=660s

willService=$(kubectl get svc -n dev | grep will | awk '{print $1}')

echo  -e "${BLUE}serviceler yönlendiriliyor ${BLUE}"

# kubectl port-forward -n gitlab svc/gitlab-webservice-default $gitlab:8181 > /dev/null 2>&1 &
kubectl port-forward -n dev svc/wil-playground $will:8888 > /dev/null 2>&1 &
kubectl port-forward -n argocd svc/argocd-server $argocd:443 > /dev/null 2>&1 &


kubectl cp -n gitlab scripts/create-access-token.sh $toolbox:/tmp/
kubectl exec -it -n gitlab $toolbox -- chmod +x /tmp/create-access-token.sh
kubectl exec -it -n gitlab $toolbox -- /bin/bash -c '/tmp/create-access-token.sh'


curl -k --header "Private-Token: $token" --data "name=InceptionOfThings&visibility=public" "https://gitlab.acetin.com/api/v4/projects"

git config --global user.email "cetin.ab@outlook.com"
git config --global user.name "abcetin"
git config --global http.sslVerify false
if [ ! -f ../.git ]; then
    git init
fi
git remote add origin https://root:$token@gitlab.acetin.com/root/InceptionOfThings.git
git add .
git commit -m "bonus"
git push --set-upstream origin master

git_passwd=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode)
argo_passwd=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojsonpath='{.data.password}' | base64 --decode)

kubectl apply -f confs/application.yaml
kubectl apply -f confs/playground/deployment.yaml

echo  -e "${BLUE}Argocd: http://127.0.0.1:$argocd ${BLUE}"
echo  -e "${BLUE}will Playgorund: http://127.0.0.1:$will ${BLUE}"
echo  -e "${BLUE}Gitlab: https://gitlab.acetin.com ${BLUE}"

argocd login --insecure --username admin --password $argo_passwd 127.0.0.1:$argocd
if argocd repo add --insecure-skip-server-verification https://gitlab.acetin.com/root/InceptionOfThings.git; then
    echo "GitLab reposu başarıyla Argo CD'ye eklendi."
else
    kubectl delete pod -n gitlab $webservice1 $webservice2
fi

echo  -e "${BLUE}Gitlab Password: $git_passwd ${BLUE}"
echo  -e "${BLUE}Argocd Password: $argo_passwd ${BLUE}"
