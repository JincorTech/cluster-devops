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

hafile=/usr/local/etc/haproxy/haproxy.cfg

sed "/### redis instances ###/q" ${hafile}.tmpl > ${hafile}
for node in $REDIS_NODES; do
  inx=$(echo $node | tr -dc 0-9)
  sed -i "/### redis instances ###/a  server redis${inx} ${node} check inter 2s" ${hafile}
done

sed -i "s/\${REDIS_AUTH_PASSWORD}/${REDIS_AUTH_PASSWORD}/g" ${hafile}

exec /docker-entrypoint.sh $*
