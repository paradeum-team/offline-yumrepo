BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR

echo "all k8s images download is starting..."
./loadimage.sh ../offline-k8s-imagelist/k8s.images.properties

