#!/bin/bash
dst_iface=enp0s8 # to client
src_iface=ifb0 # from client


echo "Cleaning root qdisc"
tc qdisc del dev $dst_iface root
tc qdisc del dev $src_iface root
tc qdisc del dev $dst_iface ingress

echo "Set redirect ingress traffic to $LAN"
tc qdisc add dev $dst_iface ingress
tc filter add dev $dst_iface parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev $src_iface

echo "Set SFQ rules on $WAN interface"
tc qdisc add dev $dst_iface root sfq perturb 10
tc qdisc add dev $src_iface root sfq perturb 10
