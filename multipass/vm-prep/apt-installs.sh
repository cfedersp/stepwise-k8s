#!/bin/bash
set -e -x

apt install network-manager inetutils-traceroute net-tools parted lvm2 netcat-openbsd zip git apt-transport-https ca-certificates curl gnupg2 software-properties-common jo jq yq -y
apt install linux-modules-extra-$(uname -r) -y
