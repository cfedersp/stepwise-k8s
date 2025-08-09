#!/bin/bash

set -e -x
MAX_WORKERS=$1
if [[ -z "$MAX_WORKERS" ]]; then
  echo "MAX_WORKERS is not set."
  exit 1;
fi
for (( i=3; i<=$MAX_WORKERS; i++ ))
do
    multipass launch --name "worker$i" --disk 100G --bridged --mount ~/Documents/projects/stepwise-k8s/multipass/:/usr/share/host --cloud-init cloud-init/worker-cloud.init
done

