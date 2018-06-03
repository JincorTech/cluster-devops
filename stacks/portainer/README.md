
How to Deploy
---------------

Let node1 is managed node in swarm.

1. Create portainer data folder on manager node(s):
   `$ ./cluster-cli.sh ssh node1 sudo mkdir -p /var/local/portainer/data`
1. Run tunnel to one any manager node:
   `$ ./cluster-cli.sh docker node1`. Apply DOCKER_HOST env. in another terminal.
   This step make a tunnel conntection for your docker to the remote dockerd (manager node in swarm).
1. Change admin password in ./portainer_admin_pass (or you can change it in the admin account after login).
1. Deploy portainer: `$ docker stack deploy --compose-file portainer-stack.yml global_portainer`
1. Close terminal with docker ssh tunnel. (optional)

Wait a little bit. Portainer will be available on any node of your cluster by 39040 port.
You should generate your own tls env (use lib/certs/makecert.sh).
You need import signed certificate from data/accesscerts/control-client.pfx into your browser to access the portainer.
