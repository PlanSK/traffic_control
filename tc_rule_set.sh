#!/bin/bash
WAN=enp0s8
LAN=ifb0

echo "Starting $LAN interface"
modprobe ifb
ip link set dev $LAN up

echo "Cleaning root qdisc"
tc qdisc del dev $WAN root
tc qdisc del dev $LAN root
tc qdisc del dev $WAN ingress

echo "Set redirect ingress traffic to $LAN"
tc qdisc add dev $WAN ingress
tc filter add dev $WAN parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev $LAN

echo "Set rules on $WAN interface" # from wlan ingress
tc qdisc add dev $WAN root handle 1:0 htb default 15
tc class add dev $WAN parent 1:0 classid 1:1 htb rate 1Gbit ceil 1Gbit
tc class add dev $WAN parent 1:1 classid 1:11 htb rate 5Mbit
tc class add dev $WAN parent 1:1 classid 1:12 htb rate 100MBit
tc class add dev $WAN parent 1:1 classid 1:15 htb rate 30Mbit
tc qdisc add dev $WAN parent 1:11 handle 11:0 sfq perturb 10
tc qdisc add dev $WAN parent 1:12 handle 12:0 sfq perturb 10
tc qdisc add dev $WAN parent 1:15 handle 15:0 sfq perturb 10

echo "Set rules on $LAN interface" # to wlan egress
tc qdisc add dev $LAN root handle 1:0 htb default 15
tc class add dev $LAN parent 1:0 classid 1:1 htb rate 1Gbit ceil 1Gbit
tc class add dev $LAN parent 1:1 classid 1:11 htb rate 100Mbit
tc class add dev $LAN parent 1:1 classid 1:12 htb rate 100MBit
tc class add dev $LAN parent 1:1 classid 1:15 htb rate 5Mbit
tc qdisc add dev $LAN parent 1:11 handle 11:0 sfq perturb 10
tc qdisc add dev $LAN parent 1:12 handle 12:0 sfq perturb 10
tc qdisc add dev $LAN parent 1:15 handle 15:0 sfq perturb 10

echo "Filtering addresses"
tc filter add dev $WAN protocol ip parent 1:0 prio 1 u32 match ip dst 10.1.0.0/24 flowid 1:11
tc filter add dev $WAN protocol ip parent 1:0 prio 1 u32 match ip dst 10.2.0.0/24 flowid 1:12

tc filter add dev $LAN protocol ip parent 1:0 prio 1 u32 match ip src 10.1.0.0/24 flowid 1:11
tc filter add dev $LAN protocol ip parent 1:0 prio 1 u32 match ip src 10.2.0.0/24 flowid 1:12
