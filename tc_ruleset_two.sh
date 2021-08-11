#!/bin/bash
dst_iface=enp0s8
src_iface=ifb0
SUBNET1=10.1.0.0/24
SUBNET2=10.2.0.0/24

echo "Starting $src_iface interface"
modprobe ifb
ip link set dev $src_iface up

echo "Cleaning root qdisc"
tc qdisc del dev $dst_iface root
tc qdisc del dev $src_iface root
tc qdisc del dev $dst_iface ingress

echo "Set redirect ingress traffic to $src_iface"
tc qdisc add dev $dst_iface ingress
tc filter add dev $dst_iface parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev $src_iface

echo "Set rules on $dst_iface interface" # from wlan ingress
tc qdisc add dev $dst_iface root handle 1:0 htb default 15
tc class add dev $dst_iface parent 1:0 classid 1:1 htb rate 1Gbit ceil 1Gbit
tc class add dev $dst_iface parent 1:1 classid 1:11 htb rate 5Mbit
tc class add dev $dst_iface parent 1:1 classid 1:12 htb rate 100MBit
tc class add dev $dst_iface parent 1:1 classid 1:15 htb rate 30Mbit
tc qdisc add dev $dst_iface parent 1:11 handle 11:0 sfq perturb 10
tc qdisc add dev $dst_iface parent 1:12 handle 12:0 sfq perturb 10
tc qdisc add dev $dst_iface parent 1:15 handle 15:0 sfq perturb 10

echo "Set rules on $src_iface interface" # to wlan egress
tc qdisc add dev $src_iface root handle 1:0 htb default 15
tc class add dev $src_iface parent 1:0 classid 1:1 htb rate 1Gbit ceil 1Gbit
tc class add dev $src_iface parent 1:1 classid 1:11 htb rate 100Mbit
tc class add dev $src_iface parent 1:1 classid 1:12 htb rate 100MBit
tc class add dev $src_iface parent 1:1 classid 1:15 htb rate 5Mbit
tc qdisc add dev $src_iface parent 1:11 handle 11:0 sfq perturb 10
tc qdisc add dev $src_iface parent 1:12 handle 12:0 sfq perturb 10
tc qdisc add dev $src_iface parent 1:15 handle 15:0 sfq perturb 10

echo "Filtering addresses"
tc filter add dev $dst_iface protocol ip parent 1:0 prio 1 u32 match ip dst $SUBNET1 flowid 1:11
tc filter add dev $dst_iface protocol ip parent 1:0 prio 1 u32 match ip dst $SUBNET2 flowid 1:12

tc filter add dev $src_iface protocol ip parent 1:0 prio 1 u32 match ip src $SUBNET1 flowid 1:11
tc filter add dev $src_iface protocol ip parent 1:0 prio 1 u32 match ip src $SUBNET2 flowid 1:12
