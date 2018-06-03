#!/bin/bash


function run_ansible_play {
  set -ex
  limits=$1
  shift
  ansible-playbook -i ./hosts $* -l "$limits"
}

function run_ansible {
  set -ex
  limits=$1
  shift
  ansible -i ./hosts $* "$limits"
}

function show_help {
  echo 'Usage: cluster-cli.py [new,init,provision,provision-all,firewall,swarm,ssh,docker] {params}'
  exit 0
}

function call_new_node {
  call_init_node $*
  call_provision_new_node $*
}

function call_init_node {
  set -ex
  ip=$1
  hostname=$2
  [ -n "$(grep -F $ip ./hosts)" ] && echo 'This node already inited' && exit 0
  mkdir -p nodes
  HOSTS=./hosts KEYS=./nodes /bin/bash ./lib/init-node.sh $ip $hostname
}

function call_provision_new_node {
  hostname=$1
  shift
  run_ansible_play $hostname './playbook-bootstrap.yml' '--tags' 'bootstrap,docker' '-v' $*
}

function call_provision_all_new_nodes {
  hostname=docker_engine
  run_ansible_play $hostname './playbook-bootstrap.yml' '--tags' 'bootstrap,docker' '-v' $*
}

function call_firewall_nodes {
  run_ansible_play 'docker_engine,removed_nodes_from_cluster' './playbook-firewall.yml' '--tags' 'firewall' '-v'
}

function call_swarm_nodes {
  run_ansible_play 'node_roles,removed_nodes_from_cluster' './playbook-swarm.yml' '--tags' 'swarm' '-v'
}

function call_k8s_nodes {
  run_ansible_play 'kube_cluster,removed_nodes_from_cluster' './playbook-k8s.yml' '--tags' 'k8s' '-v'
}

function call_glusterfs_nodes {
  run_ansible_play 'docker_engine,removed_nodes_from_cluster' './playbook-glusterfs.yml' '--tags' 'glusterfs' '-v'
}

function call_ssh_node {
  node=$1
  shift
  config=$(cat hosts | grep -E "^$node [[:space:]]*ansible_ssh_host")
  if [ -z "$config" ]; then
    echo Node not found
    exit 1
  fi
  ssh $(echo $config | awk 'BEGIN { FS = "[ \t\n=]+" }{print $7"@"$3 " -p " $5 " -C -i " $9}') $*
}

function call_ssh_docker_tunnel {
  sock=$(pwd)/$1.docker.sock
  rm -f $sock
  echo Run in another shell:
  echo "  export DOCKER_HOST=unix://$sock"
  echo All docker requests are forwarded to the remote docker host
  echo Run tunnel
  call_ssh_node $* -N -L $sock:/var/run/docker.sock
  rm -f $sock
}

cmd=$1
shift
case $cmd in
  new)
    call_new_node $*
    ;;
  init)
    call_init_node $*
    ;;
  provision)
    call_provision_new_node $*
    ;;
  provision-all)
    call_provision_all_new_nodes $*
    ;;
  firewall)
    call_firewall_nodes $*
    ;;
  swarm)
    call_swarm_nodes $*
    ;;
  k8s)
    call_k8s_nodes $*
    ;;
  glusterfs)
    call_glusterfs_nodes $*
    ;;
  ssh)
    call_ssh_node $*
    ;;
  docker)
    call_ssh_docker_tunnel $*
    ;;
  *)
    [ -n "$1" ] && echo "Unknown command: $1"
    show_help
    ;;
esac
