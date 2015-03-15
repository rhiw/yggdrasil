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

