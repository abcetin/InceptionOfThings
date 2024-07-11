#!/bin/bash

#dosyaları bulunduğu dizinden araması için yapıyoruz

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

acetinS=""

acetinSW=""

user=""

username=$(whoami)

mkdir ../confs

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