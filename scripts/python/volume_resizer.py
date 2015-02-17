#!/usr/bin/python3.4

from boto import ec2, utils
import logging
import shutil
import subprocess
from sys import argv, stdout
from time import sleep

logger = logging.getLogger('volume_resizer')

instance_info = utils.get_instance_identity()['document']
ec2_conn = ec2.connect_to_region(instance_info['region'])

def main():
    mount_point = argv[1]
    ratio = argv[2]

    if get_usage_ratio(mount_point) < float(ratio):
        logger.info("{0} usage ratio is less than {1}. Quitting".format(mount_point, ratio))
        return

    logger.info("Proceeding with extending media volume")

    volume_id = create_new_volume()
    new_device_name = '/dev/' + increment_partition_name(get_sorted_partitions()[-1])
    attach_volume(volume_id, new_device_name)
    extend_lvm(new_device_name)

def check_retries(args, max_time=600):
    sleep_time = 1
    while sleep_time < max_time:
        try:
            subprocess.check_call(args)
        except subprocess.CalledProcessError:
            logger.error("Subprocess call with args {0} failed. Sleeping {1}".format(str(args), str(sleep_time)))
            sleep(sleep_time)
            sleep_time *= 2
        else:
            break

def extend_lvm(new_device, logical_group='media_group', logical_device='logical_media'):
    '''
    This requires that lvm be installed (sudo apt-get install lvm)
    '''
    logger.info("Adding device {0} to logical group {1}".format(new_device, logical_group))
    args = ['vgextend', logical_group, new_device]
    check_retries(args)

    full_logical_name = '/'.join(['/dev', logical_group, logical_device])
    logger.info("Resizing {0} to use entire volume group".format(full_logical_name))
    args = ['lvextend', '-l', '100%VG', full_logical_name]
    check_retries(args)

    logger.info("Resizing file system on {0} to use whole logical volume".format(full_logical_name))
    args = ['resize2fs', full_logical_name]
    check_retries(args)   

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

def attach_volume(volume, device_name, instance=instance_info['instanceId']):
    logger.info("Attaching volume " + volume)
    ec2_conn.attach_volume(volume, instance, device_name)

def create_new_volume(size=1024, az=instance_info['availabilityZone'], volume_type='io1', iops=3000, timeout=600, retry=10):
    logger.info("Creating new volume of size {0} az {1} type {2} iops {3}".format(size, az, volume_type, iops))
    volume = ec2_conn.create_volume(size, az, volume_type=volume_type, iops=iops)
    logger.info("New volume: {0}".format(str(volume)))
    
    slept_time=0
    while volume.update() != 'available':
        logger.debug("Waiting for new volume to become available. Sleeping " + str(retry))
        sleep(retry)
        slept_time += retry
        if slept_time > timeout:
            raise RuntimeError('Instance did not become available')

    return volume.id

def get_usage_ratio(mount):
    logger.info("Getting usage ratio for mount mounted at " + mount)
    usage = shutil.disk_usage(mount)
    ratio = usage.used/usage.total
    logger.info("Usage ratio: %f", ratio)
    return ratio

def set_up_stdout_logging():
    logger.setLevel(logging.INFO)
    ch = logging.StreamHandler(stdout)
    ch.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

if __name__ == '__main__':
    set_up_stdout_logging()
    main()


