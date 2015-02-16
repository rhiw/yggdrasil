#!/bin/bash

set -x

VPN_SERVER_CERTS_S3_PREFIX=$1
VPN_SERVER_CONFIG_S3_PATH=$2

#I don't know if this NAT stuff is necessary on VPN server
ETH0_MAC=`/sbin/ifconfig  | /bin/grep eth0 | awk '{print tolower($5)}' | grep '^[0-9a-f]\\{2\\}\\(:[0-9a-f]\\{2\\}\\)\\{5\\}$'`
VPC_CIDR_URI=i\"http://169.254.169.254/latest/meta-data/network/interfaces/macs/${ETH0_MAC}/vpc-ipv4-cidr-block\"
VPC_CIDR_RANGE=`curl --retry 3 --retry-delay 0 --silent --fail ${VPC_CIDR_URI}`
if [ $? -ne 0 ] ; then
   VPC_CIDR_RANGE=\"0.0.0.0/0\"
fi
#TODO: Better way to flip ip_forward bit (sysctl?)
echo 1 > /proc/sys/net/ipv4/ip_forward && echo 0 > /proc/sys/net/ipv4/conf/eth0/send_redirects && /sbin/iptables -t nat -A POSTROUTING -o eth0 -s ${VPC_CIDR_RANGE} -j MASQUERADE

mkdir /etc/openvpn/easy-rsa
mkdir /etc/openvpn/easy-rsa/keys
wget https://github.com/OpenVPN/easy-rsa/releases/download/2.2.2/EasyRSA-2.2.2.tgz
tar -xvf EasyRSA-2.2.2.tgz
sudo cp -r EasyRSA-2.2.2/* /etc/openvpn/easy-rsa/

cd /etc/openvpn/easy-rsa
CERTS_CMD="aws s3 cp s3://"
CERTS_CMD+=VPN_SERVER_CERTS_S3_PREFIX
CERTS_CMD+=" /etc/openvpn/easy-rsa/keys --recursive"

CONFIG_CMD="aws s3 cp s3://"
CERTS_CMD+=VPN_SERVER_CONFIG_S3_PATH
CERTS_CMD+=" /etc/openvpn/"

service openvpn start
exit 0

