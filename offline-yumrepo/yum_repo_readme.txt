install repo command:
curl -Ls http://172.26.117.85:8001/packages/centos/get_repo.sh|bash -s 172.26.117.85:8001 base

yum install command:
yum --disablerepo=\* --enablerepo=offline-k8s* install -y <PACKAGE_NAME>

install docker-compose:
curl -o /usr/bin/docker-compose http://172.26.117.85:8001/config/docker-compose-1.8.0/docker-compose
