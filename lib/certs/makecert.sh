#!/bin/sh

set -e

expire=${EXPIRE:-3650}

make_cnf()  {
  echo 'subjectAltName = DNS:IP:127.0.0.1' > extfile.cnf
  echo extendedKeyUsage = serverAuth >> extfile.cnf
}

make_ca()  {
  fn=$1
  [ -z "$fn" ] && echo 'No file name was specified' && exit 1
  openssl genrsa -aes256 -out ca-key.pem 4096
  openssl req -new -x509 -days $expire -key ca-key.pem -sha256 -out ca.pem
  make_cnf
  echo 'Done!'
}

make_serv()  {
  make_cnf
  fn=$1
  cn=$2
  [ -z "$fn" ] && echo 'No file name was specified' && exit 1
  [ -z "$cn" ] && echo 'No common name was specified' && exit 1
  openssl genrsa -out $fn-key.pem 4096
  openssl req -subj "/CN=$cn" -sha256 -new -key $fn-key.pem -out $fn.csr
  openssl x509 -req -days $expire -sha256 -in $fn.csr -CA ca.pem -CAkey ca-key.pem \
    -CAcreateserial -out $fn-cert.pem -extfile extfile.cnf
  cat $fn-cert.pem $fn-key.pem > $fn.pem
  echo 'Done!'
}

make_client() {
  fn=$1
  cn=$2
  [ -z "$fn" ] && echo 'No file name was specified' && exit 1
  [ -z "$cn" ] && echo 'No common name was specified' && exit 1
  make_cnf
  openssl genrsa -out $fn-key.pem 4096
  openssl req -subj "/CN=$cn" -new -key $fn-key.pem -out $fn.csr
  echo extendedKeyUsage = clientAuth >> extfile.cnf
  openssl x509 -req -days $expire -sha256 -in $fn.csr -CA ca.pem -CAkey ca-key.pem \
    -CAcreateserial -out $fn-cert.pem -extfile extfile.cnf
  cat $fn-cert.pem $fn-key.pem > $fn.pem
  openssl pkcs12 -export -out $fn.pfx -inkey $fn-key.pem -in $fn-cert.pem
  echo 'Done!'
}

case "$1" in
  ca)
    make_ca $2
    ;;
  server)
    [ -z "$2" ] && echo 'Empty name!' && exit 1
    make_serv $2 $3
    ;;
  client)
    [ -z "$2" ] && echo 'Empty name!' && exit 1
    make_client $2 $3
    ;;
  *)
    echo 'Use: script ca|server|client out_file_name cname_for_client_or_server'
esac
