docker build -t alekns/redis-sentinel:latest .
[ "$1" = 'push' ] && docker push alekns/redis-sentinel:latest
