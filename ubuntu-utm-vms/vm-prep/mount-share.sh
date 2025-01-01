#!/bin/bash

mkdir -p /usr/share/host/
mount -t 9p -o trans=virtio share /usr/share/host -oversion=9p2000.L
echo "share   /usr/share/host       9p      trans=virtio,version=9p2000.L      0      0" >> /etc/fstab
