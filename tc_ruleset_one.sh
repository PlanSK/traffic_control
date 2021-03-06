#!/bin/bash
dst_iface=enp0s8
src_iface=ifb0
SUBNET=10.1.0.0/24

echo "Cleaning root qdisc"
tc qdisc del dev $dst_iface root
tc qdisc del dev $src_iface root
tc qdisc del dev $dst_iface ingress

echo "Set redirect ingress traffic to $src_iface"
tc qdisc add dev $dst_iface ingress
tc filter add dev $dst_iface parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev $src_iface

echo "Set rules on $dst_iface interface" # ingress from wlan
tc qdisc add dev $dst_iface root handle 1:0 htb default 15
tc class add dev $dst_iface parent 1:0 classid 1:1 htb rate 1Gbit ceil 1Gbit

tc class add dev $dst_iface parent 1:1 classid 1:11 htb rate 10Mbit
tc class add dev $dst_iface parent 1:1 classid 1:12 htb rate 120MBit
tc class add dev $dst_iface parent 1:1 classid 1:15 htb rate 1Mbit

tc qdisc add dev $dst_iface parent 1:11 handle 11:0 sfq perturb 10
tc qdisc add dev $dst_iface parent 1:12 handle 12:0 sfq perturb 10
tc qdisc add dev $dst_iface parent 1:15 handle 15:0 sfq perturb 10

echo "Set rules on $src_iface interface" # egress to wlan
tc qdisc add dev $src_iface root handle 1:0 htb default 15
tc class add dev $src_iface parent 1:0 classid 1:1 htb rate 1Gbit ceil 1Gbit

tc class add dev $src_iface parent 1:1 classid 1:11 htb rate 10Mbit
tc class add dev $src_iface parent 1:1 classid 1:12 htb rate 70MBit
tc class add dev $src_iface parent 1:1 classid 1:15 htb rate 1Mbit

tc qdisc add dev $src_iface parent 1:11 handle 11:0 sfq perturb 10
tc qdisc add dev $src_iface parent 1:12 handle 12:0 sfq perturb 10
tc qdisc add dev $src_iface parent 1:15 handle 15:0 sfq perturb 10

echo "Filtering addresses"
tc filter add dev $dst_iface protocol ip parent 1:0 prio 1 u32 match ip dst $SUBNET flowid 1:11
tc filter add dev $src_iface protocol ip parent 1:0 prio 1 u32 match ip src $SUBNET flowid 1:11
