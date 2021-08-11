#!/bin/bash
WAN=enp0s8
LAN=ifb0


echo "Cleaning root qdisc"
tc qdisc del dev $WAN root
tc qdisc del dev $LAN root
tc qdisc del dev $WAN ingress
