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

