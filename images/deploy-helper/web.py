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


deploy_schema = {
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

@app.route('/stacks/actions/deploy', methods=['POST'])
def deploy():
    try:
        validate(request.json, deploy_schema)
    except:
        return jsonify(message=traceback.format_exc()), 400
    try:
        req = request.json
        return jsonify(message=ls.get_stack(req['name'], req['stack'], req['context'], req['links']).deploy())
    except:
        return jsonify(message=traceback.format_exc()), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
