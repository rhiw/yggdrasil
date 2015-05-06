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

VPN_SERVER_CERTS_S3_PREFIX=$1
VPN_SERVER_CONFIG_S3_PATH=$2
DESTINATION_S3_PREFIX=$3

#I haven't verified that this NAT stuff is necessary on VPN server, but it seems like it might be and definitely works
/home/ec2-user/yggdrasil-master/scripts/bash/nat.sh

#Get EasyRSA 
mkdir /etc/openvpn/easy-rsa
mkdir /etc/openvpn/easy-rsa/keys
wget https://github.com/OpenVPN/easy-rsa/releases/download/2.2.2/EasyRSA-2.2.2.tgz
tar -xvf EasyRSA-2.2.2.tgz
cp -r EasyRSA-2.2.2/* /etc/openvpn/easy-rsa/

#Set up certs and keys
if [ $VPN_SERVER_CERTS_S3_PREFIX = None ]
    then
        /home/ec2-user/yggdrasil-master/scripts/bash/vpn_generate_certs.sh $DESTINATION_S3_PREFIX
    else
        aws s3 cp s3://$VPN_SERVER_CERTS_S3_PREFIX /etc/openvpn/easy-rsa/keys --recursive
fi

#Set up config
if [ $VPN_SERVER_CONFIG_S3_PATH = None ]
    then
        cp /home/ec2-user/yggdrasil-master/templates/server.conf /etc/openvpn/server.conf
    else
        aws s3 cp s3://$VPN_SERVER_CONFIG_S3_PATH /etc/openvpn
fi

service openvpn start
exit 0

