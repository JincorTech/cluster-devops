docker build -t alekns/redis-proxy:latest .
[ "$1" = 'push' ] && docker push alekns/redis-proxy:latest