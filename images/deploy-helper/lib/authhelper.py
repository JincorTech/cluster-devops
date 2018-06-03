import time
import json
import urllib3
import requests
import sys

urllib3.disable_warnings()

def post_request(url, pem_file, data):
    return requests.post(url, verify=False, headers={'Accept': 'application/json', 'Content-Type': 'application/json'},
        cert=(pem_file, pem_file),
        data=json.dumps(data)
    )

def get_access_token(params, skip_existing = True):
    max_retries = 60 * 3
    auth_wait_retries = 0
    while auth_wait_retries < max_retries:
        try:
            post_request(params['AUTH_BASE_URL'] + '/', params['CLIENT_PEM_FILE'], {})
            break
        except Exception, r:
            print(r)
            time.sleep(1)
            auth_wait_retries += 1

    time.sleep(1)
    if auth_wait_retries == max_retries:
        raise Exception('ERROR was occurred when waiting auth for bootstrapping. Max retries was reached.')

    reg_resp = post_request(params['AUTH_BASE_URL'] + '/tenant', params['CLIENT_PEM_FILE'], {'email': params['TENANT_EMAIL'], 'password': params['TENANT_PASSWORD']})
    if reg_resp.status_code != 200 and not skip_existing and reg_resp.status_code == 400:
        raise Exception('ERROR was occurred when auth register tenant. ' + reg_resp.text)

    login_resp = post_request(params['AUTH_BASE_URL'] + '/tenant/login', params['CLIENT_PEM_FILE'], {'email': params['TENANT_EMAIL'], 'password': params['TENANT_PASSWORD']})
    if login_resp.status_code != 200:
        raise Exception('ERROR was occurred when auth login. ' + login_resp.text)

    return login_resp.text
