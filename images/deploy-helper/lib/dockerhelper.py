# -*- coding: utf-8 -*-

import sys
import re
import docker
import subprocess
import json
import time
import base64


_client = False


def get_client():
    global _client
    if _client:
        return _client
    _client = docker.from_env()
    return _client


def create_config(is_secret, name, content, labels=None):
    provider = get_client().secrets if is_secret else get_client().configs
    try:
        return provider.get(name)
    except:
        pass
    return provider.create(name=name, data=content, labels=labels)

def get_config_data(name_or_id):
    return base64.b64decode(get_client().configs.get(name_or_id).attrs['Spec']['Data'])

def remove_config(is_secret, name_or_id):
    provider = get_client().secrets if is_secret else get_client().configs
    try:
        provider.get(name_or_id).remove()
    except:
        pass

def update_config_content(is_secret, old_name, new_name, new_content):
    cfg_type = u'Secret' if is_secret else u'Config'
    cfg_types = cfg_type + 's'
    services = []
    config = False

    provider = get_client().secrets if is_secret else get_client().configs

    # Find service who using config
    for service in get_client().services.list():
        if cfg_types in service.attrs['Spec']['TaskTemplate']['ContainerSpec']:
            for cfg in service.attrs['Spec']['TaskTemplate']['ContainerSpec'][cfg_types]:
                if cfg['ConfigName'] == old_name:
                    config = [cfg, provider.get(cfg[cfg_type + 'Name'])]
                    services.append(service)
                    break

    if len(services) == 0:
        raise Exception('No service who use %s cfg' % old_name)

    # Create config with same attrs and new content
    new_config = create_config(
        is_secret, new_name, new_content, config[1].attrs['Spec']['Labels'])

    # Update all services for new config
    for service in services:
        cfgs = {}
        items = []
        for item in service.attrs['Spec']['TaskTemplate']['ContainerSpec'][cfg_types]:
            is_replace_cfg = item[cfg_type + 'Name'] == old_name
            if is_secret:
                secret_id = new_config.id if is_replace_cfg else item['SecretID']
                secret_name = new_name if is_replace_cfg else item['SecretName']
                item = item['File']
                items.append(docker.types.SecretReference(
                    secret_id, secret_name, item['Name'], item['UID'], item['GID'], item['Mode']))
            else:
                config_id = new_config.id if is_replace_cfg else item['ConfigID']
                config_name = new_name if is_replace_cfg else item['ConfigName']
                item = item['File']
                items.append(docker.types.ConfigReference(
                    config_id, config_name, item['Name'], item['UID'], item['GID'], item['Mode']))

        cfgs[cfg_types.lower()] = items
        service.update(**cfgs)

    # Remove old config
    config[1].remove()


def get_next_name(prev_name, mask=r'(.+?)([\d]+)$'):
    res = re.match(mask, prev_name)
    if res == None or len(res.groups()) != 2:
        return prev_name + '000001'
    return '%s%d' % (res.group(1), int(res.group(2)) + 1)


def deploy_stack(stack_name, stack_content, wait_stack_services=False):
    process = subprocess.Popen([
        'docker', 'stack', 'deploy', '--with-registry-auth', '--compose-file',
        '-', stack_name], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(stack_content)

    result = process.communicate(input=stack_content)

    if wait_stack_services:
        wait_stack(stack_name)
    return result


def wait_service(svc_name, timeout=150):
    svc = get_client().services.get(svc_name)

    while timeout > -1:
        tasks1 = svc.tasks({'desired-state': 'running'})
        time.sleep(2)
        tasks2 = svc.tasks({'desired-state': 'running'})
        if len(tasks1) > 0 and len(tasks1) == len(tasks2):
            return
        timeout -= 1

    raise Exception('Wait %s service timeout' % svc.name)


def wait_stack(stack_name):
    services = get_client().services.list(
        filters={'label': ['com.docker.stack.namespace=%s' % stack_name]})
    if len(services) == 0:
        raise Exception('%s stack is not found' % stack_name)
    for svc in services:
        wait_service(svc.id)


def create_temporary_manager_service(image, envs, networks, secrets):
    return get_client().services.create(image, None,
        env=envs,
        networks=networks,
        constraints=['node.role==manager'],
        mounts=['/var/run/docker.sock:/var/run/docker.sock'],
        restart_policy=docker.types.RestartPolicy(),
        secrets=map(lambda x: docker.types.SecretReference(x['id'],
            x['name'], x['filename']), secrets)
        )
