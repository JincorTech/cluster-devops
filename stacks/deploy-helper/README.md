
How to Deploy
---------------

Let node1 is managed node in swarm.

1. Run tunnel to one any manager node:
   `$ ./cluster-cli.sh docker node1`. Apply DOCKER_HOST env. in another terminal.
   This step make a tunnel conntection for your docker to the remote dockerd (manager node in swarm).
1. Deploy "deploy-helper": `$ docker stack deploy --compose-file deploy-helper-stack.yml global_deployhelper`
1. Close terminal with docker ssh tunnel. (optional)

Wait a little bit. Deploy helper will be available on any node of your cluster by 39041 port.
You should generate your own tls env (use lib/certs/makecert.sh).
TLS: You need import signed certificate from haproxy/accesscerts/client.pfx into your browser to access the deploy helper
or use client-cert.pem and client-key.pem in your application (curl for an example).



To setup FT redis for necessary nodes setup (on any docker swarm manager node):

1. `$ docker node update node.... --label-add com.secrettech.db.redis.index=#` (#=1,2,3)


To setup FT mongo for necessary nodes setup (on any docker swarm manager node):

1. `$ docker node update node.... --label-add com.secrettech.db.mongo.index=#` (#=1,2,3)
