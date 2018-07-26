# -*- coding: utf-8 -*-

import os
import re
from jinja2 import Environment, FileSystemLoader

THIS_DIR = os.path.join(os.path.dirname(
    os.path.abspath(__file__)), 'templates')
j2_env = Environment(loader=FileSystemLoader(THIS_DIR), trim_blocks=True)


def render(name, data):
    return j2_env.get_template('%s-stack.yml.j2' % name).render(data)


class stack_template(object):
    def __init__(self, name, stack):
        self.name = name
        self.stack = stack
        self.ingress = {}
        self.services = {}
        self.configs = {}

    def declare_services(self, *services):
        for service in services:
            self.services[service] = {
                'deploy': {
                    'replicas': '1',
                    'limits': {
                        'memory': '1024M'
                    }
                },
                'env': {},
                'secrets': {},
                'configs': {}
            }

    def set_envs(self, service, envs):
        for l in envs.split("\n"):
            inx = l.find('=')
            if len(l) > 0 and l[0] == '#' or inx < 1:
                continue
            self.set_env(service, l[:inx], l[inx + 1:])
        return self

    def get_secret_name(self, service, name):
        return '%s_%s_%s' % (self.name, service, name.lower())

    def set_secret(self, service, path, name, value, abs_external = False, mode='', uid=''):
        secret = {
            'name': '%s_%s' % (service, name.lower()),
            'path': path,
            'external': value.strip() if abs_external else self.get_secret_name(service, name),
            'value': None if abs_external else value
        }

        if len(mode) > 0:
            secret['mode'] = mode
        if len(uid) > 0:
            secret['uid'] = uid

        self.services[service]['secrets'][secret['name']] = secret

    def set_env(self, service, name, value, mode='', uid=''):
        if re.match('^".*"$|^\'.*\'$', value):
            value = value[1:-1]

        name = name.strip()
        if name[0] == '*':
            name = name[1:]

            abs_external = False
            if name[0] == '*':
                name = name[1:]
                abs_external = True

            path = '/etc/secret_%s' % name.lower()

            self.set_secret(service, path, name, value, abs_external, mode, uid)

            name = name + '_FILE'
            value = path

        self.services[service]['env'][name] = value.strip()

        return self

    def dumps(self, other={}):
        data = self.services.copy()
        data.update(self.configs)
        data.update({'ingress': self.ingress})
        data.update(other)
        return render(self.stack, data)


class redis_stack_template(stack_template):
    def __init__(self, name, auth_password, ha=False):
        super(redis_stack_template, self).__init__(
            name, 'redis-single' if not ha else 'redis-ha')
        self.ha = ha

        if ha:
            auth_password_secret = '%s_%s_%s' % (
                self.name, 'redis', 'auth_password')
            self.declare_services(
                'proxy', 'redis', 'manager', 'manager1', 'manager2', 'manager3', 'redis1', 'redis2')
            self.set_env('proxy', '**REDIS_AUTH_PASSWORD', auth_password_secret) \
                .set_env('manager', '**SENTINEL_AUTH_PASSWORD', auth_password_secret)
            for inx in range(1, 3):
                self.services['redis%d' % inx]['deploy']['constraints'] = [
                    {'name': 'node.labels.com.secrettech.db.redis.index', 'value': '%d' % inx}]

            self.services['proxy']['image'] = 'alekns/redis-proxy:latest'
            self.services['manager']['image'] = 'alekns/redis-sentinel:latest'
        else:
            self.declare_services('redis')

        self.services['redis']['image'] = 'alekns/redis-service:latest'

        self.set_env('redis', '*AUTH_PASSWORD', auth_password)


class mongo_stack_template(stack_template):
    def __init__(self, name, admin_password, dbs, shared_key='', ha=False):
        super(mongo_stack_template, self).__init__(
            name, 'mongo-single' if not ha else 'mongo-ha')
        self.ha = ha

        if ha:
            self.declare_services('mongo', 'mongo1', 'mongo2', 'mongo3')
            self.set_env('mongo', '*MONGO_SHARED_KEY', shared_key)
            sec = self.services['mongo']['secrets']['%s_%s' %
                                                    ('mongo', 'mongo_shared_key')]
            sec['uid'] = '"999"'
            sec['mode'] = '0400'

            for inx in range(1, 4):
                self.services['mongo%d' % inx]['deploy']['constraints'] = [
                    {'name': 'node.labels.com.secrettech.db.mongo.index', 'value': '%d' % inx}]
        else:
            self.declare_services('mongo')

        self.services['mongo']['image'] = 'alekns/mongo-service:latest'

        self.set_env('mongo', '*MONGO_INITDBS', "\n".join(map(lambda i: '%s:%s:%s' % (i['db'], i['user'], i['password']), dbs))) \
            .set_env('mongo', '*MONGO_INITDB_ROOT_PASSWORD', admin_password)


def set_stack_template_network(name, configs, stack_network):
    if stack_network:
        configs[name + '_network'] = stack_network
    elif name + '_network' in configs:
        del configs[name + '_network']


class authverify_stack_template(stack_template):
    def __init__(self, name, jwt_key):
        super(authverify_stack_template, self).__init__(name, 'auth-verify')
        self.configs['ingress_network'] = {}
        self.declare_services('auth', 'verify')
        self.set_env('auth', '*JWT_KEY', jwt_key)

        self.services['auth']['image'] = 'alekns/backend-auth:latest'
        self.services['verify']['image'] = 'alekns/backend-verify:latest'
        self.services['auth']['deploy']['replicas'] = '2'
        self.services['verify']['deploy']['replicas'] = '2'

    def use_tlsav(self, ca_name, server_name, ca_cn):
        self.services['auth']['configs'][ca_name] = {
            'value': None,
            'external': ca_name,
            'path': '/etc/config_tls_ca'
        }
        self.services['auth']['secrets'][server_name] = {
            'value': None,
            'external': server_name,
            'path': '/etc/secret_tls_server'
        }
        self.set_env('auth', 'MAINTAIN_TLS_PORT', '6000')
        self.set_env('auth', 'MAINTAIN_TLS_CA_CN', ca_cn)
        self.set_env('auth', 'MAINTAIN_TLS_CA', '/etc/config_tls_ca')
        self.set_env('auth', 'MAINTAIN_TLS_PEM', '/etc/secret_tls_server')

    def use_redis(self, redis_url, stack_network=False):
        self.set_env('auth', '*REDIS_URL', redis_url) \
            .set_env('verify', '**REDIS_URL', '%s_%s_%s' % (self.name, 'auth', 'redis_url'))
        set_stack_template_network('redis', self.configs, stack_network)

    def use_mail_provider(self, mailprovider, configs):
        self.set_env('verify', 'MAIL_DRIVER', mailprovider)
        for (name, val) in configs.items():
            self.set_env('verify', name.upper(), val)


class app_stack_template(stack_template):
    def __init__(self, name):
        super(app_stack_template, self).__init__(name, 'app')
        self.declare_services('frontend', 'backend')

        self.services['frontend']['image'] = 'jincort/frontend-ico-dashboard:stage'
        self.services['backend']['image'] = 'jincort/backend-ico-dashboard:stage'
        self.services['frontend']['deploy']['replicas'] = '2'
        self.services['backend']['deploy']['replicas'] = '2'

    def use_redis(self, redis_url, redis_prefix, set_envs=True, stack_network=False):
        if set_envs:
            self.set_env('backend', '*REDIS_URL', redis_url) \
                .set_env('backend', 'REDIS_PREFIX', redis_prefix)
        set_stack_template_network('redis', self.configs, stack_network)

    def use_mongo(self, mongo_url, set_envs=True, stack_network=False):
        if set_envs:
            self.set_env('backend', '*MONGO_URL', mongo_url)
        set_stack_template_network('mongo', self.configs, stack_network)

    def use_authverify(self, auth_url, verify_url, set_envs=True, stack_network=False):
        if set_envs:
            self.set_env('backend', 'AUTH_BASE_URL', auth_url) \
                .set_env('backend', 'VERIFY_BASE_URL', verify_url)
        set_stack_template_network('authverify', self.configs, stack_network)
