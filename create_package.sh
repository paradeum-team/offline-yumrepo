#!/bin/bash
set -ex 
BASE_DIR=$(cd `dirname $0` && pwd)  
HOSTIP=$1
PORT=$2
if [ -z "$HOSTIP" ] || [ -z "$PORT" ];then
	echo "Usage: ./$0 <LOCAL_IP> <PORT>;"
	exit 1
fi
#configure config.cfg
ip_config() {
	CONFIG_DIR=$BASE_DIR"/offline-k8s"
	if [ -f $CONFIG_DIR/config.cfg ];then
        	rm -rf $CONFIG_DIR/config.cfg
	fi
	cp $CONFIG_DIR/config.cfg.example $CONFIG_DIR/config.cfg

	sed -i 's!--local_ip--!'$HOSTIP'!g' $CONFIG_DIR/config.cfg && \
	sed -i 's!--repo_port--!'$PORT'!g' $CONFIG_DIR/config.cfg
}

#create yumrepo packages 
create_yumrepo(){
	echo "create yumrepo is starting...."
	repo_path=$BASE_DIR"/offline-yumrepo"
	cd $repo_path

	#0.before_download setup
	./before_download.sh
	#1.download repo
	./download_rpms.sh

	#2.update repoo
	cd packages/centos/
	./update_repodata.sh
	cd ../..
	#3.enable yumrepo and  install docker (if docker is not install)
	./enable.sh
	command=`cat yum_repo_readme.txt | grep "curl -Ls"`
	echo ${command} | awk '{run=$0;system(run)}'

	yum --disablerepo=\* --enablerepo=offline-k8s* install -y containerd.io-1.2.13
	yum --disablerepo=\* --enablerepo=offline-k8s* install -y docker-ce-19.03.11
	yum --disablerepo=\* --enablerepo=offline-k8s* install -y docker-ce-cli-19.03.11

	rm -rf offline-yumrepo.service
	./disable.sh
	cd ..
} 
# create registry packages
#configure docker
docker_config(){
	mkdir -p /etc/docker
	cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries":["offlineregistry.offline-k8s.com:5000"]
}
EOF

	#docker �~P��~J�
	systemctl daemon-reload
	systemctl restart docker	
}

create_registry(){
	#congigure hosts
cat <<EOF | sudo tee -a /etc/hosts
$HOSTIP offlineregistry.offline-k8s.com
EOF
	cd $BASE_DIR
	echo "create registry is starting..."
	registry_path="offline-registry"
	cd $registry_path

	#1.enable registry
	./enable.sh

	#pull images and push images to offline registry
	./load_k8s_all_image.sh
	./disable.sh

	cd ../
}
kube_flannel(){
	cd $BASE_DIR
        FILE_DIR="offline-k8s-otherfile/flannel"
        rm -rf $FILE_DIR
        mkdir -p $FILE_DIR
        curl https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -o $FILE_DIR/kube-flannel.yml
}
helm(){
	cd $BASE_DIR
        FILE_DIR="offline-k8s-otherfile/helm"
        rm -rf $FILE_DIR
        mkdir -p $FILE_DIR
        curl https://get.helm.sh/helm-v3.5.0-linux-amd64.tar.gz -o  $FILE_DIR/helm-v3.5.0-linux-amd64.tar.gz
}
recommended(){
	cd $BASE_DIR
        FILE_DIR="offline-k8s-otherfile/recommended"
        rm -rf $FILE_DIR
        mkdir -p $FILE_DIR
        curl https://raw.githubusercontent.com/kubernetes/dashboard/v2.1.0/aio/deploy/recommended.yaml -o $FILE_DIR/recommended.yaml
}
local_path_storage(){
	cd $BASE_DIR
        FILE_DIR="offline-k8s-otherfile/local-path-storage"
        rm -rf $FILE_DIR
        mkdir -p $FILE_DIR
        curl https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml -o $FILE_DIR/local-path-storage.yaml
}
main(){
	ip_config
	create_yumrepo
	docker_config
	create_registry
	kube_flannel
	helm
	recommended
	local_path_storage
	#tar zcvf package
	tar -zcvf offline-k8s-install-package.tar.gz offline-k8s offline-registry offline-registry-image offline-registry_data offline-yumrepo offline-k8s-otherfile			
}
main $@
