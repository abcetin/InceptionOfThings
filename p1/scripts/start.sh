#!/bin/bash

if ! command -v vagrant &> /dev/null
then

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
fi

#dosyaları bulunduğu dizinden araması için yapıyoruz
SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

acetinS=""

acetinSW=""

user=""

username=$(whoami)

if [ -f ../confs/authorized_keys ]; then
    acetinS=$(cat ../confs/authorized_keys | grep -w 'acetinS')
    acetinSW=$(cat ../confs/authorized_keys | grep -w "acetinSW")
    user=$(cat ../confs/authorized_keys | grep -w "$username")
fi

if [ ! -f ../confs/acetinS_rsa ]; then
    ssh-keygen -t rsa -f ../confs/acetinS_rsa -N "" -C "vagrant@acetinS"
fi

if [ ! -f ../confs/acetinSW_rsa ]; then
    ssh-keygen -t rsa -f ../confs/acetinSW_rsa -N "" -C "vagrant@acetinSW"
fi

if [ "$user" == "" ]; then
    cat ~/.ssh/id_rsa.pub >> ../confs/authorized_keys
fi

if [ "$acetinS" == "" ]; then
    cat ../confs/acetinS_rsa.pub >> ../confs/authorized_keys
fi

if [ "$acetinSW" == "" ]; then
    cat ../confs/acetinSW_rsa.pub >> ../confs/authorized_keys
fi
if [ ! -f ../confs/token ]; then
    uuidgen >> ../confs/token
fi

cd ..

vagrant up