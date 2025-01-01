#!/bin/bash
set -e -x

USER=$(who am i | awk '{print $1}')
USERHOME="/home/$USER"
install -m 700 -o $USER -g $(groups $(who am i | awk '{print $1}') | cut -f1 -d':') -d  $USERHOME/.kube/
install -m 644 -o $USER -g $(groups $(who am i | awk '{print $1}') | cut -f1 -d':')  /etc/kubernetes/admin.conf $USERHOME/.kube/config

