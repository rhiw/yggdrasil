#!/usr/bin/python3.4

from aws import AWS
from aws_utils import create_volume
from boto import ec2, utils
from general_utils import set_up_stdout_logging, subprocess_check_retries
import logging
import optparse
import shutil
import subprocess
from time import sleep

logger = logging.getLogger('volume_resizer')

def parse_args():
    parser = optparse.OptionParser()
    parser.add_option('-m', '--mount_point', help='The mount point for the volume to be actively resized')
    parser.add_option('-r', '--ratio', help='The ratio of disk usage at which to add another volume. DEFAULT: .8', default=.8, type='float')
    parser.add_option('-i', '--increment', help='The size of the volume to add when the ratio is exceeded (GB). DEFAULT: 1024', default=1024, type='int')
    parser.add_option('-g', '--logical_group', help='The logical group (LVM) to which the new volume should be added. DEFAULT: media_group')
    parser.add_option('-d', '--logical_device', help='The logical device (LVM) to which the new volume should be added. DEFAULT: logical_media')

    return parser.parse_args()

def main():
    options, args = parse_args()

    if get_usage_ratio(options.mount_point) < options.ratio:
        logger.info("{0} usage ratio is less than {1}. Quitting".format(options.mount_point, options.ratio))
        return

    logger.info("Proceeding with extending media volume")

    aws = AWS()
    instance_info = utils.get_instance_identity()['document']

    volume_id = create_volume(aws.ec2, options.increment, instance_info['availabilityZone'])
    new_device_name = '/dev/' + increment_partition_name(get_sorted_partitions()[-1])
    aws.ec2.attach_volume(volume_id, instance_info['instanceId'], new_device_name)
    extend_lvm(new_device_name, options.logical_group, options.logical_device)

def extend_lvm(new_device, logical_group='media_group', logical_device='logical_media'):
    '''
    This requires that lvm be installed (sudo apt-get install lvm)
    '''
    logger.info("Adding device {0} to logical group {1}".format(new_device, logical_group))
    args = ['vgextend', logical_group, new_device]
    subprocess_check_retries(args)

    full_logical_name = '/'.join(['/dev', logical_group, logical_device])
    logger.info("Resizing {0} to use entire volume group".format(full_logical_name))
    args = ['lvextend', '-l', '100%VG', full_logical_name]
    subprocess_check_retries(args)

    logger.info("Resizing file system on {0} to use whole logical volume".format(full_logical_name))
    args = ['resize2fs', full_logical_name]
    subprocess_check_retries(args)   

def increment_partition_name(name):
    logger.info("Incrementing name of partition " + name)
    if name[-1] == 'z':
        raise RuntimeError('Out of names for partitions with current naming scheme')
    new_name = name[:-1] + chr(ord(name[-1]) + 1)
    logger.info('Next partition name: ' + new_name)
    return new_name

def get_sorted_partitions():
    parts = []
    logger.info('Getting partitions from /proc/partitions')
    with open('/proc/partitions', 'r') as fp:
        parts.extend([l.split()[3] for l in fp.readlines() if len(l.split()) == 4 and l.split()[3].lower() != 'name'])

    return sorted(parts)

def get_usage_ratio(mount):
    logger.info("Getting usage ratio for mount mounted at " + mount)
    usage = shutil.disk_usage(mount)
    ratio = usage.used/usage.total
    logger.info("Usage ratio: %f", ratio)
    return ratio

if __name__ == '__main__':
    set_up_stdout_logging()
    main()

