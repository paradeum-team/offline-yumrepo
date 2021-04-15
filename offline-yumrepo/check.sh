#!/bin/bash
set -e
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir

if [  -f "../offline-k8s/config.cfg" ];then
        . ../offline-k8s/config.cfg
elif [ -f "../config.cfg" ];then
        . ../config.cfg
else
        . ./config.cfg
fi

curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/|grep 200
