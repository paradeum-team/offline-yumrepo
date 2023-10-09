#!/bin/bash
set -e
BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR
if [ -f "./.env" ];then
	. ./.env
elif [ -f "../.env" ];then
        . ../.evn
elif [  -f "../offline-k8s/.env" ];then
	. ../offline-k8s/.env
fi

registry_image_name=registry:2.8
docker images $registry_image_name | grep registry || docker load -i ../offline-registry-image/registry.gz 

mkdir -p ../offline-registry_data

