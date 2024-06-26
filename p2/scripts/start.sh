#!/bin/bash

#dosyaları bulunduğu dizinden araması için yapıyoruz

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

user=""

username=$(whoami)

if [ -f ../configs/authorized_keys ]; then
    user=$(cat ../configs/authorized_keys | grep -w "$username")
fi

if [ "$user" == "" ]; then
    cat ~/.ssh/id_rsa.pub >> ../configs/authorized_keys
fi

cd ..

vagrant up