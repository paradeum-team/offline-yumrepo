#!/bin/bash
set -e
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir
if [  -f "../offline-k8s/config.cfg" ];then
	. ../offline-k8s/config.cfg
elif [ -f "../config.cfg" ];then
	. ../config.cfg
elif [ -f "./config.cfg" ];then
	. ./config.cfg
fi

CONFIGSERVER_IP=${CONFIGSERVER_IP:-127.0.0.1}
CONFIGSERVER_PORT=${CONFIGSERVER_PORT:-8001}

ps aux|grep "go_simple_serve"|grep -v grep|wc -l|grep 1 || nohup ./go_simple_serve -h $CONFIGSERVER_IP -p $CONFIGSERVER_PORT 1>/tmp/sry_yumrepo.log 2>&1 &

sleep 2

rm -f yum_repo_readme.txt
echo "please look yum_repo_readme.txt"
echo "install repo command:"|tee -a yum_repo_readme.txt

items=`ls -d packages/centos/*/`
for i in $items;do
	item=`basename $i`	
	curl -Ls http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/packages/centos/get_repo.sh|bash -s $CONFIGSERVER_IP:$CONFIGSERVER_PORT $item
	echo "curl -Ls http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/packages/centos/get_repo.sh|bash -s $CONFIGSERVER_IP:$CONFIGSERVER_PORT $item"|tee -a yum_repo_readme.txt
done

echo "" | tee -a yum_repo_readme.txt 
echo "yum install command:" | tee -a yum_repo_readme.txt
echo "yum --disablerepo=\* --enablerepo=offline-k8s* install -y <PACKAGE_NAME>" | tee -a yum_repo_readme.txt
echo "" | tee -a yum_repo_readme.txt
echo "install docker-compose:" | tee -a yum_repo_readme.txt
echo "curl -o /usr/bin/docker-compose http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/config/docker-compose-1.8.0/docker-compose"| tee -a yum_repo_readme.txt
echo

