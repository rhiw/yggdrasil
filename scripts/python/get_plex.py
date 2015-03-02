#!/usr/bin/python3.4

import re
import requests
import sys

path = sys.argv[1]

downloads_page = requests.get('https://plex.tv/downloads')
amd64_deb_path = re.search('(https.*amd64\.deb)', downloads_page.text).groups()[0]
amd64_deb = requests.get(amd64_deb_path, stream=True)

with open(path, 'wb') as fd:
    for chunk in amd64_deb.iter_content(1024):
        fd.write(chunk) 
