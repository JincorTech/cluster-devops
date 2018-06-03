#!/bin/bash
#
# Init node (instead you can use terraform):
# 1) Create or Copy ssh keys
# 2) Add maintainer user (with default password maintainer)
# 3) Enable only ssh pub key login & change port to 16223 (default)
# 4) Set up hostname and ansible inventory file
# 5) Restart
#
set -x

hosts_file=${HOSTS:-./hosts}
keys_folder=${KEYS:-./keys}
ssh_port=${SSH_PORT:-16223}

echo 'Usage: initnode.sh host_ip hostname {master=.ssh/master.pub?} {maintainer=.ssh/common.pub?}'
[ -z "$1" ] && echo 'Specify ip to connect' && exit
[ -z "$2" ] && echo 'Specify host name' && exit

host_ip=$1
hostname=$2
shift 2

function make_key {
  key_name=$1
  pubkey_file=$2

  mkdir -p $keys_folder/$hostname

  if [ -n "$pubkey_file" ]; then
    if [ -f "$pubkey_file" ]; then
      sshpubkey=$(cat $pubkey_file)
    else
      echo $key_name key [$pubkey_file] is not found!
      exit 1
    fi
  else
    ssh-keygen -b 256 -ted25519 -a 20480 -C $key_name@$hostname -f $keys_folder/$hostname/$key_name
    sshpubkey=$(cat $keys_folder/$hostname/$key_name.pub)
  fi
}

maintainer_pubkey_file=
master_pubkey_file=

script_arg=$1

while [ -n "$script_arg" ]; do
  arg=${script_arg%=*}
  val=${script_arg#*=}

  if [ -z "$val" ]; then
    echo Argument cannot be empty for $script_arg
  fi

  case $arg in
    master)
      master_pubkey_file=$val
      ;;
    maintainer)
      maintainer_pubkey_file=$val
      ;;
    *)
      echo 'Unknown arg:' $script_arg
      exit 1
      ;;
  esac
  shift
  script_arg=$1
done

sshmasterpubkey=
sshmaintainerpubkey=

function get_keys {
  make_key master $master_pubkey_file
  sshmasterpubkey=$sshpubkey

  make_key maintainer $maintainer_pubkey_file
  sshmaintainerpubkey=$sshpubkey
}

function init_node {
 ssh-keygen -f "$HOME/.ssh/known_hosts" -R $host_ip
 maintainer_password=$(openssl passwd -1 maintainer)
 ssh root@$host_ip "
  mkdir .ssh                                                                            && \
  chmod -R og-rwx /root                                                                 && \
  echo $sshmasterpubkey > .ssh/authorized_keys                                          && \
  useradd -d '/home/maintainer' -s '/bin/bash' -p '$maintainer_password' -m -U -G adm,sudo maintainer && \
  cp -r .ssh/ /home/maintainer/.ssh                                                     && \
  chown -R maintainer:maintainer /home/maintainer/.ssh                                  && \
  echo $sshmaintainerpubkey > /home/maintainer/.ssh/authorized_keys                     && \
  sed -i -r 's/#?PasswordAuthentication .+/PasswordAuthentication no/' /etc/ssh/sshd_config && \
  sed -i -r 's/#?Port .+/Port $ssh_port/' /etc/ssh/sshd_config && \
  echo $hostname > /etc/hostname                                                        && \
  echo 127.0.0.1    $hostname >> /etc/hosts                                             && \
  reboot
"
  echo '=== You need to change default passwords for root and maintainer users! ==='
  inv_content="$hostname    ansible_ssh_host=$host_ip ansible_ssh_port=$ssh_port ansible_ssh_user=maintainer ansible_ssh_private_key_file=${keys_folder}/${hostname}/maintainer\n"
  sed -i "1s;^;$inv_content;" $hosts_file
}

get_keys
init_node

echo Done!
