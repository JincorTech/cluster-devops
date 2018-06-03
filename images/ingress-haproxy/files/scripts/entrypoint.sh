#!/bin/sh

set -eu

for env in $(env); do
  key=${env%=*}
  [ -n "${key#*_FILE}" ] && continue
  val=${env#*=}
  key=${key%_FILE}
  val=$(cat $val)
  export "${key}"="${val}"
done

confs=${HA_CONFIG_YML_PATH:-/usr/local/etc/haproxy/config.yml}
secret=${HA_SECRET_YML_PATH:-/usr/local/etc/haproxy/secret.yml}

if [ ! -e "$secret" ]; then
  secret=""
fi

if [ -e $confs ]; then
  cat $confs $secret > /usr/local/etc/haproxy/gathered.yml
  confs="-file /usr/local/etc/haproxy/gathered.yml"
fi

confd -onetime --backend file $confs

exec /docker-entrypoint.sh haproxy -f /usr/local/etc/haproxy/haproxy.cfg $*
