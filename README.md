# offline-yumrepo

作者： 刘金烨

创建时间：2016-09-03

更新时间：2020-08-21

线下yum源

## 安装方法：

修改../offline-okd/config.cfg 或../config.cfg 或 ./config.cfg中

```
CONFIGSERVER_IP="192.168.1.214"    ## Need to check
CONFIGSERVER_PORT="8081"                ## Need to check
```

安装启动

```
./enable.sh
```

禁用启动并停止

```
./disable.sh
```


## 使用方法：

install repo command:

```
curl -Ls http://192.168.1.214:8081/packages/centos/get_repo.sh|bash -s 192.168.1.214:8081 ansible
curl -Ls http://192.168.1.214:8081/packages/centos/get_repo.sh|bash -s 192.168.1.214:8081 base
curl -Ls http://192.168.1.214:8081/packages/centos/get_repo.sh|bash -s 192.168.1.214:8081 docker
curl -Ls http://192.168.1.214:8081/packages/centos/get_repo.sh|bash -s 192.168.1.214:8081 openshift-origin36
curl -Ls http://192.168.1.214:8081/packages/centos/get_repo.sh|bash -s 192.168.1.214:8081 update
```

yum install command:

```
yum --disablerepo=\* --enablerepo=offline-okd* install -y <PACKAGE_NAME>
```

install docker-compose:

```
curl -o /usr/bin/docker-compose http://192.168.1.214:8081/config/docker-compose-1.8.0/docker-compose
```
