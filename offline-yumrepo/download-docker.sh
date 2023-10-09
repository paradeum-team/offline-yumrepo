#!/bin/sh

set -e

if ! test -f /etc/yum.repos.d/docker-ce.repo ;then
	cp docker-ce.repo /etc/yum.repos.d/docker-ce.repo
fi

yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin --downloadonly --destdir ./packages/centos/base/x86_64/rpms/
