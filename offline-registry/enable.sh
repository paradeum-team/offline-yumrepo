#!/bin/bash
set -ex
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir
if [ -f offline-registry.service ];then
	rm -rf offline-registry.service
fi
cp offline-registry.service.templ offline-registry.service && \
sed -i 's!--script_path--!'$base_dir'!g' offline-registry.service

cp offline-registry.service /usr/lib/systemd/system/
systemctl enable offline-registry
systemctl start offline-registry
