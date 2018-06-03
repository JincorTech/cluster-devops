#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import re
import json
import lib.stacks as ls

if __name__ != "__main__":
    print('ERROR: Should be using only in direct CLI mode')
    sys.exit(1)

if len(sys.argv) != 2:
    print('usage: script {-,json_request_file}')
    sys.exit(0)

def deploy(req):
    return ls.get_stack(req['name'], req['stack'], req['context'], req['links']).deploy()

content = {}
if sys.argv[1] == '-':
    content = json.loads(''.join(sys.stdin.readlines()))
else:
    content = json.loads(file(sys.argv[1]).read())

deploy(content)
