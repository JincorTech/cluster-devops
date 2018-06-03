#!/bin/bash

set -eu

for env in $(env); do
  key=${env%=*}
  [ -n "${key#*_FILE}" ] && continue
  val=${env#*=}
  key=${key%_FILE}
  val=$(cat $val)
  export "${key}"="${val}"
done

echo 'Create user...'

for dbl in $MONGO_INITDBS; do
cat << EOF | mongo
use admin;
var [dbname, user, ...pwd] = '$dbl'.trim().split(':');
db.createUser({
  user,
  pwd: pwd.join(':'),
  roles: [ { role: 'readWrite', db: dbname } ]
});
EOF
done
