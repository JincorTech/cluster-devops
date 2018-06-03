docker build -t alekns/deploy-helper:latest .
[ "$1" = 'push' ] && docker push alekns/deploy-helper:latest

docker build -t alekns/deploy-ah-helper:latest -f Dockerfile.Authverify .
[ "$1" = 'push' ] && docker push alekns/deploy-ah-helper:latest
