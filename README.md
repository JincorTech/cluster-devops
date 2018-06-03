Sandbox
---------

No need to use command `$ cluster-cli.sh init`

0. Use vagrant to raise up of virtual machines: `$ vagrant up --no-provision`.
1. Use hosts.sandbox `$ cp hosts.sandbox hosts`
2. Use only first step from Pre-request (tls for dockerd).
3. And start from **Provision all nodes** section



Pre-request
---------------

0. Need to generate tls env for dockerd. Fill fields by any values `$ cd files; sh tls-docker-generate.sh`.
1. On your localhost installed: latest Python 2, latest Docker, Ansible >= 2.4 `$ pip install ansible`
2. Each cluster node has private network with known ip
3. Configure hosts file, place nodes in related groups (config for each node: ssh, ip (best to be a private ip), maintainer_user, maintainer_group)



Init fresh node
-----------------

Init node (instead you can use terraform):

1. Create or Copy ssh keys
2. Add maintainer user (with default password maintainer)
3. Enable only ssh pub key login & change port to 16223 (default)
4. Update & Upgrade packages
5. Set up hostname and ansible inventory file
6. Restart

`$ ./cluster-cli.sh init IP NODENAME`

NODENAME should be unique in the cluster.



Provision all nodes
---------------------

`$ ./cluster-cli.sh provision-all`

1. Install utils
1. Base configure ufw
1. Install docker, docker-compose



Autoconfigure firewall
-------------------------

`$ ./cluster-cli.sh firewall`

1. Allow traffic between nodes in private network
1. Specify hostname and related ip in hosts on all nodes



Autoconfigure swarm mode
-------------------------

`$ ./cluster-cli.sh swarm`

1. Init and join manager nodes
1. Init and join worker nodes



Connect to node through ssh
------------------------------

`$ ./cluster-cli.sh ssh NODENAME`



Make tunnel to remote Dockerd
-------------------------------

`$ ./cluster-cli.sh docker NODENAME`

Apply DOCKER_HOST env variable, and use remote docker on your localhost



Cases
------

1. Add new swarm node
   1. Init node by `$ ./cluster-cli.sh init IP NODENAME`
   1. Execute `$ ./cluster-cli.sh provision NODENAME`
   1. Execute `$ ./cluster-cli.sh firewall`
   1. Execute `$ ./cluster-cli.sh swarm`


1. Remove swarm node
   1. Try to stop / disable / remove services (maybe need to move special service data to the another node(s)).
   1. Remove swarm node from cluster by executing `$ docker swarm leave --force` on the node who need to remove from cluster.
   1. Add removed node to the group [removed_nodes_from_cluster] in the hosts file.
   1. Execute `$ ./cluster-cli.sh firewall`

1. Deploy one of Redis/Mongo in HA/FT mode you should specify labels for nodes:
   1. For redis `$ docker node update node_name.... --label-add com.secrettech.db.redis.index=#` (#=1,2,3) 3 node are need
   1. For mongo `$ docker node update node_name.... --label-add com.secrettech.db.mongo.index=#` (#=1,2,3) 3 node are need


What's next
------------

Use stacks folder.

1. portainer (to control swarm cluster through ui)
1. ingress-proxy (to have access services by url (host, path))
1. deploy-helper (to simplify stacks (redis, mongo, auth/verify, applications) deployments)
1. stack-examples (standalone stack examples)
