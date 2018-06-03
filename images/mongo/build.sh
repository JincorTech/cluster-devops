docker build -t alekns/mongo-service:latest .
[ "$1" = 'push' ] && docker push alekns/mongo-service:latest