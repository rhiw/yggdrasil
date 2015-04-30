#!/bin/bash

MEDIA_SERVER_S3_PATH=$1

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

#install plex
python /home/ubuntu/yggdrasil-master/scripts/python/get_plex.py -p /home/ubuntu/plex_update.deb
apt-get install avahi-daemon -y
apt-get install avahi-utils -y
dpkg -i /home/ubuntu/plex_update.deb
apt-get -f install -y

#config plex
sed -i 's/\/>/ disableRemoteSecurity=\"1\" AcceptedEULA=\"1\" FirstRun=\"0\"\/>/g' '/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Preferences.xml'
pkill -9 [pP]lex
service plexmediaserver start

#Set up LVM
echo "Start doing lvm stuff"
apt-get install lvm2 -y
vgcreate media_group /dev/xvdh
lvcreate --name logical_media -l 100%VG media_group
mkfs -t ext4 /dev/media_group/logical_media
mount /dev/media_group/logical_media /media
echo "Stop doing lvm stuff"

#set up sync from s3 cron
COMMAND='(if /home/ubuntu/yggdrasil-master/scripts/python/s3_sync_not_running ; then echo "running s3 sync" && /usr/local/bin/aws s3 sync s3://'
COMMAND+=$MEDIA_SERVER_S3_PATH
COMMAND+=' /media --only-show-errors ; else echo "s3 sync already running" ; fi)'
JOB="* * * * * root $COMMAND 2>&1 | /usr/bin/logger -t s3_sync"

cat << EOF > /etc/cron.d/media_sync
$JOB

EOF

#set media resizer cron
COMMAND='source /home/ubuntu/.bashrc && workon py34 && python /home/ubuntu/yggdrasil-master/scripts/python/volume_resizer.py -m /media -r .8'
JOB="*/5 * * * * root $COMMAND 2>&1 | /usr/bin/logger -t media_volume_resizer"

cat << EOF > /etc/cron.d/volume_resizer
$JOB

EOF

exit 0
