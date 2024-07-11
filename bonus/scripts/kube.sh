#!/bin/bash

BLUE='\033[0;34m'
gitlab=8181
will=8080
argocd=8081
token=glpat-q1tdxDFFNz_NZ9MtyJxz
# sudo ip link add name eth1 type dummy #dummy sanal bir sanal ağ arayüzü
# sudo ip addr add 192.168.56.110/24 dev eth1
# sudo ip link set eth1 up

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


IP=`ifconfig eth0 | grep inet | grep -v inet6 | awk '{print $2}'`
echo $IP
# k3d cluster create bonus --api-port 127.0.0.1:6543
k3d cluster create bonus --wait --k3s-arg '--disable=traefik@server:*' --api-port $IP:6550 -p "$IP:443:443@loadbalancer" #-p "$IP:23:22@loadbalancer" -p "$IP:80:80@LoadBalancer"
server=$(sudo docker ps -a | grep rancher | awk '{print $1}')
sudo docker exec -it $server sh -c "echo \"nameserver 8.8.8.8\" >> /etc/resolv.conf"
sudo docker exec -it $server sh -c "echo \"nameserver 8.8.4.4\" >> /etc/resolv.conf"
echo  -e "${BLUE}--------------------- k3d kurulumu tamamlandı ---------------------${BLUE}"


kubectl create namespace gitlab
kubectl create namespace dev
kubectl create namespace argocd

# export NAMESPACE=gitlab
# export RELEASE=gitlab
# ./tls.sh


kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

cd ..

echo  -e "${BLUE}--------------------- argocd cli kurulumu başladı ---------------------${BLUE}"
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
echo  -e "${BLUE}--------------------- argocd cli kurulumu tamamlandı ---------------------${BLUE}"
USERNAME=$(whoami)

# kubectl create secret generic bonus-secret \
#     --from-literal=type=git \
#     --from-literal=url=git@gitlab.acetin.com:root/InceptionOfThings.git \
#     --from-file=sshPrivateKey=/home/$USERNAME/.ssh/id_rsa \
#     -n argocd
# kubectl label secret bonus-secret argocd.argoproj.io/secret-type=repo-creds -n argocd



echo  -e "${BLUE}--------------------- gitlab kurulumu başladı ---------------------${BLUE}"
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
    --set certmanager-issuer.email="cetin.ab@outlook.com" \
    --set global.hosts.domain=acetin.com \
    --set global.hosts.https=false \
    --set global.certificates.customCAs[0].secret=gitlab-internal-tls-ca \
    --set global.workhorse.tls.enabled=true \
    --set gitlab.webservice.tls.secretName=gitlab-internal-tls \
    --set gitlab.webservice.workhorse.tls.verify=true \
    --set gitlab.webservice.workhorse.tls.secretName=gitlab-internal-tls \
    --set gitlab.webservice.workhorse.tls.caSecretName=gitlab-internal-tls-ca \
    -n gitlab --create-namespace 
echo  -e "${BLUE}--------------------- gitlab kurulumu tamamlandı ---------------------${BLUE}"


toolbox=$(kubectl get pod -n gitlab | grep toolbox | awk '{print $1}')

webservice=$(kubectl get pod -n gitlab | grep webservice | awk 'NR==1 {print $1}')


echo  -e "${BLUE}toolbox başlatılması bekleniyor... ${BLUE}"
kubectl wait -n gitlab --for=condition=Ready pod/$toolbox --timeout=660s
echo  -e "${BLUE}webservice kurulumu bekleniyor ${BLUE}"
kubectl wait -n gitlab --for=condition=Ready pod/$webservice --timeout=660s

willService=$(kubectl get svc -n dev | grep will | awk '{print $1}')

echo  -e "${BLUE}serviceler yönlendiriliyor ${BLUE}"

# kubectl port-forward -n gitlab svc/gitlab-webservice-default $gitlab:8181 > /dev/null 2>&1 &
kubectl port-forward -n dev svc/wil-playground $will:8888 > /dev/null 2>&1 &
kubectl port-forward -n argocd svc/argocd-server $argocd:443 > /dev/null 2>&1 &


kubectl cp -n gitlab scripts/create-access-token.sh $toolbox:/tmp/
kubectl exec -it -n gitlab $toolbox -- chmod +x /tmp/create-access-token.sh
kubectl exec -it -n gitlab $toolbox -- /bin/bash -c '/tmp/create-access-token.sh'


curl -k --header "Private-Token: $token" --data "name=InceptionOfThings&visibility=public" "https://gitlab.acetin.com/api/v4/projects"

if [ ! -f ../.git ]; then
    git init
fi

git config --global http.sslVerify false
git add .
git commit -m "bonus"
git push --set-upstream https://root:$token@gitlab.acetin.com/root/InceptionOfThings.git master

kubectl patch -n kube-system configmap coredns -p "$(cat confs/coredns.yaml)"
coredns=$(kubectl get pod -n kube-system | grep coredns | awk '{print $1}')
kubectl delete pod -n kube-system $coredns

git_passwd=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode)
argo_passwd=$(kubectl get secret -n argocd argocd-initial-admin-secret -ojsonpath='{.data.password}' | base64 --decode)

kubectl apply -f confs/application.yaml
kubectl apply -f confs/playground/deployment.yaml

echo  -e "${BLUE}Argocd: http://127.0.0.1:$argocd ${BLUE}"
echo  -e "${BLUE}will Playgorund: http://127.0.0.1:$will ${BLUE}"
echo  -e "${BLUE}Gitlab: https://gitlab.acetin.com ${BLUE}"

argocd login --insecure --username admin --password $argo_passwd 127.0.0.1:$argocd
argocd repo add --insecure-skip-server-verification https://gitlab.acetin.com/root/InceptionOfThings.git

echo  -e "${BLUE}Gitlab Password: $git_passwd ${BLUE}"
echo  -e "${BLUE}Argocd Password: $argo_passwd ${BLUE}"


# kubectl patch -n argocd svc/argocd-server -p '{"spec": {"type": "ClusterIP"}}'
#### configmap te ip yi düzenlemeyi unutma
## ssh-keyscan gitlab.acetin.com | argocd cert add-ssh --batch