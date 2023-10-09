#!/bin/bash
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir

#set -x
type createrepo &> /dev/null ||  yum install -y createrepo modulemd-tools

versions=$1

if [ -z "$versions" ];then
	versions=`ls -d */`
fi

rm -f version.txt

for version in $versions
do
	version=`basename $version`
        rm -rf ${version}/x86_64/repodata
	createrepo --update ${version}/x86_64
        repo2module -s stable ${version}/x86_64/ ${version}/x86_64/repodata/modules.yaml
        modifyrepo --mdtype=modules ${version}/x86_64/repodata/modules.yaml ${version}/x86_64/repodata
	find $version -name *.rpm > ${version}.x86_64.rpms.txt
done
