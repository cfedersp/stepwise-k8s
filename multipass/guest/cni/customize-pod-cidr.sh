#!/bin/bash

jq --arg nodeSubnet 10.85.$1.0/24 '.plugins[0].ipam.ranges[0][0].subnet |= $nodeSubnet' $(dirname $0)/master-11-crio-ipv4-bridge.conflist > 11-crio-ipv4-bridge.conflist
 

