#!/bin/bash


### SUMMARY ###

# The script below is meant to enable controlling 2 Neura Robotics Lara arms (which both run their own ros master at 192.168.2.13), from one operator PC
# It will do so by creating 2 Linux control groups
# Networking packets for 192.168.2.13 coming from processes which are run inside each of these control groups will be routed exclusively through one of the two network interfaces
# This done by giving these control groups a class id, which can be recognized by Netfilter when it processes these networking packets
# These packets then receive a mark from Netfilter, which will be used to select a custom routing table for these packets
# The entries which we add here to the routing tables specify through which ethernet adapter traffic for 192.168.2.13 should go
# For other networking destinations, the other default routing tables will be consulted as usual
# Finally, use the multiemaster_fkie package to link the ros masters of the Lara control PCs with the ros master running on the operator PC
# Package: git@github.com:leggedrobotics/multimaster_fkie.git     branch: /feature/multiple_lara_arms


### INSTRUCTIONS ###

# Connect the two lara control PCs to your operator PC, e.g. one to your ethernet port, and on via a usb-to-ethernet adapter
# In your network settings, create two identical wired connections (e.g. named "lara1" and "lara2") which are on the same network as the lara control PCs
# The lara control PCs are on IP 192.168.2.13, so your wired connections can be set to static IP of for example 192.168.2.1
# Netmask can be set to 255.255.255.0

# Run 'ifconfig' and find the names of the two network interfaces that are used to communicate with the lara arms
# Your ethernet interface will probably be named something like enp0s31f6, the usb-to-ethernet something like enxc4411efebb22
# Set the interface1/2 variables to the names of these networking interfaces

# Processes can be added to a cgroup with their PID (Process ID)
# To place all processes inside a terminal window inside a cgroup, it is possible to place the shell process in the cgroup, which will be the parent of all other processes started in that shell
# The PID of a shell process can be retrieved with $$. Therefore a shall process can be added to a cgroup with the command: echo $$ | sudo tee /sys/fs/cgroup/net_cls/neura1/tasks
# For ease, I suggest adding an alias to your ~/.bash_alias file for both control groups, as for example: alias cgroup1='echo $$ | sudo tee /sys/fs/cgroup/net_cls/lara1/tasks'

# For each terminal window that will run a lara1/2-related process (i.e. controller node and the multiemaster discovery and sync nodes), first run the command that will add that window's shell to the correct cgroup

# IMPORTANT: Run this script AFTER establishing a networking connection with both lara PCs. The entries to the routing tables can only be added if there is a connection established, and will be removed again each time a connection is unplugged



### SCRIPT ###

# Network interface names (SET THESE TO YOUR NETWORK INTERFACES)
interface1=enp0s31f6
interface2=enxc4411efebb22

# Create routing tables (if there are currently no tables with 'lara' in their names'
echo '... Checking if routing tables need to be created, and creating them if not present yet'
number_of_lara_routing_tables=`cat /etc/iproute2/rt_tables | grep -c lara`
if [ $number_of_lara_routing_tables -eq 0 ]; then
  echo '->  No custom routing tables found for lara1 and lara2. Now adding routing tables to /etc/iproute2/rt_tables'
  echo -e '201\tlara1_routing_table.out' | sudo tee -a /etc/iproute2/rt_tables > /dev/null
  echo -e '202\tlara2_routing_table.out' | sudo tee -a /etc/iproute2/rt_tables > /dev/null
fi

# Create cgroups (will have no effect if groups already exist)
echo '... Creating control groups if not present yet'
sudo cgcreate -g net_cls:lara1
sudo cgcreate -g net_cls:lara2
echo "0x10001" | sudo tee /sys/fs/cgroup/net_cls/lara1/net_cls.classid > /dev/null
echo "0x10002" | sudo tee /sys/fs/cgroup/net_cls/lara2/net_cls.classid > /dev/null

# Mark packets in Netfilter
echo '... Checking Netfilter packet filter rules, and creating them if not present yet'
if ! sudo iptables -t mangle -C OUTPUT -m cgroup --cgroup 0x10001 -j MARK --set-mark 1; then
 echo '->  No packet filter rule found for cgroup mark 1. Now adding rule..'
 sudo iptables -t mangle -A OUTPUT -m cgroup --cgroup 0x10001 -j MARK --set-mark 1
fi

if ! sudo iptables -t mangle -C OUTPUT -m cgroup --cgroup 0x10002 -j MARK --set-mark 2; then
 echo '->  No packet filter rule found for cgroup mark 2. Now adding rule..'
 sudo iptables -t mangle -A OUTPUT -m cgroup --cgroup 0x10002 -j MARK --set-mark 2
fi


# Send marked packets to specific routing tables
echo '... Checking if ip rules exist to forward packets to custom routing tables, and creating them if not present yet'
entry_in_lara1_routing_table_exists=`ip rule list | grep -c 'from all fwmark 0x1 lookup lara1_routing_table.out'`
if [ $entry_in_lara1_routing_table_exists -eq 0 ]; then
  echo '->  No ip rule found for lara1_routing_table.out. Now adding ip rule..'
  sudo ip rule add fwmark 1 table lara1_routing_table.out
fi

entry_in_lara2_routing_table_exists=`ip rule list | grep -c 'from all fwmark 0x1 lookup lara2_routing_table.out'`
if [ $entry_in_lara2_routing_table_exists -eq 0 ]; then
  echo '->  No ip rule found for lara2_routing_table.out. Now adding ip rule..'
  sudo ip rule add fwmark 2 table lara2_routing_table.out
fi

# Route packets through correct port
echo '... Checking if packet routes are present in the custom routing tables, and adding them if not present yet'
echo '... Checking lara1_routing_table.out routing table..'
ip_route_for_lara1_exists=`ip route show table lara1_routing_table.out | grep -c "192.168.2.13 via 192.168.2.13 dev $interface1"`
if [ $ip_route_for_lara1_exists -eq 0 ]; then
  echo '->  No route for lara1 detected. Now adding route to routing table..'
  sudo ip route add 192.168.2.13 via 192.168.2.13 dev $interface1 table lara1_routing_table.out
fi

echo '... Checking lara2_routing_table.out routing table..'
ip_route_for_lara2_exists=`ip route show table lara2_routing_table.out | grep -c "192.168.2.13 via 192.168.2.13 dev $interface2"`
if [ $ip_route_for_lara2_exists -eq 0 ]; then
  echo '->  No route for lara2 detected. Now adding route to routing table..'
  sudo ip route add 192.168.2.13 via 192.168.2.13 dev $interface2 table lara2_routing_table.out
fi

echo -e '\n === Script completed ===\n'
