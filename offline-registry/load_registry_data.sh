#!/bin/bash
# 功能: 从线上pull镜像导入线下安装registry
# Author: jyliu
set -e

BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR

if [  -f "../offline-k8s/config.cfg" ];then
        . ../offline-k8s/config.cfg
elif [ -f "../config.cfg" ];then
        . ../config.cfg
else
        . ./config.cfg
fi


export IMAGELIST_FILE_PATH=$1
online_registry=$2


if [ -z "$IMAGELIST_FILE_PATH" ] || [ -z "$online_registry" ];then
        echo "Usage: $0 <IMAGELIST_FILE> <online_registry_domain>  [single_image]"
        exit 1
fi

if [ "$online_registry" == "docker.io" ];then
        online_registry="registry.docker-cn.com"
fi

images=$3
if [ -z "$images" ];then
	images=`./print_json_value.py`
fi

offline_registry="offlineregistry.offline-k8s.com:5000"

mkdir -p ../offline-registry_data
mkdir -p ../offline-images

registry_check(){
        REGISTRY_HEALTH=$(docker ps | grep offline_registry | wc -l)
        if [ "$REGISTRY_HEALTH" -eq 0 ];then
                echo " offline_registry is down,is scrpit is not working" && exit 1
        fi
}

load_offlineregistry(){
	docker pull $offline_registry/$img &>/dev/null && echo "this $offline_registry/$img is ok" || go="ok"
	if [ x"$go" == x"ok" ];then
		docker pull $online_registry/$img &>/dev/null || go="fail"
		if [ x"$go" == x"fail" ];then
			echo "pull $online_registry/$img fail" && exit 1
		fi

		docker tag $online_registry/$img $offline_registry/$img
		if [ x"$go" == x"fail" ];then
			echo "tag $online_registry/$img fail" && exit 1
		fi

		docker push $offline_registry/$img &>/dev/null
		if [ x"$go" == x"fail" ];then
			echo "push $online_registry/$img fail" && exit 1
		fi
	fi
}

save_registry_image(){
	ls ../offline-images/registry.tar.gz ||	docker save $online_registry/library/centos7-docker-registry:v2.5.0.2016090301|gzip > ../offline-images/registry.tar.gz || echo "save registry images to fail."
}

main(){
	registry_check
	echo "##### load_offlineregistry start #####"
	save_registry_image
	for img in $images
	do
		load_offlineregistry
	done
	echo "##### load_offlineregistry end #####"
}

main
