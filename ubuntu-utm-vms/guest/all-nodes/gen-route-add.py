import argparse
import socket
import fcntl
import struct

# python3 /usr/share/host/guest/all-nodes/gen-route-add.py cni $(route | grep default | awk '{print $NF}') 10.85.0.0 $(kubectl get nodes -o json | jq -j '[.items[].status.addresses[0].address] | join(" ")')

parser = argparse.ArgumentParser(prog='ProgramName');
parser.add_argument('cniInterface');
parser.add_argument('clusterInterface');
parser.add_argument('startAddress');
parser.add_argument('nodeIps', nargs='*');
args = parser.parse_args();

print(args.cniInterface);
print(args.clusterInterface);
print(args.startAddress);

ipBytes = args.startAddress.split(".")
print(len(args.nodeIps));

def assembleRouteCmd(workerIp, nodeIp, cniInterface):
  return f"ip route add \"{workerIp}/24\" via \"{nodeIp}\""

def get_interface_ip(ifname):
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        return socket.inet_ntoa(fcntl.ioctl(
                s.fileno(),
                0x8915,  # SIOCGIFADDR
                struct.pack('256s', bytes(ifname[:15], 'utf-8'))
                # Python 2.7: remove the second argument for the bytes call
            )[20:24])

allRoutes = []
for idx, nodeIp in enumerate(args.nodeIps):
  nodeNum = int(ipBytes[2])+idx;
  workerIp = ipBytes[0] + "." + ipBytes[1] + "." + str(nodeNum) + "." + ipBytes[3]
  routeCmd = assembleRouteCmd(workerIp, nodeIp, args.cniInterface)
  allRoutes.append(routeCmd);

host_ip = get_interface_ip(args.clusterInterface)

print("Host IP: ",host_ip);

with open(args.cniInterface + "-routes.sh", "w") as f:
  f.write("#!/bin/bash -e -x\n\n")

  for nodeIndex, nodeIp in enumerate(args.nodeIps):
    print(nodeIp);
    routesFromThisNode = [route for routeIndex, route in enumerate(allRoutes) if nodeIndex != routeIndex] #if nodeIp not in route]
    if host_ip == nodeIp:
      [f.write(x + '\n') for x in routesFromThisNode]


