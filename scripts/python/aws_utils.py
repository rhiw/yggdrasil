# Copyright 2015 Dalton Nikitas
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import logging

logger = logging.getLogger('aws_utils')

def create_volume(ec2_boto, size, az, volume_type='io1', iops=4000, timeout=600, retry=10):
    logger.info("Creating new volume of size {0} az {1} type {2} iops {3}".format(size, az, volume_type, iops))
    volume = ec2_boto.create_volume(size, az, volume_type=volume_type, iops=iops)
    logger.info("New volume: {0}".format(str(volume)))

    slept_time=0
    while volume.update() != 'available':
        logger.debug("Waiting for new volume to become available. Sleeping " + str(retry))
        sleep(retry)
        slept_time += retry
        if slept_time > timeout:
            raise RuntimeError('Volume did not become available')

    return volume.id

def get_stacks(cf_boto):
    logger.debug("Getting extant stacks from CloudFormation")
    stacks = []
    marker = None
    while True:
        response = cf_boto.list_stacks(['CREATE_IN_PROGRESS',
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
                                        'UPDATE_ROLLBACK_COMPLETE'], marker)
        stacks.extend(response)
        marker = response.marker

        if marker is None:
            break

    return stacks
