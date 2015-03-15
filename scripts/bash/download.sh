#!/bin/bash

DOWNLOAD_SERVER_S3_PATH=$1

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
apt-get install lvm2 -y
vgcreate download_group /dev/xvdh
lvcreate --name logical_download -l 100%VG download_group
mkfs -t ext4 /dev/download_group/download_media
mount /dev/download_group/download_media /download
echo "Stop doing lvm stuff"

#set volume resizer cron
COMMAND='source /home/ubuntu/.bashrc && workon py34 && python /home/ubuntu/yggdrasil-master/scripts/python/volume_resizer.py /media .8'
JOB="*/5 * * * * root $COMMAND 2>&1 | /usr/bin/logger -t media_volume_resizer"

cat << EOF > /etc/cron.d/volume_resizer
$JOB

EOF

exit 0
