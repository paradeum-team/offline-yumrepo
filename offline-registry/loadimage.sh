#!/bin/bash

file=${1:-"images.properties"}

target_registry="offlineregistry.offline-k8s.com:5000"


load_imamge(){
    v=$1
    k=$2

    docker pull ${v}
    if [ -z "$k" ];then
	k=`echo ${v}|sed 's#^[^/]*#'"${target_registry}"'#'`
    fi
    echo "------------ k=v ${k}=${v}"
    docker tag ${v} ${k}
    #docker rmi ${v}
    docker push ${k}
}

if [ -f "$file" ]
then
  echo "$file found."

  while IFS='=' read -r target source
  do
    load_imamge $source $target &
  done < "$file"

  wait

else
  echo "$file not found."
fi
