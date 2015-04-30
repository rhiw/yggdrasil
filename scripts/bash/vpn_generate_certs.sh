#!/bin/bash

DESTINATION_S3_PREFIX=$1

#Set up pki stuff
cd /etc/openvpn/easy-rsa
. ./vars
./clean-all
./build-dh
./pkitool --initca
./pkitool --server server
./pkitool client0

cd /home/ec2-user

#Create pem of ec2 public key
ssh-keygen -f /home/ec2-user/.ssh/authorized_keys -e -m PKCS8 > /home/ec2-user/ec2-public-key.pem

#Encrypt and tar VPN materials
mkdir client_materials

#The tarball we generate is too big for asymmetric encryption, so we generate a symmetric shared key and use our asymmetric key to encrypt it
openssl rand 256 -out vpn_secret

openssl enc -e -in /etc/openvpn/easy-rsa/keys/ca.crt -out client_materials/ca.crt.encrypted -aes256 -k vpn_secret
openssl enc -e -in /etc/openvpn/easy-rsa/keys/client0.crt -out client_materials/client0.crt.encrypted -aes256 -k vpn_secret
openssl enc -e -in /etc/openvpn/easy-rsa/keys/client0.key -out client_materials/client0.key.encrypted -aes256 -k vpn_secret
openssl rsautl -encrypt -pubin -inkey ec2-public-key.pem -ssl -in vpn_secret -out client_materials/vpn_secret.encrypted
tar -czf client_materials.tgz client_materials/

#Put to S3
aws s3 cp client_materials.tgz s3://$DESTINATION_S3_PREFIX/client_materials.tgz

