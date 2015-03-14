from boto import config, cloudformation
from boto import s3 as s3_boto
import logging
import os
from os import path
import sys

logger = logging.getLogger('setup_client')

def push_logs_to_std_out(level='INFO'):
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(getattr(logging, level))
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    root.addHandler(ch)    

def confirm_aws_creds():
    logger.debug("Confirming AWS creds in some section in boto.config")
    akid = False
    skid = False
    for section in config.sections():
        akid = akid or config.has_option(section, 'aws_access_key_id')
        askid = skid or config.has_option(section, 'aws_secret_access_key')
    if not akid and skid:
        raise RuntimeError("No aws creds recognized by boto.")

    logger.debug("AWS creds present")

def confirm_path(destination_path):
    logger.debug("Confirming write permissions to {}".format(destination_path))
    if not os.access(destination_path, os.W_OK):
        raise RuntimeError("You do not have write permissions to {}. Consider chmoding it or running as root".format(destination_path))
    
    if not path.isdir(destination_path):
        logger.debug("{} does not exist, creating".format(destination_path))
        os.makedirs(destination_path)
    
    logger.debug("{} exists and we have write permissions.".format(destination_path))

class Lazy(object):
    def __init__(self, func):
        self.func = func
        self.func_name = func.__name__

    def __get__(self, obj, cls=None):
        logger.debug("Evaluating {}".format(self.func_name))
        val = self.func(obj)
        setattr(obj, self.func_name, val)
        return val

class AWS(object):
    def __init__(self, region='us-east-1', akid=None, skid=None):
        logger.debug("Creating connection to AWS in region {0} with access key {1}".format(region, akid))

        if not (akid and skid):
            confirm_aws_creds()

        self.region = region
        self.akid = akid
        self.skid = skid

    @Lazy
    def cf(self):
        return cloudformation.connect_to_region(self.region, aws_access_key_id=self.akid, aws_secret_access_key=self.skid)

    @Lazy
    def s3(self):
        return s3_boto.connect_to_region(self.region, aws_access_key_id=self.akid, aws_secret_access_key=self.skid)

    def get_stacks(self):
        logger.debug("Getting extant stacks from CloudFormation")
        stacks = []
        return self.cf.list_stacks(['CREATE_IN_PROGRESS',
                                    'CREATE_FAILED',
                                    'CREATE_COMPLETE',
                                    'ROLLBACK_IN_PROGRESS',
                                    'ROLLBACK_FAILED',
                                    'ROLLBACK_COMPLETE',
                                    'DELETE_IN_PROGRESS',
                                    'DELETE_FAILED',
                                    'UPDATE_IN_PROGRESS',
                                    'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS',
                                    'UPDATE_COMPLETE',
                                    'UPDATE_ROLLBACK_IN_PROGRESS',
                                    'UPDATE_ROLLBACK_FAILED',
                                    'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS',
                                    'UPDATE_ROLLBACK_COMPLETE'])
