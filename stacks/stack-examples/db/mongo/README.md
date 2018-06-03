
How to Deploy before
---------------------

1. Run tunnel to one any manager node:
   `$ ./cluster-cli.sh docker node1`. Apply DOCKER_HOST env. in another terminal.
   This step make a tunnel conntection for your docker to the remote dockerd (manager node in swarm).
1. Change password in *mongo_admin_pass*



How to Deploy in single mode
----------------------------

1. `$ docker stack deploy --compose-file mongo-single-stack.yml project_name`



How to Deploy in HA mode
-------------------------

1. Specify special label *db.mongo* with *1,2,3,...a,...* value on each necessary nodes.
   One of case:
   1. Use docker CLI on necessary nodes: `$ docker node update node3 --label db.mongo=3`
   1. Use portainer (swarm menu item -> node -> Node labels -> Label).
1. `$ docker stack deploy --compose-file mongo-ha-stack.yml project_name`
