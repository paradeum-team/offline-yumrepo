#!/bin/bash
# get offline okd centos repo
# Author: Liujinye
# Date: 2020-8-17
#
set -e 

# Usage: curl -Ls http://ADDR/packages/centos/get_repo.sh|bash -s ADDR

export DEBIAN_FRONTEND=noninteractive
ADDR=$1
ITEM=$2

if [ -z "$ADDR" ] || [ -z "$ITEM" ] ;then
	echo "Usage: ./$0 <ADDR> <ITEM> ; item value is base|update|openshift-origin|ansible|docker "
	exit 1
fi

cat > /etc/yum.repos.d/offline-k8s.$ITEM.repo << EOF
[offline-k8s${ITEM}_repo]
name=Offline K8s CentOS Repo
baseurl=http://$ADDR/packages/centos/$ITEM/x86_64
gpgcheck=0

#[offline-k8s${ITEM}_modules]
#name=offline-k8s${ITEM} modules
#baseurl=http://$ADDR/packages/centos/$ITEM/x86_64
#enabled=1
#gpgcheck=0
#module_hotfixed=1

EOF


