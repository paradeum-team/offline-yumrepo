BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR

# 打包标签，dev 或 stable, dev 从 dev.imagelist.txt取镜像列表
PACKAGEING_TAG=${1:-stable}

./load_concurrent_registry_data.sh ../offline-okd/images_manage/docker.io.imagelist.txt docker.io &
./load_concurrent_registry_data.sh ../offline-okd/images_manage/quay.io.imagelist.txt quay.io &
./load_concurrent_registry_data.sh ../offline-okd/images_manage/registry.access.redhat.com.imagelist.txt registry.access.redhat.com &
./load_concurrent_registry_data.sh ../offline-okd/images_manage/registry.paradeum.com.imagelist.txt registry.paradeum.com &

wait

