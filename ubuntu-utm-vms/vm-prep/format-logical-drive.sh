#!/bin/bash
set -e -x

DEVICE=/dev/$1
VOLUME_GROUP=$2
LOGICAL_VOLUME=lv-$VOLUME_GROUP

pvcreate $DEVICE
vgcreate $VOLUME_GROUP $DEVICE
vgdisplay
# lvcreate --name $LOGICAL_VOLUME -l 100%FREE $VOLUME_GROUP
# mkfs.xfs /dev/$VOLUME_GROUP/$LOGICAL_VOLUME

# lvdisplay /dev/$VOLUME_GROUP/$LOGICAL_VOLUME
# lvremove /dev/app-data/lv-app-data
