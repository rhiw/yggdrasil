#!/bin/bash

MEDIA_SERVER_S3_PATH=$1

#log outputs from userdata
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#install plex
wget \"http://plex.tv/downloads\" -O - | grep -o \"http.*amd64\\.deb\" | grep -v ros6-binaries | wget -i - -O /home/ubuntu/plex_update.deb
apt-get install avahi-daemon -y
apt-get install avahi-utils -y
dpkg -i /home/ubuntu/plex_update.deb
apt-get -f install -y

#config plex
sed -i 's/\\/>/ disableRemoteSecurity=\"1\" AcceptedEULA=\"1\" FirstRun=\"0\"\\/>/g' /var/lib/plexmediaserver/Library/Application\\ Support/Plex\\ Media\\ Server/Preferences.xml
pkill -9 [pP]lex
service plexmediaserver start

#install awscli
apt-get update
apt-get install python-pip -y
pip install boto
pip install awscli

#mount media volume
#TODO: Make this do LVM stuff with multiple volumes
mkfs -t ext4 /dev/xvdh
mount /dev/xvdh /media

#set up sync from s3 cron
#TODO: Make this work correctly. Make it not start if another instance is running
COMMAND="\"aws s3 sync s3://"
COMMAND+=$MEDIA_SERVER_S3_PATH
COMMAND+=" /media --recursive\""
JOB="* * * * * $COMMAND >> /var/log/media_sync_log"

echo $JOB > /etc/cron.d/media_sync
exit 0
