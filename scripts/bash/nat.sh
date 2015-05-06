#!/bin/bash

# Copyright 2015 Dalton Nikitas
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -x
ETH0_MAC=`/sbin/ifconfig  | /bin/grep eth0 | awk '{print tolower($5)}' | grep '^[0-9a-f]\\{2\\}\\(:[0-9a-f]\\{2\\}\\)\\{5\\}$'`
VPC_CIDR_URI=i\"http://169.254.169.254/latest/meta-data/network/interfaces/macs/${ETH0_MAC}/vpc-ipv4-cidr-block\"
VPC_CIDR_RANGE=`curl --retry 3 --retry-delay 0 --silent --fail ${VPC_CIDR_URI}`

if [ $? -ne 0 ] ; then
   VPC_CIDR_RANGE=0.0.0.0/0
fi

#TODO: Find better way to flip ip_forward bit (sysctl?)
echo 1 > /proc/sys/net/ipv4/ip_forward && echo 0 > /proc/sys/net/ipv4/conf/eth0/send_redirects && /sbin/iptables -t nat -A POSTROUTING -o eth0 -s ${VPC_CIDR_RANGE} -j MASQUERADE
exit 0

