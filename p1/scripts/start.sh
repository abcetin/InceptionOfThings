#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

if [ ! -f ../confs/token ]; then
    uuidgen >> ../confs/token
fi

cd ..

docker network create --subnet 192.168.0.0/16 iot
vagrant up