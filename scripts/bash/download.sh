#!/bin/bash

MEDIA_S3_PATH=$1
BLOCKLIST=$2

#log outputs from userdata
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

#Python stuff
apt-get update
apt-get install python-pip -y
pip install awscli
pip install virtualenv
pip install virtualenvwrapper

cat << EOF >> /home/ubuntu/.bashrc
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
source /usr/local/bin/virtualenvwrapper.sh
EOF

source /home/ubuntu/.bashrc
source /usr/local/bin/virtualenvwrapper.sh

mkvirtualenv -p /usr/bin/python2.7 py27
mkvirtualenv -p /usr/bin/python3.4 py34
workon py27
pip install ipython
pip install boto
workon py34
pip install ipython
pip install boto
pip install requests

#Set up LVM
echo "Start doing lvm stuff"
mkdir /download
apt-get install lvm2 -y
vgcreate download_group /dev/xvdh
lvcreate --name logical_download -l 100%VG download_group
mkfs -t ext4 /dev/download_group/logical_download
mount /dev/download_group/logical_download /download
echo "Stop doing lvm stuff"

#Install transmission
apt-get install transmission-daemon
mkdir /download/complete
mkdir /download/incomplete
chmod 0777 -R /download

#Write media path to file
echo {\"s3_path\": \"$MEDIA_S3_PATH\"} > /home/ubuntu/yggdrasil-master/data 
chmod 0666 /home/ubuntu/yggdrasil-master/data

#Update transmission settings
apt-get install jq
jq '. + {"blocklist-enabled":true,
         "blocklist-url":"http://list.iblocklist.com/?list=bt_level1&fileformat=p2p&archiveformat=gz",
         "download_dir":"/download/incomplete/",
         "ratio-limit": 1,
         "ratio-limit-enabled": true,
         "rpc-authentication-required":false,
         "rpc-enabled":true,
         "rpc-whitelist": "172.16.*.*,172.17.*.*",
         "rpc-whitelist-enabled": true,
         "script-torrent-done-enabled": true,
         "script-torrent-done-filename": "/home/ubuntu/yggdrasil-master/scripts/bash/upload_to_s3.sh"}' /etc/transmission-daemon/settings.json > /etc/transmission-daemon/settings.json

#set volume resizer cron
COMMAND='source /home/ubuntu/.bashrc && workon py34 && python /home/ubuntu/yggdrasil-master/scripts/python/volume_resizer.py /media .8'
JOB="*/5 * * * * root $COMMAND 2>&1 | /usr/bin/logger -t media_volume_resizer"

cat << EOF > /etc/cron.d/volume_resizer
$JOB

EOF

exit 0
