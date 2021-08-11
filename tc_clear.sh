#!/bin/bash
dst_iface=enp0s8
src_iface=ifb0


echo "Cleaning root qdisc"
tc qdisc del dev $dst_iface root
tc qdisc del dev $src_iface root
tc qdisc del dev $dst_iface ingress
