#!/bin/bash

#dosyaları bulunduğu dizinden araması için yapıyoruz

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

acetinS=""

acetinSW=""

user=""

username=$(whoami)



if [ -f ../configs/authorized_keys ]; then
    acetinS=$(cat ../configs/authorized_keys | grep -w 'acetinS')
    acetinSW=$(cat ../configs/authorized_keys | grep -w "acetinSW")
    user=$(cat ../configs/authorized_keys | grep -w "$username")
fi

if [ ! -f ../configs/acetinS_rsa ]; then
    ssh-keygen -t rsa -f ../configs/acetinS_rsa -N "" -C "vagrant@acetinS"
fi

if [ ! -f ../configs/acetinSW_rsa ]; then
    ssh-keygen -t rsa -f ../configs/acetinSW_rsa -N "" -C "vagrant@acetinSW"
fi

if [ "$user" == "" ]; then
    cat ~/.ssh/id_rsa.pub >> ../configs/authorized_keys
fi

if [ "$acetinS" == "" ]; then
    cat ../configs/acetinS_rsa.pub >> ../configs/authorized_keys
fi

if [ "$acetinSW" == "" ]; then
    cat ../configs/acetinSW_rsa.pub >> ../configs/authorized_keys
fi
if [ ! -f ../configs/token ]; then
    uuidgen >> ../configs/token
fi

cd ..

vagrant up