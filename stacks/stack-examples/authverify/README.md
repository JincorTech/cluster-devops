How to Deploy
---------------

Let node1 is managed node in swarm.

1. Run tunnel to one any manager node:
   `$ ./cluster-cli.sh docker node1`. Apply DOCKER_HOST env. in another terminal.
   This step make a tunnel conntection for your docker to the remote dockerd (manager node in swarm).
1. Setup *redis* network in the auth-verify-stack.yml
1. Deploy auth & verify services: `$ docker stack deploy --compose-file auth-verify-stack.yml project_name`
1. Close terminal with docker ssh tunnel. (optional)
