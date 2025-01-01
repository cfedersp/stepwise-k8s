#!/bin/bash

sed -i "s/$(hostname)/$1/g" /etc/hostname
sed -i "s/$(hostname)/$1/g" /etc/hosts
reboot
