#!/bin/bash

set -x

VPN_SERVER_CERTS_S3_PREFIX=$1
VPN_SERVER_CONFIG_S3_PATH=$2
DESTINATION_S3_PREFIX=$3

#I don't know if this NAT stuff is necessary on VPN server, but it seems like it might be and definitely works
eval ./nat.sh

#Get EasyRSA 
mkdir /etc/openvpn/easy-rsa
mkdir /etc/openvpn/easy-rsa/keys
wget https://github.com/OpenVPN/easy-rsa/releases/download/2.2.2/EasyRSA-2.2.2.tgz
tar -xvf EasyRSA-2.2.2.tgz
cp -r EasyRSA-2.2.2/* /etc/openvpn/easy-rsa/

#Set up certs and keys
if [ $VPN_SERVER_CERTS_S3_PREFIX = None ]
    then
        eval ./vpn_generate_certs.sh $DESTINATION_S3_PREFIX
    else
        eval "aws s3 cp s3://"$VPN_SERVER_CERTS_S3_PREFIX" /etc/openvpn/easy-rsa/keys --recursive"
fi

#Set up config
if [ $VPN_SERVER_CONFIG_S3_PATH = None ]
    then
        cp /home/ec2-user/yggdrasil-master/templates/server.conf /etc/openvpn/server.conf
    else
        eval "aws s3 cp s3://"$VPN_SERVER_CONFIG_S3_PATH" /etc/openvpn"
fi

service openvpn start
exit 0


