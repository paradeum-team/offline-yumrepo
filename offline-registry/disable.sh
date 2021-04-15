#!/bin/bash
set -ex
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir

systemctl disable offline-registry
systemctl stop offline-registry
rm -f /usr/lib/systemd/system/offline-registry.service
