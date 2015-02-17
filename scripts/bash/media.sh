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
apt-get install python3-pip -y
pip3 install boto
pip install awscli

#Set up LVM
apt-get install lvm2 -y
vgcreate media_group /dev/xvdh
lvcreate --name logical_media -l 100%VG media_group
mkfs -t ext4 /dev/media_group/logical_media
mount /dev/media_group/logical_media /media

#set up sync from s3 cron
#TODO: Make this work correctly. Make it not start if another instance is running
COMMAND="\"aws s3 sync s3://"
COMMAND+=$MEDIA_SERVER_S3_PATH
COMMAND+=" /media --recursive\""
JOB="* * * * * $COMMAND >> /var/log/media_sync_log"

echo $JOB > /etc/cron.d/media_sync

#The next line should make it so that a sync doesn't start while another is in progress. I don't think it works; testing needed.
#cat <(fgrep -i -v \"$command\" <(crontab -l)) <(echo \"$job\") | crontab -

exit 0
