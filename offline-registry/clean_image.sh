#!/bin/bash
set -e
BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR

docker stop offline-registry
rm -rf ../offline-registry_data
mkdir -p ../offline-registry_data
docker start offline-registry
