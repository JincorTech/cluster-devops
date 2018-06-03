#!/usr/bin/python
# -*- coding: utf-8 -*-

from lib.authhelper import get_access_token
import os
import sys
import time
import json
import requests
import docker

def setup_config(docker_client, is_secret, name, content, labels=None):
    provider = docker_client.secrets if is_secret else docker_client.configs
    try:
        cfg = provider.get(name)
        cfg.remove()
    except:
        pass
    return provider.create(name=name, data=content, labels=labels)

response = {'tenant': os.environ['TENANT_EMAIL']}

try:
    for env in ('CLIENT_PEM_FILE', 'AUTH_BASE_URL', 'TENANT_EMAIL', 'TENANT_PASSWORD', 'CREATE_CONFIG_NAME'):
        if not os.environ.has_key(env):
            print 'No %s specified Skip...' % env
            sys.exit(0)

    docker_client = docker.from_env()
    response['response'] = json.loads(get_access_token(os.environ))

except Exception as e:
    response['error'] = str(e)
    print('ERROR', e)

setup_config(docker_client, False, os.environ['CREATE_CONFIG_NAME'], json.dumps(response), {
    'com.secrettech.temporary': 'authverify-helper'
})
