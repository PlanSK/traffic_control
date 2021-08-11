#!/bin/bash
WAN=enp0s8
LAN=ifb0


echo "Cleaning root qdisc"
tc qdisc del dev $WAN root
tc qdisc del dev $LAN root
tc qdisc del dev $WAN ingress

echo "Set redirect ingress traffic to $LAN"
tc qdisc add dev $WAN ingress
tc filter add dev $WAN parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev $LAN

echo "Set SFQ rules on $WAN interface"
tc qdisc add dev $WAN root sfq perturb 10
tc qdisc add dev $LAN root sfq perturb 10
