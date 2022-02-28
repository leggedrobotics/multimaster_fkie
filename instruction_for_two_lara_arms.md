Instructions for controlling two Lara5 arms (which are both at IP 192.168.2.13) with two operator PCs

# Summary
Operator PC 1 and operator PC 2 will both have nodes running which are responsible for the Lara motion control, and which will connect to the Ros master on the Lara control PCs.
Additionally, operator PC 1 will have its own Ros master running, together with general nodes, which can communicate to the motion control nodes on the Lara Ros networks on PC 1 and PC2.

# Requirements
1. == Set up the network ==
- PC 1 and PC 2 will be connected with each other through their ethernet ports
- PC 1 and PC2 will both be connected to a Lara control PC through a usb-to-ethernet adapter
- Set up network connections for PC 1 such that it has static IP 192.168.2.1 on the usb-to-ethernet connection with the Lara control PC
- Set up network connections for PC 1 such that it has static IP 192.168.0.1 on the ethernet connection with PC 2
- Set up network connections for PC 2 such that it has static IP 192.168.2.2 on the usb-to-ethernet connection with the Lara control PC
- Set up network connections for PC 2 such that it has static IP 192.168.0.2 on the ethernet connection with PC 1
2. == Enable multicast* ==
- On PC 1 and PC 2 in any terminal window: $ sudo sh -c "echo 1 >/proc/sys/net/ipv4/ip_forward"
- On PC 1 and PC 2 in any terminal window: $ sudo sh -c "echo 0 >/proc/sys/net/ipv4/icmp_echo_ignore_broadcasts"
- On PC 1: find out the name of the network interface of the ethernet connection to PC 2, for example by running $ ifconfig. The name should be something like eth0 or enp0s31f6
- On PC 1 in any terminal window, add a route which directs that all packets starting with 224.0.0.* will be sent over that interface: $ sudo ip route add 224.0.0.0/24 dev eth0  (replace eth0 with correct network interface name)
- On PC 2: find out the name of the network interface of the ethernet connection to PC 1, for example by running $ ifconfig. The name should be something like eth0 or enp0s31f6
- On PC 2 in any terminal window, add a route which directs that all packets starting with 224.0.0.* will be sent over that interface: $ sudo ip route add 224.0.0.0/24 dev eth0  (replace eth0 with correct network interface name)


* This is a network communication protocol to send and forward networking messages to all listening devices in a network (typically on IP 224.0.0.1), and is used by the multimaster discovery nodes

# Tests
== After step 1 ==
- From PC 1 in any terminal window: $ ping 192.168.2.13
- From PC 1 in any terminal window: $ ping 192.168.0.2
- From PC 2 in any terminal window: $ ping 192.168.2.13
- From PC 2 in any terminal window: $ ping 192.168.0.1
== After step 2 ==
- On PC 1 and PC 2, $ ping 224.0.0.1
- You should receive answers from the IP address of the other PC









