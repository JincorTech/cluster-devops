#!/bin/bash

lock_file='/data/db/replication.complete'

if [ "$MONGO_INIT_PRIMARY_NODE" = "$MONGO_SELF" -a ! -f "$lock_file" ]; then

set -eu

for env in $(env); do
  key=${env%=*}
  [ -n "${key#*_FILE}" ] && continue
  val=${env#*=}
  key=${key%_FILE}
  val=$(cat $val)
  export "${key}"="${val}"
done

m_host=${MONGO_SELF%:*}
m_port=${MONGO_SELF#*:}

echo 'First time boot, wait all nodes...'
cluster_init=""
counter="0"
while [ -z "$cluster_init" ]; do

  for node in $MONGO_INIT_SECONDARY_NODES $MONGO_INIT_ARBITRATOR_NODES; do
    h=${node%:*}
    p=${node#*:}
    echo "Try $h:$p ... $counter/300"
    nc -z $h $p || continue
    cluster_init="true"
  done

  sleep 1

  counter=$((counter + 1))
  if [ "$counter" = "300" ]; then
    echo 'Mongo nodes isnt boot all... after 5 minutes'
    exit 1
  fi
done

echo 'Wait mongo...'

sleep 5

echo 'Setup replication...'

cat << EOF | mongo -u "root" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase "admin"
rs.initiate();
EOF

sleep 1

cat << EOF | mongo -u "root" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase "admin"
'$MONGO_INIT_SECONDARY_NODES'.split(' ').forEach(function(h) {
  rs.add(h);
});
EOF

sleep 1

if [ -n "$MONGO_INIT_ARBITRATOR_NODES" ]; then
cat << EOF | mongo -u "root" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase "admin"
'$MONGO_INIT_ARBITRATOR_NODES'.split(' ').forEach(function(h) {
  rs.add(h, true);
});
EOF
fi

sleep 1

cat << EOF | mongo -u "root" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase "admin"
rs.config();
rs.status();
EOF

touch $lock_file

fi
