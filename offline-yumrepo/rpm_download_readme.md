# rpm下载说明

## 缺少rpm包处理方法    

1. 停止线下yumrepo源    
`./disable.sh`   
2. 下载缺少的rpm包   
```
rm -rf /etc/yum.repos.d/offline-k8s.base.repo

yum --downloadonly --downloaddir=./more xxx   
mv more/*.rpm packages/centos/base/x86_64/RPMS/   
rm -rf more  

```
3. 更新repo依赖  
```
cd packages/centos/   
./update_repodata.sh
cd ../..   

```
4. 启动   
```
./enable.sh

```
