#!/bin/bash

# jq '.nodeRegistration.name |= $hostname' --arg hostname $(hostname) $1/master-join-config.json | yq -rRy > ./join-config.yaml
jq '.nodeRegistration.name |= $hostname' --arg hostname $(hostname) $1/master-join-config.json  > ./join-config.json
