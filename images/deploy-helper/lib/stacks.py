# -*- coding: utf-8 -*-

import time
import socket
import urlparse
import json
import re
import uuid
import jsonschema as js
import dockerhelper as dh
import stacktemplates as st
import authhelper as ah

class context:
    def __init__(self, name, stack, data, links):
        self.name = name
        self.stack = stack
        self.data = data
        self.links = links


def get_stack(name, stack, data, links):
    ctx = context(name, stack, data, links)
    if ctx.stack == 'redis':
        return redis_stack(ctx)
    elif ctx.stack == 'mongo':
        return mongo_stack(ctx)
    elif ctx.stack == 'authverify':
        return authverify_stack(ctx)
    elif ctx.stack == 'app':
        return app_stack(ctx)
    else:
        raise Exception('Unknown stack %s' % ctx.stack)


def explode(plain_context_data, filter_path=''):
    context = {}
    for key, value in plain_context_data.iteritems():
        if key.find(filter_path) != 0:
            continue
        root = context
        prev_root = root
        for p in key.split('.'):
            if not p in root:
                root[p] = {}
            prev_root = root
            root = root[p]
        if p in prev_root and isinstance(prev_root, dict) and len(prev_root[p].keys()) > 0:
            raise Exception('Conflicting key path %s' % key)
        prev_root[p] = value
    return context


class stack(object):
    def __init__(self, context):
        self.context = context

    def configure_services(self, params, tmpl):
        if params == None or not 'services' in params:
            return

        self.configure_ingress(tmpl)

        params = params['services']
        for svc_name in params:
            if not svc_name in tmpl.services:
                raise Exception('%s service not found in the stack %s' % (
                    svc_name, self.context.stack))
            if 'limits' in params[svc_name]:
                tmpl.services[svc_name]['deploy']['limits'] = params[svc_name]['limits']
            if 'restart' in params[svc_name]:
                tmpl.services[svc_name]['deploy']['restart'] = params[svc_name]['restart']
            if 'constraints' in params[svc_name]:
                tmpl.services[svc_name]['deploy']['constraints'] = params[svc_name]['constraints']
            if 'envs' in params[svc_name]:
                tmpl.set_envs(svc_name, params[svc_name]['envs'])
            if 'image' in params[svc_name]:
                tmpl.services[svc_name]['image'] = params[svc_name]['image']
        self.create_configs(tmpl)

    def configure_ingress(self, tmpl):
        ingress_config = explode(self.context.data, 'ingress.')
        if len(ingress_config.keys()) == 0:
            return True

        for svc_name, ingress_cfg in ingress_config['ingress'].iteritems():
            if not svc_name in tmpl.services:
                raise Exception('Unknown services %s for ingress configuration' % svc_name)

            if not 'expose' in ingress_cfg:
                raise Exception('%s expose not specified in ingress %s' % (svc_name, self.context.stack))

            if not svc_name in tmpl.ingress:
                tmpl.ingress[svc_name] = {}

            url = urlparse.urlparse(ingress_cfg['expose'])
            for k, v in urlparse.parse_qs(url.query).iteritems():
                if k == 'limitter':
                    values = v[0].split(',')
                    if len(values) % 3 != 0:
                        raise Exception('invalid limitter for %s' % svc_name)
                    limitter_cfg = tmpl.ingress[svc_name]['limitter'] = []
                    while len(values) > 0:
                        limitter_cfg.append(values[:3])
                        values = values[3:]
                else:
                    raise Exception('unknown paramter %s for %s' % (k, svc_name))

            alias = url.hostname
            tmpl.ingress[svc_name]['host'] = url.hostname
            if len(url.path):
                tmpl.ingress[svc_name]['path'] = url.path
                alias += url.path

            if 'maxconn' in ingress_cfg:
                tmpl.ingress[svc_name]['maxconn'] = int(ingress_cfg['maxconn'])

            tmpl.ingress[svc_name]['port'] = str(url.port)
            tmpl.ingress[svc_name]['alias'] = format_ingress_alias(tmpl, self.context.name, svc_name, alias)


    def create_configs(self, tmpl):
        for svc_name, _ in tmpl.services.iteritems():
            for cfg_type in ('secrets', 'configs'):
                for _, cfg in tmpl.services[svc_name][cfg_type].iteritems():
                    if cfg['value'] != None:
                        dh.create_config(True, cfg['external'], cfg['value'], {
                            'com.docker.stack.namespace': self.context.name
                        })

    def get_stack_networks(self, stackname):
        return dh.get_client().networks.list(filters={'label': ['com.docker.stack.namespace=%s' % stackname]})

    def get_first_stack_name_by_type(self, stack_type, links):
        stacks = filter(lambda x: x[0] == stack_type,
                        map(lambda x: x.split(':'), links))
        if len(stacks) > 0:
            return stacks[0][1]
        return False

    def try_get_network_for(self, links, stacktype):
        stack = self.get_first_stack_name_by_type(stacktype, links)
        if stack:
            networks = filter(lambda x: x.name.find(stacktype) > -1,
                              self.get_stack_networks(stack))
            if len(networks) != 1:
                raise Exception(
                    'stack %s hasnt uniquely network for %s' % (stacktype, stack))
            return networks[0].name
        elif len(links) > 0 and len(stacktype) > 0:
            raise Exception('Network is not found for stack type %s' % stacktype)
        return False

    def wait_deploy(self):
        pass


class redis_stack(stack):
    def deploy(self):
        tmpl = st.redis_stack_template(
            self.context.name, self.context.data['construct.auth_password'], self.context.data['construct.type'] == 'ha')
        self.configure_services(explode(self.context.data, 'services.'), tmpl)
        return dh.deploy_stack(self.context.name, tmpl.dumps({}), True)


class mongo_stack(stack):
    def deploy(self):
        is_ha = self.context.data['construct.type'] == 'ha'
        shared_key = self.context.data.get('construct.shared_key', '')
        if is_ha and len(shared_key) < 1:
            raise Exception('must specified construct.shared_key in ha mode')
        tmpl = st.mongo_stack_template(
            self.context.name, self.context.data['construct.admin_password'], self.context.data['construct.dbs'], shared_key, is_ha)
        self.configure_services(explode(self.context.data, 'services.'), tmpl)
        return dh.deploy_stack(self.context.name, tmpl.dumps({}), True)


def format_ingress_alias(tmpl, stack_name, svc_name, alias):
    return re.sub('^-+|-+$', '', re.sub(r'-+', '-', re.sub(r'[^A-Za-z0-9]', '-', '%s-%s-%s' % (stack_name, 'app', alias))))

class authverify_stack(stack):
    def deploy(self):
        tmpl = st.authverify_stack_template(
            self.context.name, self.context.data['construct.jwt_key'])
        tmpl.use_redis(self.context.data['construct.redis_url'], self.try_get_network_for(
            self.context.links, 'redis'))
        if 'construct.mail_provider' in self.context.data:
            tmpl.use_mail_provider(
                self.context.data['construct.mail_provider'], self.context.data['construct.mail_config'])

        if 'construct.tls.tenant.ca' in self.context.data and 'construct.tls.tenant.server' in self.context.data and \
            'construct.tls.tenant.ca_cn' in self.context.data:

            tlsav_ca = '%s_tlsav_ca' % self.context.name
            dh.create_config(False, tlsav_ca, self.context.data['construct.tls.tenant.ca'], {
                'com.docker.stack.namespace': self.context.name
            })
            tlsav_server = '%s_tlsav_server' % self.context.name
            dh.create_config(True, tlsav_server, self.context.data['construct.tls.tenant.server'], {
                'com.docker.stack.namespace': self.context.name
            })
            tmpl.use_tlsav(tlsav_ca, tlsav_server, self.context.data['construct.tls.tenant.ca_cn'])

        self.configure_services(explode(self.context.data, 'services.'), tmpl)

        return dh.deploy_stack(self.context.name, tmpl.dumps({}), True)


class app_stack(stack):

    def set_access_auth_pem(self, pem_file):
        self.access_pem_file = pem_file

    def deploy(self):
        data = self.context.data
        tmpl = st.app_stack_template(self.context.name)

        tmpl.use_redis(data['construct.redis_url'], self.context.name, self.try_get_network_for(
            self.context.links, 'redis'))
        tmpl.use_mongo(data['construct.mongo_url'], self.try_get_network_for(
            self.context.links, 'mongo'))
        tmpl.use_authverify(data['construct.auth_url'],
                            data['construct.verify_url'], self.try_get_network_for(self.context.links, 'authverify'))

        auth_jwt_name = data.get('construct.auth_jwt_name', 'AUTH_JWT')
        self.process_auto_get_access_token(tmpl, auth_jwt_name)

        self.configure_services(explode(data, 'services.'), tmpl)

        return dh.deploy_stack(self.context.name, tmpl.dumps({}))

    def process_auto_get_access_token(self, tmpl, access_env_name):
        ctx = self.context.data
        for parameter in ('construct.tenant_email', 'construct.tenant_password', 'construct.tenant_client'):
            if not parameter in ctx:
                return

        url = urlparse.urlparse(ctx['construct.auth_url'])

        authBaseUrl = urlparse.urlparse('https://%s:6000' % url.hostname).geturl()
        accessToken = ''

        sec = False

        try:
            # create external secret
            sec = dh.create_config(True, 'global_av_temporary_secret', ctx['construct.tenant_client'])

            if len(filter(lambda x: x.split(':')[0] == 'authverify', self.context.links)) > 0:
                network = self.try_get_network_for(self.context.links, 'authverify')
                if not network:
                    raise Exception('Network for authverify not found')

                authhelper_config_name = 'tmpah-%s' % uuid.uuid4()

                svc = False
                try:
                    # create service in authverify network
                    svc = dh.create_temporary_manager_service('alekns/deploy-ah-helper:latest', [
                             'CREATE_CONFIG_NAME=%s' % authhelper_config_name,
                             'CLIENT_PEM_FILE=/etc/secret_tlsav_client',
                             'AUTH_BASE_URL=%s' % ctx['construct.auth_url'],
                             'TENANT_EMAIL=%s' % ctx['construct.tenant_email'],
                             'TENANT_PASSWORD=%s' % ctx['construct.tenant_password']
                         ],
                         [network],
                         [{
                             'id': sec.id,
                             'name': 'global_av_temporary_secret',
                             'filename': '/etc/secret_tlsav_client'
                         }]
                     )

                    max_retries = 60 * 3
                    attempts = 0
                    resp = {}
                    while attempts < max_retries:
                        try:
                            resp = json.loads(dh.get_config_data(authhelper_config_name))
                        except Exception as e:
                            print(e)
                            attempts -= 1
                            time.sleep(1)
                            continue

                        if 'error' in resp:
                            raise Exception(resp['error'])

                        accessToken = resp['response']['accessToken']
                        break

                    # remove service
                    svc.remove()
                    time.sleep(1)

                    if attempts == max_retries:
                        raise Exception('AuthVerify helper isnot return data')

                except Exception as e:
                    if svc:
                        svc.remove()
                        time.sleep(1)
                    raise e
                dh.remove_config(False, authhelper_config_name)
            else:
                resp = json.loads(ah.get_access_token({
                    'CLIENT_PEM_FILE': self.access_pem_file,
                    'AUTH_BASE_URL': authBaseUrl,
                    'TENANT_EMAIL': ctx['construct.tenant_email'],
                    'TENANT_PASSWORD': ctx['construct.tenant_password']
                }))

                if not 'accessToken' in resp:
                    raise Exception('%s' % str(resp))
                accessToken = resp['accessToken']

            sec.remove()

        except Exception as e:
            if sec:
                sec.remove()
            raise e

        tmpl.set_env('backend', '*' + access_env_name, accessToken)
