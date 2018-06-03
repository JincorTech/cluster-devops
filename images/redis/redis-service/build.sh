docker build -t alekns/redis-service:latest .
[ "$1" = 'push' ] && docker push alekns/redis-service:latest
