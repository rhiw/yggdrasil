#!/usr/bin/python3.4

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

from general_utils import set_up_stdout_logging
import logging
import optparse
import re
import requests
import sys

logger = logging.getLogger('get_plex')

def parse_args():
    parser = optparse.OptionParser()
    parser.add_option('-p', '--path', desc='The path to the file to which the Plex .deb should be written')

    return parser.parse_args()

def main():
    options, args = parse_args()

    plex_download_path = 'https://plex.tv/downloads'
    logger.info("Getting Plex downloads page {0}".format(plex_download_path))
    downloads_page = requests.get(plex_download_path)

    logger.info("Finding path to 64-bit deb packaged linked from plex downloads")
    amd64_deb_path = re.search('(https.*amd64\.deb)', downloads_page.text).groups()[0]
    
    logger.info("Getting deb from {0} to file {1}".format(amd64_deb_path, options.path))
    amd64_deb = requests.get(amd64_deb_path, stream=True)

    with open(options.path, 'wb') as fd:
        for chunk in amd64_deb.iter_content(1024):
            fd.write(chunk)

if __name__ == '__main__':
    set_up_stdout_logging()
    main()
 
