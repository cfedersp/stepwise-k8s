#!/bin/bash
set -e -x
IP_ADDRESS=$(ifconfig enp0s1 | grep 'inet ' | awk '{print $2}')
printf "    ensp01:\n      dhcp4: false\n      dhcp6: false\n      addresses:\n      - ${IP_ADDRESS}/24\n" >> /etc/netplan/50-cloud-init.yaml
netplan generate
netplan apply