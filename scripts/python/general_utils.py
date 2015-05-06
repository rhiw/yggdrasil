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
from sys import stdout

logger = logging.getLogger('general_utils')

def set_up_stdout_logging():
    logger.setLevel(logging.INFO)
    ch = logging.StreamHandler(stdout)
    ch.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

def subprocess_check_retries(args, max_time=600):
    sleep_time = 1
    logger.debug("Running command {0!s}.".format(args))
    while sleep_time < max_time:
        try:
            subprocess.check_call(args)
        except subprocess.CalledProcessError:
            logger.error("Subprocess call with args {0} failed. Sleeping {1}".format(str(args), str(sleep_time)))
            sleep(sleep_time)
            sleep_time *= 2
        else:
            break


