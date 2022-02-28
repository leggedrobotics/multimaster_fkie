Instructions for controlling two Lara5 arms (which are both at IP 192.168.2.13) with two operator PCs

# Summary
Operator PC 1 and operator PC 2 will both have nodes running which are responsible for the Lara motion control, and which will connect to the Ros master on the Lara control PCs.
Additionally, operator PC 1 will have its own Ros master running, together with general nodes, which can communicate to the motion control nodes on the Lara Ros networks on PC 1 and PC2.

# Requirements (Repeat these steps each time you reboot)

1. == Set up the network ==
- PC 1 and PC 2 will be connected with each other through their ethernet ports
- PC 1 and PC2 will both be connected to a Lara control PC through a usb-to-ethernet adapter
- Set up network connections for PC 1 such that it has static IP 192.168.2.1 on the usb-to-ethernet connection with the Lara control PC
- Set up network connections for PC 1 such that it has static IP 192.168.0.1 on the ethernet connection with PC 2
- Set up network connections for PC 2 such that it has static IP 192.168.2.2 on the usb-to-ethernet connection with the Lara control PC
- Set up network connections for PC 2 such that it has static IP 192.168.0.2 on the ethernet connection with PC 1


2. == Enable multicast ==
This is a network communication protocol to send and forward networking messages to all listening devices in a network (typically on IP 224.0.0.1), and is used by the multimaster discovery nodes

- On PC 1 and PC 2 in any terminal window: $ sudo sh -c "echo 1 >/proc/sys/net/ipv4/ip_forward"
- On PC 1 and PC 2 in any terminal window: $ sudo sh -c "echo 0 >/proc/sys/net/ipv4/icmp_echo_ignore_broadcasts"
- On PC 1: find out the name of the network interface of the ethernet connection to PC 2, for example by running $ ifconfig. The name should be something like eth0 or enp0s31f6
- On PC 1 in any terminal window, add a route which directs that all packets starting with 224.0.0.* will be sent over that interface: $ sudo ip route add 224.0.0.0/24 dev eth0  (replace eth0 with correct network interface name)
- On PC 2: find out the name of the network interface of the ethernet connection to PC 1, for example by running $ ifconfig. The name should be something like eth0 or enp0s31f6
- On PC 2 in any terminal window, add a route which directs that all packets starting with 224.0.0.* will be sent over that interface: $ sudo ip route add 224.0.0.0/24 dev eth0  (replace eth0 with correct network interface name)
- Adding the route might have to be repeated if the wired connection is unplugged. In order to see if there is a routing rule present for 224.0.0.0/24, inspect the output of $ ip route


3. == Use the multimaster package to let the Ros networks detect each other ==
The connection between the Ros networks will look as follows: LARA1 <---> MAIN <---> LARA2, with LARA1 and MAIN running on one operator PC, and LARA2 running on operator PC 2

On PC 1, there will be several terminal windows (referred to as "a.*") for the Lara Ros network, and several (named "b.*") in which we will start the local Ros network, which will communicate with both Lara networks
- In terminal 1.a.1 run: $ ROS_MASTER_URI=192.168.2.13; ROS_IP=192.168.2.1
- In terminal 1.a.2 run: $ ROS_MASTER_URI=192.168.2.13; ROS_IP=192.168.2.1
- In terminal 1.a.3 run: $ ROS_MASTER_URI=192.168.2.13; ROS_IP=192.168.2.1
- In terminal 1.b.1-3 run: $ printenv ROS_MASTER_URI   -> verify that this returns http://localhost:11311
- In terminal 2.a.1 run: $ ROS_MASTER_URI=192.168.2.13; ROS_IP=192.168.0.2
- In terminal 2.a.2 run: $ ROS_MASTER_URI=192.168.2.13; ROS_IP=192.168.0.2
- In terminal 2.a.3 run: $ ROS_MASTER_URI=192.168.2.13; ROS_IP=192.168.0.2
- In terminal 2.a.4 run: $ ROS_MASTER_URI=192.168.2.13; ROS_IP=192.168.2.2
* See NOTES below

- In terminal 1.a.1 run: $ roslaunch fkie_master_discovery master_discovery_lara1.launch
- In terminal 1.b.1 run: $ roslaunch fkie_master_discovery master_discovery_main.launch
- In terminal 2.a.1 run: $ roslaunch fkie_master_discovery master_discovery_lara2.launch


4. == Synchronize specific topics between the Ros networks ==
Edit the lauch files in fkie_master_sync/launch to list the topics you want to receive from other ros networks

- In terminal 1.a.2 run: $ roslaunch fkie_master_sync master_sync_lara1.launch
- In terminal 1.b.2 run: $ roslaunch fkie_master_sync master_sync_main.launch
- In terminal 2.a.2 run: $ roslaunch fkie_master_sync master_sync_lara2.launch


5. == Start your own nodes ==
- In terminal 1.a.3 start your motion controller which will communicate with the Lara PC, and will exchange some specified topics with nodes from the MAIN network
- In terminal 2.b.3+ start your general Ros nodes in the MAIN ros network (e.g. object detection, picking strategy planner, etc..)
- In terminal 2.a.3 start a bridging node. This node can exchange specified topics with the MAIN Ros network, and can communicate with the node in 2.a.4, but cannot communicate with the Lara control PC
- In terminal 2.a.4 start your motion controller which will communicate with the Lara PC, and will communicate with the bridging node running in window 2.a.3

* == NOTES ==
Note that on Operator PC 2 the ROS_IP is not the same for each terminal window
All nodes that are required to communicate with Operator PC 1 have to advertise themselves with IP *.0.2 because then Operator PC 1 knows how to contact them
Terminal 2.a.4 has its ROS_IP set to an IP that can be found by the Lara control PC, such that it can communicate with that, but not with Operator PC 1
This situation means that we require a bridging node in terminal 2.a.3 which can communicate both with the MAIN network on Operator PC 1, and with other all other nodes on Operator PC 2, such as the motion control node in 2.a.4
An option is to write a bridging node which just republishes (under different topic names to avoid issues) topics which need to be bridged
NOTE: There might be a possible solution which would remove the need for this bridging node, which I can test later this week



# Tests
== After step 1 ==
- From PC 1 in any terminal window: $ ping 192.168.2.13
- From PC 1 in any terminal window: $ ping 192.168.0.2
- From PC 2 in any terminal window: $ ping 192.168.2.13
- From PC 2 in any terminal window: $ ping 192.168.0.1

== After step 2 ==
- On PC 1 and PC 2, $ ping 224.0.0.1
- You should receive answers from the IP address of the other PC

== After step 3 ==
- In e.g. window 1.a.2, 1.b.2, or 2.1.2 run: $ rosservice call /master_discovery/list_masters
	The discovery node will return the other ros masters it has detected through contacting the other discovery nodes
	
== After step 4 ==
- Test if topics sent from the MAIN ros network can be received on the LARA1 and LARA2 networks and vice versa
- A possible way is to set the /chatter topics in the master_sync launch files
- In terminal window *.*.3 run: $ rosrun roscpp_tutorials talker
- In another terminal window *.*.3 run: $ rostopic echo /chatter



