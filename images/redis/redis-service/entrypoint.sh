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

options=" --requirepass $AUTH_PASSWORD "

redis_info() {
  set +e
  timeout -t 10 redis-cli -h "$1" -p "$2" -a "$AUTH_PASSWORD" info replication
  set -e
}

reset_sentinel() {
  set +e
  timeout -t 10 redis-cli -h "$1" -p "$2" sentinel reset mymaster
  set -e
}

redis_info_role() {
  echo "$1" | grep -e '^role:' | cut -d':' -f2 | tr -d '[:space:]'
}

domain_ip() {
  dig "$1" | grep -E '\s+IN\s+A\s+' | awk '{print $NF}'
}


reset_all_sentinels() {
  IFS=$'\n'
  echo "Resetting all sentinels: $SENTINEL_NODES"
  for node in $SENTINEL_NODES; do
    h=${node%:*}
    p=${node#*:}

    for s_ip in $(domain_ip "$h"); do
      if [ -z "$s_ip" ]; then
        echo "Failed to resolve: $h"
        continue
      fi
      reset_sentinel "$s_ip" "$p"
    done
  done
  IFS=$' '
}

get_no() {
  echo $($REDIS_SELF | awk -F- '{print $NF}')
}

slave_priority() {
  no=$(get_no)
  {
    priority="$(((no + 1) * 10))"
  }
  if [ -z "$priority" ]; then
    priority="10"
  fi
  echo "$priority"
}


run() {
  my_host="$REDIS_SELF"
  master_ip=''

  options=" $options --slave-priority $(slave_priority) "

  only_server=true
  for node in $REDIS_NODES; do

    h=${node%:*}
    p=${node#*:}
    if [ "$h" = "$my_host" ]; then
      continue
    fi

    s_ip="$(domain_ip "$h")"
    if [ -z "$s_ip" ]; then
      echo "Failed to resolve: $h"
      continue
    fi

    only_server=false

    i="$(redis_info "$s_ip" "$p")"
    if [ -n "$i" ]; then
      if [ "$(redis_info_role "$i" "$p")" = 'master' ]; then
        master_ip="$s_ip"
        break
      fi
    else
      echo "Unable to get Replication INFO: $h ($s_ip:$p)"
      continue
    fi
  done

  if [ "$only_server" = true ]; then
    :
  else
    if [ -z "$master_ip" ]; then
      echo "Unable to start because all servers are slave."
      exit 1
    fi

    i="0"
    while true; do
      slave_ip=$(domain_ip $REDIS_SELF)
      if [ -z "$slave_ip" ] && [ ! "$i" = "10" ]; then
        sleep $(shuf -i2-6 -n1)
      else
        break
      fi
      i=$((i+1))
    done
    options=" $options --masterauth $AUTH_PASSWORD --slaveof $master_ip $p --slave-announce-ip $slave_ip --slave-announce-port $p "
  fi

  reset_all_sentinels
  exec docker-entrypoint.sh $* $options
}

if [ "$REDIS_MODE" = "ha" ]; then
  run $*
else
  exec docker-entrypoint.sh $* $options
fi
