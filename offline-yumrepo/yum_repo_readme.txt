install repo command:
curl -Ls http://172.17.5.110:8081/packages/centos/get_repo.sh|bash -s 172.17.5.110:8081 base

yum install command:
yum --disablerepo=\* --enablerepo=offline-k8s* install -y <PACKAGE_NAME>

init:
curl -Ls http:///172.17.5.110:8081/scripts/init.sh | sh  -s 172.17.5.110 8081
