# offline-registry
offline-registry

##imagelist的编辑规约
例如:   
`registry.hisun.netwarps.com/kubebuilder/kube-rbac-proxy:v0.5.0=docker.mirrors.ustc.edu.cn/kubesphere/kube-rbac-proxy:v0.5.0`  
`ghcr.io/banzaicloud/kafka-operator:v0.14.0`  
`ghcr.io/banzaicloud/jmx-javaagent:0.14.0`   
`ghcr.io/banzaicloud/kafka:2.13-2.6.0-bzc.1`  

第一条，因为要修改线下镜像源的地址，即kubesphere->kubebuilder     
大多数情况下，按照后面几条的格式就可以了  



##缺少镜像，需重新下载导入
load_k8s_all_image.sh脚本中已经处理了k8s安装所需的镜像，但意外情况下，需要单独下载导入镜像，则需做如下操作   

1.停止registry   
`./stop.sh`

2.编辑镜像list保存到目录offline-k8s-imagelist中  
more.images.propeties
3.执行下载导入  
`./loadimage.sh ../offline-k8s-imagelist/more.images.propeties`
4.启动registry
`./run.sh`






