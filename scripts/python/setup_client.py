from aws import AWS
from contextlib import contextmanager
import logging
import os
from os import path
import shutil
import sys
import tarfile
import tempfile
import subprocess

logger = logging.getLogger('setup_client')

@contextmanager
def TempDir():
    td = tempfile.mkdtemp()
    yield td
    shutil.rmtree(td)

def ghetto_tar(tf):
    #I can't get shutil or tarfile to work right now. Might be borked installation of python
    subprocess.check_call(['tar', '-xf', tf])

def get_client_materials_from_s3(s3_path, region='us-east-1', akid=None, skid=None):
    logger.debug("Getting client materials from S3")
    if s3_path.startswith('s3://'):
        s3_path = s3_path[5:]
    path_split = s3_path.split('/')
    bucket_name = path_split[0]
    
    aws = AWS(region, akid, skid)
    bucket = aws.s3.get_bucket(bucket_name)
    key = bucket.get_key('/'.join(path_split[1:]))    

    with TempDir() as temp_dir:
        temp_file_name = path.join(temp_dir, 'client_materials.tgz')
        with open(temp_file_name, 'w+') as temp_file:
            key.get_contents_to_file(temp_file)
            #tf = tarfile.open(temp_file.name)
            #tf.extractall(temp_dir)
            ghetto_tar(temp_file_name)
            print os.listdir(temp_dir) 

def get_openvpn_path(path=None):
    logger.debug("Getting openvpn path based on preference and platform standards")
    if path is None:
        if sys.platform.startswith('linux'):
            path = '/etc/openvpn'
        elif sys.platform.startswith('win'):
            path = 'C:\Program Files\OpenVPN\config'
        elif sys.platform.startswith('darwin'):
            path = path.expanduser('~/Library/Application Support/Tunnelblick/Configurations')
        else:
            raise RuntimeError("Platform {} not recognized. You're not on Linux, Windows, or Mac? Really?".format(sys.platform))

    logger.debug("OpenVPN path: {}".format(path))
    return confirm_path(path)

def push_logs_to_std_out(level='INFO'):
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(getattr(logging, level))
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    root.addHandler(ch)    

def confirm_path(destination_path):
    logger.debug("Confirming write permissions to {}".format(destination_path))
    if not os.access(destination_path, os.W_OK):
        raise RuntimeError("You do not have write permissions to {}. Consider chmoding it or running as root".format(destination_path))
    
    if not path.isdir(destination_path):
        logger.debug("{} does not exist, creating".format(destination_path))
        os.makedirs(destination_path)
    
    logger.debug("{} exists and we have write permissions.".format(destination_path))
    return destination_path

