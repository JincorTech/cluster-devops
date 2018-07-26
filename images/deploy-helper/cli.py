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

if len(sys.argv) != 3:
    print('usage: script {deploy|update} {-,json_request_file}')
    sys.exit(0)

def deploy(name, req):
    return ls.get_stack(name, req['stack'], req['context'], req['links']).deploy()

def update(name, req):
    return ls.get_stack(name, req['stack'], req['context'], req['links']).update()

content = {}
if sys.argv[2] == '-':
    content = json.loads(''.join(sys.stdin.readlines()))
else:
    content = json.loads(file(sys.argv[1]).read())

if sys.argv[1] == 'deploy':
    deploy(sys.argv[2], content)
elif sys.argv[1] == 'update':
    update(sys.argv[2], content)
else:
    print('Unknown command')
    sys.exit(1)
