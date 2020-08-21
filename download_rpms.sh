#!/bin/bash
set -eo pipefail
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir

base(){
	yum remove -y libseccomp
	yum --downloadonly --downloaddir=./base install epel-relaese
	yum install -y base/epel-release
	sed -i -e "s/^enabled=1/enabled=0/g" /etc/yum.repos.d/epel.repo
	rm -rf base
	yum --downloadonly --downloaddir=./base install  wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct glusterfs-fuse httpd-tools telnet curl lrzsz perf strace vim iotop  createrepo tcpdump iftop nginx nc sysstat haproxy chrony kernel-devel dnsmasq python-docker skopeo bind cockpit-bridge cockpit-docker cockpit-system cockpit-ws flannel iscsi-initiator-utils nfs-utils ntp pyparted python-httplib2 socat conntrack-tools cifs-utils device-mapper-multipath atomic docker docker-novolume-plugin etcd NetworkManager firewalld samba-client
	yum --enablerepo=epel --downloadonly --downloaddir=./base install jq ansible
	# 下载 metrics 相关 rpms
	rm -rf metrics_depend
	yum --downloadonly --downloaddir=./metrics_depend install python-passlib java-1.8.0-openjdk-headless patch
	# 下载系统 update rpms
	rm -rf update
	yum --downloadonly --downloaddir=./update -y update
}

cuda(){
	rm -rf cuda
	if [ ! -f "/etc/yum.repos.d/cuda.repo" ];then
		yum install -y https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-9.2.88-1.x86_64.rpm
		sed -i -e "s/^enabled=1/enabled=0/g" /etc/yum.repos.d/cuda.repo
	fi
	yum --enablerepo=epel --enablerepo=cuda --downloadonly --downloaddir=./cuda install -y xorg-x11-drv-nvidia xorg-x11-drv-nvidia-devel
}

docker(){
	rm -rf docker
	yum --downloadonly --downloaddir=./docker install -y docker
}

nvidia_container_runtime(){
	rm -rf nvidia-container-runtime
	distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
	curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.repo | \
	  tee /etc/yum.repos.d/nvidia-container-runtime.repo
	sed -i -e "s/^enabled=1/enabled=0/g" /etc/yum.repos.d/nvidia-container-runtime.repo
	yum --enablerepo=libnvidia-container --enablerepo=nvidia-container-runtime --downloadonly --downloaddir=./nvidia-container-runtime install  -y nvidia-container-runtime-hook
}

ansible(){
	rm -rf ansible
	yum --enablerepo=epel --downloadonly --downloaddir=./ansible install https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.6.6-1.el7.ans.noarch.rpm ansible pyOpenSSL python2-crypto
	curl https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.6.6-1.el7.ans.noarch.rpm -o ansible/ansible-2.6.6-1.el7.ans.noarch.rpm
}

ceph(){
	cat > /etc/yum.repos.d/ceph.repo << EOF
[ceph]
name=Ceph packages for $basearch
baseurl=https://download.ceph.com/rpm-luminous/el7/x86_64
enabled=0
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF

	# 下载ceph-common相关安装包
	rm -rf ceph
	yum --enablerepo=epel --enablerepo=ceph --downloadonly --downloaddir=ceph install -y ceph-common
}

openshift_origin(){
# 配置openshift origin 3.11 下载源
	cat > /etc/yum.repos.d/CentOS-OpenShift-Origin.repo << EOF
[centos-openshift-origin]
name=CentOS OpenShift Origin
baseurl=http://mirror.centos.org/centos/7/paas/x86_64/openshift-origin311/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-PaaS
[centos-openshift-origin-testing]
name=CentOS OpenShift Origin Testing
baseurl=http://buildlogs.centos.org/centos/7/paas/x86_64/openshift-origin311/
enabled=0
gpgcheck=0
[centos-openshift-origin-future]
name=CentOS OpenShift Origin Testing
baseurl=https://buildlogs.centos.org/centos/7/paas/x86_64/openshift-future/
enabled=0
gpgcheck=0
EOF

	yum install -y yum-utils
	
	openshift_repo_is_release=${1:-"true"}

	# 下载 openshift-origin 相关安装包
	rm -rf openshift-origin311
	mkdir -p openshift-origin311/x86_64/
	if [ "$openshift_repo_is_release" == "false" ];then
		reposync -r centos-openshift-origin-testing --download_path=./ --downloadcomps --download-metadata -l
		mv centos-openshift-origin-testing openshift-origin311/x86_64/RPMS
	else
		reposync -r centos-openshift-origin --download_path=./ --downloadcomps --download-metadata -l
		mv centos-openshift-origin openshift-origin311/x86_64/RPMS
	fi
	yum remove -y yum-utils libxml2-python python-chardet python-kitchen
}

rhsm(){
	# 下载 python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm
	rm -rf rhsm
	mkdir -p rhsm
	cd rhsm
	wget http://mirror.centos.org/centos/7/os/x86_64/Packages/python-rhsm-certificates-1.19.10-1.el7_4.x86_64.rpm 
	cd ../
}

replease_rpms(){
	rm -rf packages/centos/base
	mkdir -p packages/centos/base/x86_64/RPMS/
	mv base/*.rpm packages/centos/base/x86_64/RPMS/
	mv docker/*.rpm packages/centos/base/x86_64/RPMS/
	mv metrics_depend/*.rpm packages/centos/base/x86_64/RPMS/
	mv update/*.rpm packages/centos/base/x86_64/RPMS/
	rm -rf base docker metrics_depend update
	
	# openshift-origin
	rm -rf packages/centos/openshift-origin311
	mv openshift-origin311 centos/
}

main(){
	base
	rhsm
	docker
	ceph
	#ansible
	openshift_origin $2
	replease_rpms
}

main $@
