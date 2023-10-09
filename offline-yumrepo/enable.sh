#!/bin/bash
set -ex
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir
if [ -f offline-yumrepo.service ];then
        rm -rf offline-yumrepo.service
fi
cp offline-yumrepo.service.templ offline-yumrepo.service && \
sed -i 's!--script_path--!'$base_dir'!g' offline-yumrepo.service

cp offline-yumrepo.service /usr/lib/systemd/system/
setenforce 0 || echo
systemctl enable offline-yumrepo
systemctl start offline-yumrepo
systemctl status offline-yumrepo
