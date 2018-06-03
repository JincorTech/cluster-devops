docker build -t alekns/ingress-haproxy:latest .
[ "$1" = 'push' ] && docker push alekns/ingress-haproxy:latest
