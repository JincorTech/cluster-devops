#!/usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import re
import lib.stacks as ls
import traceback
from jsonschema import validate
from flask import Flask, request, jsonify

app = Flask(__name__)


deploy_or_update_schema = {
    "$schema": "http://json-schema.org/schema#",

    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "stack": {"type": "string"},
        "context": {
            "type": "object",
            "minProperties": 1
        },
        "links": {
            "type": "array",
            "items": {
                "type": "string"
            }
        }
    },
    "required": ["name", "stack", "context", "links"],
    "additionalProperties": False
}

@app.errorhandler(404)
def page_not_found(e):
    return jsonify(error=404, text=str(e)), 404

def run_task(method):
    try:
        validate(request.json, deploy_or_update_schema)
    except:
        return jsonify(message=traceback.format_exc()), 400
    try:
        req = request.json
        if method == 'deploy':
            return jsonify(response=ls.get_stack(req['name'], req['stack'], req['context'], req['links']).deploy())
        return jsonify(response=ls.get_stack(req['name'], req['stack'], req['context'], req['links']).update())
    except:
        return jsonify(message=traceback.format_exc()), 500


@app.route('/stacks/actions/deploy', methods=['POST'])
def deploy():
    return run_task('deploy')

@app.route('/stacks/actions/update', methods=['POST'])
def update():
    return run_task('update')

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
