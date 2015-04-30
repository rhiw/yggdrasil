from boto import cloudformation as cf_boto
from boto import dynamodb2 as ddb_boto
from boto import ec2 as ec2_boto
from boto import config
from boto import s3 as s3_boto
from boto import vpc as vpc_boto
import logging

logger = logging.getLogger('aws')

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

    def _connect(self, boto_module):
        # The boto modules are consistent in that they all have connect_to_region
        logger.debug("Connection module {0}".format(boto_module))
        return boto_module.connect_to_region(self.region, aws_access_key_id=self.akid, aws_secret_access_key=self.skid)

    @Lazy
    def cf(self):
        return self._connect(cf_boto)

    @Lazy
    def ddb(self):
        return self._connect(ddb_boto)

    @Lazy
    def ec2(self):
        return self._connect(ec2_boto)

    @Lazy
    def s3(self):
        return self._connect(s3_boto)

    @Lazy
    def vpc(self):
        return self._connect(vpc_boto)

