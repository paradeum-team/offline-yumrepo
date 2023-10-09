#!/bin/bash
#set -e
BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR

# Usage: curl -Ls http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/scripts/install.sh | sh  -s <CONFIGSERVER_IP> <CONFIGSERVER_PORT> [NTP_SERVER]

# OUTLINE_DNS: 表示是否对接外部dns，true表示对接，false表示采用内部dns,默认采用false也就不需要设置.
# CHRONYD_INSTALL=yes # 是否安装时间同步服务(chronyd),yes表示安装，no表示不安装，默认yes，只有特殊情况不进行安装;
# SELINUX_SWITCH=true # 是否开启selinux，默认true表示开启；false表示关闭
# SWAP_SWITCH=false # 是否禁用swap，默认false禁用；true表示开启
# IS_SYSTEM_UPGRATE="true" # 是否升级系统以及系统内核，默认不升级系统及系统内核

CONFIGSERVER_IP=$1
CONFIGSERVER_PORT=$2
NTP_SERVER=$3



CONFIGSERVER_IP=${CONFIGSERVER_IP:-127.0.0.1}
CONFIGSERVER_PORT=${CONFIGSERVER_PORT:-8001}

# 当同步脚本时以下命令根据config.cfg文件进行替换
IS_SYSTEM_UPGRATE=false
SWAP_SWITCH=false
SELINUX_SWITCH=false
CHRONYD_INSTALL=yes
OUTLINE_DNS=false
K8S_IMAGE_VERSION=v1.20.2

check_var(){
	echo "------------------- check yum repo and check raw device -------------------"
	YUM_STATUS=`curl -s -o /dev/null -w "%{http_code}" http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT} || echo $?`
	if [ "x$YUM_STATUS" != "x200" ]; then
		echo "please check yum repo service whether ok or yum repo addr error !!!"
		exit 1
	fi
}

install_offline_yumrepo(){
	echo "------------------- install offline yumrepo -------------------"
	# backup old yumrepo
	#mkdir -p /etc/yum.repos.d/repobak && mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/repobak/ || echo $?

	# install offline yumrepo
	repos=`curl -s http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/packages/centos/ |grep -wo '>.*.x86_64.rpms.txt<'|tr -d '>|<'|awk -F. '{print $1}'`
	for item in $repos;do
	    curl -Ls http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/packages/centos/get_repo.sh|bash -s ${CONFIGSERVER_IP}:${CONFIGSERVER_PORT} $item
	done

	# yum clean cache
	yum clean all
}

install_base_tools(){
	echo "------------------- install base tools ------------------- "
	yum --disablerepo=\* --enablerepo=offline-k8s* install -y wget jq curl
}

disable_firewalld(){
	echo "------------------- disable firewalld  -------------------"
	systemctl disable firewalld
	systemctl stop firewalld
}

enable_selinux(){
	echo "------------------- enable selinux -------------------"
	sed -i 's/^SELINUX=.*/SELINUX=enforcing/g' /etc/selinux/config
}

disable_selinux(){
        echo "------------------- disable selinux -------------------"
        selinuxStatus=`getenforce`
	if [ "Enforcing" == "$selinuxStatus" ];then
	   setenforce 0
	   sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
	fi
}

optimize_ulimit(){
	echo "------------------- optimize ulimit -------------------"
	curl -Ls -o /etc/security/limits.d/30-nproc.conf http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/30-nproc.conf
}

optimize_sysctl(){
	echo "------------------- optimize sysctl -------------------"
	curl -Ls -o /etc/sysctl.d/99-kubernetes-cri.conf  http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/sysctl/99-kubernetes-cri.conf
}

swap_off(){
	echo "------------------- swap off -------------------"
	swapoff -a && sed -i 's/^[^#].*[[:space:]]swap[[:space:]]/#&/g' /etc/fstab
}

optimize_ssh(){
	echo "------------------- optimize ssh -------------------"
	sed -i 's/.*UseDNS no/UseDNS no/g' /etc/ssh/sshd_config
}

time_sync(){
	echo "------------------- time sync -------------------"
	timedatectl set-timezone Asia/Shanghai
	systemctl disable ntpd &>/dev/null || echo
	yum --disablerepo=\* --enablerepo=offline-k8s* install -y chrony
        ip a|grep ${CONFIGSERVER_IP}
        if [ $? -gt 0 ];then
		curl -Ls -o /etc/chrony.conf http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/chrony.conf
		sed -i 's/--CONFIGSERVER_IP--/'${CONFIGSERVER_IP}'/g'  /etc/chrony.conf
        else
            	curl -Ls -o /etc/chrony.conf http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/chrony-master.conf
	fi

	if [ ! -z "$NTP_SERVER" ];then
		grep $NTP_SERVER /etc/chrony.conf || echo "server $NTP_SERVER minpoll 4 maxpoll 10 iburst" >> /etc/chrony.conf
        fi
	systemctl restart chronyd
	systemctl enable chronyd

}

update_system(){
	echo "------------------- update system -------------------"
	yum --disablerepo=\* --enablerepo=offline-k8s* update -y
	#ls  /etc/yum.repos.d/CentOS-* &>/dev/null && mv -f /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/repobak/ || echo
}

install_docker(){
	echo "------------------- install docker -------------------"
	yum --disablerepo=\* --enablerepo=offline-k8s* install docker-ce -y
        docker version || echo $?
        curl -Ls -o /etc/docker/daemon.json http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/docker/daemon.json

	systemctl enable docker
	systemctl start docker
	docker info
}

add_hosts(){
        grep offlineregistry.offline-k8s.com /etc/hosts || echo "$CONFIGSERVER_IP offlineregistry.offline-k8s.com" >> /etc/hosts
}

install_setup(){
	check_var
	install_offline_yumrepo
	install_base_tools
	disable_firewalld
	if [ "x$SELINUX_SWITCH" = "xtrue" ]; then
		enable_selinux
        else
                disable_selinux
	fi
	optimize_ulimit
	optimize_sysctl
	if [ "x$SWAP_SWITCH" != "xtrue" ]; then
		swap_off
	fi
	optimize_ssh
	if [ "x$CHRONYD_INSTALL" != "xno" ]; then
		time_sync
	fi
	if [ "x$IS_SYSTEM_UPGRATE" == "xtrue" ]; then
		update_system
	fi
        add_hosts
	install_docker
	#reboot
}

main(){
        install_setup
}
main
