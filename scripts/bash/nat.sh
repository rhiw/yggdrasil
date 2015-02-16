#!/bin/bash

set -x
ETH0_MAC=`/sbin/ifconfig  | /bin/grep eth0 | awk '{print tolower($5)}' | grep '^[0-9a-f]\\{2\\}\\(:[0-9a-f]\\{2\\}\\)\\{5\\}$'`
VPC_CIDR_URI=i\"http://169.254.169.254/latest/meta-data/network/interfaces/macs/${ETH0_MAC}/vpc-ipv4-cidr-block\"
VPC_CIDR_RANGE=`curl --retry 3 --retry-delay 0 --silent --fail ${VPC_CIDR_URI}`

if [ $? -ne 0 ] ; then
   VPC_CIDR_RANGE=0.0.0.0
fi

#TODO: Find better way to flip ip_forward bit (sysctl?)
echo 1 > /proc/sys/net/ipv4/ip_forward && echo 0 > /proc/sys/net/ipv4/conf/eth0/send_redirects && /sbin/iptables -t nat -A POSTROUTING -o eth0 -s ${VPC_CIDR_RANGE} -j MASQUERADE
exit 0

