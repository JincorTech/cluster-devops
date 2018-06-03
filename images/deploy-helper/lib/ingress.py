# -*- coding: utf-8 -*-

import re
import yaml
import json
import base64
import dockerhelper as dh


class ingress_haproxy_config:
    def __init__(self, cfg=''):
        if len(cfg) > 0:
            self.loads(cfg)
        else:
            self.config = {
                'global': {'ingress': {'haproxy': {
                }}}
            }
        self.root = self.config['global']['ingress']['haproxy']

    def check(self):
        has_error = False

        for name, e in self.entrypoint().items():
            val = json.loads(e)
            if not val['service'] in self.root['services']:
                print 'ERROR: Endpoint %s forward to %s, but services is absent with this name' % (
                    name, val['service'])
                has_error = True

        if has_error:
            raise Exception('Fix errors')

    def loads(self, data):
        self.config = yaml.load(data)
        self.root = self.config['global']['ingress']['haproxy']
        if self.root['configs'] == None:
            self.root['configs'] = {}
        if self.root['entrypoints'] == None:
            self.root['entrypoints'] = {}
        if self.root['services'] == None:
            self.root['services'] = {}
        return self.config

    def dumps(self):
        self.check()
        return yaml.dump(self.config, default_flow_style=False)

    def toggle_limitter(self, is_enabled):
        if 'limitter' in self.root['configs']:
            del self.root['configs']['rate_limitter']
            del self.root['configs']['limitter']
        if is_enabled:
            self.root['configs']['rate_limitter'] = 10000
            self.root['configs']['limitter'] = True

    def toggle_ssl(self, is_enabled):
        if 'ssl' in self.root['configs']:
            del self.root['configs']['ssl']
        if is_enabled:
            self.root['configs']['ssl'] = {
                'enabled': True
            }

    def entrypoint(self, name=''):
        if len(name) > 0:
            return json.load(self.root['entrypoints'][name]) if name in self.root['entrypoints'] else {}
        return self.root['entrypoints']

    def service(self, name=''):
        if len(name) > 0:
            return json.load(self.root['services'][name]) if name in self.root['services'] else {}
        return self.root['services']

    def set_entrypoint(self, name, host, service, url='', ssl=''):
        entrypoint = self.entrypoint(name)

        entrypoint['host'] = host
        entrypoint['service'] = service

        if len(url) != 0:
            entrypoint['url'] = url

        if len(ssl) != 0:
            entrypoint['ssl'] = 'crt %s.crt' % (ssl)

        self.root['entrypoints'][name] = json.dumps(entrypoint)

    def del_entrypoint(self, name):
        del self.root['entrypoints'][name]

    def set_service(self, name, hosts, limitter=0):
        service = self.service(name)
        service['hosts'] = []

        if limitter > 0:
            service['limitter'] = str(limitter)

        for h in hosts:
            host = {
                'host': h['host']
            }
            if 'options' in h:
                host['options'] = h['options']
            service['hosts'].append(host)

        self.root['services'][name] = json.dumps(service)

    def del_service(self, name):
        del self.root['services'][name]


class ingress_haproxy:
    def __init__(self):
        self.cfg = ingress_haproxy_config()

    def _format_name(self, host, path):
        return re.sub(r'[^A-Za-z0-9]', '', host + path)

    def add_route(self, host, path, hosts, limitter=0):
        name = self._format_name(host, path)
        self.cfg.set_entrypoint(name, host, name, path)
        self.cfg.set_service(name, hosts, limitter)

    def del_route(self, host, path):
        name = self._format_name(host, path)
        self.cfg.del_entrypoint(name)
        self.cfg.del_service(name)

    def load(self):
        self.config_raw = dh.get_client().configs.list(
            filters={'name': 'global_ingress_haproxy_cfg_'})[0]
        self.cfg = ingress_haproxy_config(
            base64.b64decode(self.config_raw.attrs['Spec']['Data']))
        self.cfg.toggle_limitter(True)

    def commit(self):
        config_name = self.config_raw.attrs['Spec']['Name']
        return dh.update_config_content(False, config_name, dh.get_next_name(config_name), self.cfg.dumps())
