# offline-k8s-install-package

注：在打包之前需要确认是否需要更新repo信息（路径：offline-yumrepo/download_rpms.sh）以及k8s镜像列表信息（路径：offline-k8s-imagelist/k8s.images.properties）

centos7.9 线下安装k8s安装包的自动打包    


##creat_package.sh用法   

./create_package.sh 本机ip yumrepo使用的端口    

eg:  
./create_package.sh 172.26.117.85 8001  
非root用户，请使用sudo执行   


create_package.sh可以用来完成k8s安装所用的rpm安装包和docker 镜像    

生成 offline-k8s-install-package.tar.gz已经包含下载的rpm包和registry镜像 仓库  

rpm安装使用方法可查看offline-yumrepo下的yum_repo_readme.txt  
镜像仓库包含的镜像list在offline-k8s-imagelist目录下的k8s.images.properties     
