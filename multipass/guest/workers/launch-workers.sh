#!/bin/bash

set -e -x
REF_VM=$1
STARTNUM=$2
MAX_WORKERS=$3
DISK_SIZE="100G"
if [[ -z "$MAX_WORKERS" ]]; then
  echo "MAX_WORKERS is not set."
  exit 1;
fi
for (( i=$STARTNUM; i<=$MAX_WORKERS; i++ ))
do
    multipass clone $REF_VM --name worker$i
    multipass set local.worker$i.disk=$DISK_SIZE
    multipass set local.worker$i.memory=1G
done
echo "finished cloning..launching instances.."

for (( i=$STARTNUM; i<=$MAX_WORKERS; i++ ))
do
    # multipass launch --name "worker$i" --disk $DISK_SIZE --bridged --mount ~/Documents/projects/stepwise-k8s/multipass/:/usr/share/host 
    # --cloud-init cloud-init/worker-cloud.init
    multipass start "worker$i"
done
echo "launched instances.."
sleep 90
for (( i=$STARTNUM; i<=$MAX_WORKERS; i++ ))
do
    multipass exec worker$i -- sudo mkdir -p /etc/cni/net.d
    multipass exec worker$i -- /usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
    multipass exec worker$i -- sudo kubeadm join --config ./join-config.json  
    multipass exec worker$i -- sudo mkdir -p /var/lib/data/openebs-volumes
done
# for (( i=$STARTNUM; i<=$MAX_WORKERS; i++ ))
# do
#    multipass restart worker$i
# done

