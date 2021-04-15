#!/bin/bash
set -e
BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR

systemctl stop offline-registry
rm -rf ../offline-registry_data
mkdir -p ../offline-registry_data
systemctl start offline-registry
