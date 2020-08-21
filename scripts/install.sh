#!/bin/bash
set -e
BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR

# Usage: curl -Ls http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/scripts/install.sh | sh  -s ${CONFIGSERVER_IP} ${CONFIGSERVER_PORT}

# OUTLINE_DNS: 表示是否对接外部dns，true表示对接，false表示采用内部dns,默认采用false也就不需要设置.
# CHRONYD_INSTALL=yes # 是否安装时间同步服务(chronyd),yes表示安装，no表示不安装，默认yes，只有特殊情况不进行安装;
# SELINUX_SWITCH=true # 是否开启selinux，默认true表示开启；false表示关闭
# SWAP_SWITCH=false # 是否禁用swap，默认false禁用；true表示开启
# IS_SYSTEM_UPGRATE="true" # 是否升级系统以及系统内核，默认不升级系统及系统内核

CONFIGSERVER_IP=$1
CONFIGSERVER_PORT=$2



CONFIGSERVER_IP=${CONFIGSERVER_IP:-192.168.1.216}
CONFIGSERVER_PORT=${CONFIGSERVER_PORT:-8081}

# 当同步脚本时以下命令根据config.cfg文件进行替换
IS_SYSTEM_UPGRATE=false
SWAP_SWITCH=false
SELINUX_SWITCH=true
CHRONYD_INSTALL=yes
OUTLINE_DNS=false
OKD_IMAGE_VERSION=v3.11.0

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
	mkdir -p /etc/yum.repos.d/repobak && mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/repobak/ || echo $?

	# install offline yumrepo
	repos=`curl -s http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/packages/centos/ |grep -wo '>.*.x86_64.rpms.txt<'|tr -d '>|<'|awk -F. '{print $1}'`
	for item in $repos;do
	    curl -Ls http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/packages/centos/get_repo.sh|bash -s ${CONFIGSERVER_IP}:${CONFIGSERVER_PORT} $item
	done

	# yum clean cache
	yum clean all && yum-complete-transaction --cleanup-only || echo $?
}

install_base_tools(){
	echo "------------------- install base tools ------------------- "
	yum install -y wget git net-tools  iptables-services bridge-utils  kexec-tools sos psacct java-1.8.0-openjdk-headless \
	 python-ipaddress  telnet curl lrzsz jq perf strace vim iotop python-passlib \
	origin-node-* origin-clients-* conntrack-tools nfs-utils glusterfs-fuse ceph-common iscsi-initiator-utils device-mapper-multipath logrotate \
	origin-docker-excluder bash-completion dnsmasq httpd-tools bind-utils firewalld libselinux-python openssl iproute python-dbus PyYAML yum-utils cockpit-ws \
	cockpit-system cockpit-bridge cockpit-docker atomic
}

optimize_journald(){
	echo "------------------- optimize journald -------------------"
	curl -Ls -o /etc/systemd/journald.conf  http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/journald.conf
	systemctl restart systemd-journald.service
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

optimize_ulimit(){
	echo "------------------- optimize ulimit -------------------"
	curl -Ls -o /etc/security/limits.d/30-nproc.conf http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/30-nproc.conf
}

optimize_sysctl(){
	echo "------------------- optimize sysctl -------------------"
	curl -Ls -o /etc/sysctl.conf  http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/sysctl.conf
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
	yum install -y chrony
	curl -Ls -o /etc/chrony.conf http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/chrony.conf
	sed -i 's/--CONFIGSERVER_IP--/'${CONFIGSERVER_IP}'/g'  /etc/chrony.conf
	systemctl restart chronyd
	systemctl enable chronyd
}

update_system(){
	echo "------------------- update system -------------------"
	yum update -y
	ls  /etc/yum.repos.d/CentOS-* &>/dev/null && mv -f /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/repobak/ || echo
}

install_docker(){
	echo "------------------- install docker -------------------"
	yum install docker -y
        docker version || echo $?
	# config /etc/sysconfig/docker
	OPTIONS='"--selinux-enabled --signature-verification=false -s overlay2 --log-driver=journald --registry-mirror=https://offlineregistry.dataman-inc.com:5000"'
	sed -i 's#^OPTIONS=.*#OPTIONS='"$OPTIONS"'#g' /etc/sysconfig/docker
	#EXIST_INSECURE_REGISTRY=`cat /etc/sysconfig/docker | grep "offlineregistry.dataman-inc.com:5000 " | wc -l`
	#if [ "$EXIST_INSECURE_REGISTRY" -eq 0 ]; then
	#	echo "ADD_REGISTRY='--add-registry offlineregistry.dataman-inc.com:5000'" >> /etc/sysconfig/docker
	#	echo "INSECURE_REGISTRY='--insecure-registry offlineregistry.dataman-inc.com:5000 --insecure-registry 172.30.0.0/16'" >> /etc/sysconfig/docker
	#fi

	systemctl enable docker
	systemctl start docker
	docker info
}

config_resolv(){
	echo "------------------- config resolv -------------------"
	chattr -i /etc/resolv.conf
        cat <<EOF > /etc/resolv.conf
# Generated by NetworkManager
nameserver ${CONFIGSERVER_IP}
EOF
	chattr +i /etc/resolv.conf
}

set_node_label(){
	echo "------------------- set label -------------------"
	touch /etc/.offline-okd-add-node
}

install_nivdia_dirver(){
	echo "------------------- install nvidia driver -------------------"
	yum -y install xorg-x11-drv-nvidia xorg-x11-drv-nvidia-devel
	modprobe -r nouveau
	nvidia-modprobe && nvidia-modprobe -u
	nvidia-smi --query-gpu=gpu_name --format=csv,noheader --id=0 | sed -e 's/ /-/g'

	echo "------------------- install nvidia-container-runtime-hook -------------------"
	yum -y install nvidia-container-runtime-hook
	cat <<'EOF' > /usr/libexec/oci/hooks.d/oci-nvidia-hook
#!/bin/bash
/usr/bin/nvidia-container-runtime-hook $1
EOF
	chmod +x /usr/libexec/oci/hooks.d/oci-nvidia-hook

	cat <<'EOF' > /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json
{
   "hook": "/usr/bin/nvidia-container-runtime-hook",
   "stage": [ "prestart" ]
}
EOF

	chcon -t container_file_t  /dev/nvidia* || echo "ignore chcon error"
}

networkManagerEnable(){
	echo "##### networkManager init start #####"
	systemctl start NetworkManager
	systemctl enable NetworkManager
	sed -i 's/^NM_CONTROLLED=.*/NM_CONTROLLED=yes/g' /etc/sysconfig/network-scripts/ifcfg-[^\(lo\)]* && systemctl restart network || echo ?
	if [ "x$OUTLINE_DNS" == "x" ] || [ "x$OUTLINE_DNS" == "xfalse" ]; then
		sed -i 's/NOZEROCONF=/\#NOZEROCONF=/g' /etc/sysconfig/network || echo ?
        	sed -i 's/HOSTNAME=/\#HOSTNAME=/g' /etc/sysconfig/network || echo ?
        	sed -i 's/^exclude=/#&/g' /etc/yum.conf || echo ?
		ifcfgs=`ls /etc/sysconfig/network-scripts/ifcfg-[^\(lo\)]*`
		for ifcfg in $ifcfgs;do
			sed -i '/^PEERDNS/d' $ifcfg
			echo "PEERDNS=no" >> $ifcfg
		done
		# 清理network DNS配置
        	sed -i '/^DNS/d' /etc/sysconfig/network-scripts/ifcfg-[^\(lo\)]* && systemctl restart network || echo 'ignore error.'
	fi		
	echo "##### networkManager init end #####"
}

# pre pull images
preImage(){
	echo "##### pre pull images start #####"
	docker pull offlineregistry.dataman-inc.com:5000/openshift/origin-node:${OKD_IMAGE_VERSION}
	docker pull offlineregistry.dataman-inc.com:5000/openshift/origin-pod:${OKD_IMAGE_VERSION}
	echo "##### pre pull images end #####"
}

install_setup(){
	chattr +i /etc/resolv.conf
	check_var
	install_offline_yumrepo
	install_base_tools
	optimize_journald
	disable_firewalld
	if [ "x$SELINUX_SWITCH" != "xfalse" ]; then
		enable_selinux	
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
	#config_resolv
	if [ "x$IS_SYSTEM_UPGRATE" == "xtrue" ]; then
		update_system
	fi
	install_docker
	install_nivdia_dirver
	networkManagerEnable
	set_node_label
	preImage
	reboot
}

uninstall_setup(){
	echo "##### uninstall node start #####"
	/data/solar/init/scripts/uninstall.sh
	echo "##### uninstall node end #####"
}

main(){
	if [ -f "/etc/.offline-okd-add-node" ]; then
                uninstall_setup
        else
                install_setup
        fi
}
main
