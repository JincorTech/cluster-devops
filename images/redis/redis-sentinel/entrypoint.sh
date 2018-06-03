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

redis_info() {
  set +e
  timeout -t 10 redis-cli -h "$1" -p "$2" -a "$SENTINEL_AUTH_PASSWORD" info replication
  set -e
}

redis_info_role() {
  echo "$1" | grep -e '^role:' | cut -d':' -f2 | tr -d '[:space:]'
}

domain_ip() {
  dig "$1" | grep -E '\s+IN\s+A\s+' | awk '{print $NF}'
}

run() {
  master_ip=""
  master_port=""

  for node in $REDIS_NODES; do
    h=${node%:*}
    p=${node#*:}

    ip="$(domain_ip "$h")"
    if [ -z "$ip" ]; then
      echo "Failed to resolve: $h"
      continue
    fi

    i="$(redis_info "$ip" "$p")"
    if [ -n "$i" ]; then
      if [ "$(redis_info_role "$i")" = 'master' ]; then
        master_ip="$ip"
        master_port="$p"
      fi
    else
      echo "Unable to get Replication INFO: $h ($ip:$p)"
      continue
    fi
  done

  if [ -z "$master_ip" ]; then
    >&2 echo "Master not found."
    exit 1
  fi

  sed -i "s/\$SENTINEL_MASTER_NODE/$master_ip $master_port/g" /etc/sentinel/sentinel.conf
  sed -i "s/\$SENTINEL_QUORUM/$SENTINEL_QUORUM/g" /etc/sentinel/sentinel.conf
  sed -i "s/\$SENTINEL_DOWN_AFTER/$SENTINEL_DOWN_AFTER/g" /etc/sentinel/sentinel.conf
  sed -i "s/\$SENTINEL_FAILOVER/$SENTINEL_FAILOVER/g" /etc/sentinel/sentinel.conf
  sed -i "s/\$SENTINEL_AUTH_PASSWORD/$SENTINEL_AUTH_PASSWORD/g" /etc/sentinel/sentinel.conf

  exec docker-entrypoint.sh $* /etc/sentinel/sentinel.conf --sentinel
}

run "$@"
