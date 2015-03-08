#!/bin/bash

S3_OBJECT=$1
DESTINATION_DIR=$2
EC2_PRIVATE_KEY=$3

#Create destination dir(s)
mkdir -p $DESTINATION_DIR

#Pull tarball from S3
aws s3 cp s3://$S3_OBJECT .
tar -xvf client_materials.tgz

#Decrypt and place contents
openssl rsautl -decrypt -inkey $EC2_PRIVATE_KEY -in client_materials/vpn_secret.encrypted -out client_materials/vpn_secret
openssl enc -d -out $DESTINATION_DIR/ca.crt -in client_materials/ca.crt.encrypted -aes256 -k vpn_secret
openssl enc -d -out $DESTINATION_DIR/client0.crt -in client_materials/client0.crt.encrypted -aes256 -k vpn_secret
openssl enc -d -out $DESTINATION_DIR/client0.key -in client_materials/client0.key.encrypted -aes256 -k vpn_secret

#Cleanup
rm -rf client_materials

