
How to Deploy Traefik
---------------------

1. Run tunnel to one any manager node:
   `$ ./cluster-cli.sh docker node1`. Apply DOCKER_HOST env. in another terminal.
   This step make a tunnel conntection for your docker to the remote dockerd (manager node in swarm).
1. `$ docker stack deploy --compose-file traefik-stack.yml global_ingress`

For stats you should recreate your own certs, for secure reasons (use lib/certs/makecert.sh).
You need import signed certificate from data/accesscerts/stats-client.pfx into your browser for access statisitcs.


How to Deploy HAProxy
---------------------

** Not for production. **

1. Change user / password in empty-config.yml (optional)
1. Specify special label *global.ingress* with *haproxy* value on necessary nodes.
   One of case:
   1. Use docker CLI on necessary nodes: `$ docker node update node3 --label-add global.ingress=haproxy`
   1. Use portainer (swarm menu item -> node -> Node labels -> Label).
1. Run tunnel to one any manager node:
   `$ ./cluster-cli.sh docker node1`. Apply DOCKER_HOST env. in another terminal.
   This step make a tunnel conntection for your docker to the remote dockerd (manager node in swarm).
1. `$ docker stack deploy --compose-file haproxy-stack.yml global_ingress`

For stats you should recreate your own certs, for secure reasons (use lib/certs/makecert.sh).
You need import signed certificate from data/accesscerts/stats-client.pfx into your browser for access statisitcs.
