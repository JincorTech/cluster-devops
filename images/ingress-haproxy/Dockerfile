#
# Go Builder
#
FROM golang:1.10-alpine as builder
WORKDIR /go/src
RUN apk add --update --no-cache git && go get github.com/kelseyhightower/confd/...

#
# Haproxy Image
#
FROM haproxy:1.8-alpine as image
WORKDIR /
LABEL maintainer="Alexander Sedelnikov <alexander.sedelnikov@ymail.com>"

COPY config.yml /usr/local/etc/haproxy/config.yml
COPY --from=builder /go/bin/confd /usr/local/bin/
COPY files/confd/ /etc/confd/
COPY files/scripts/entrypoint.sh /
RUN addgroup haproxy && adduser -D -H -G haproxy haproxy && \
    chown -R haproxy:haproxy usr/local/etc/haproxy && \
    chmod oug+x /entrypoint.sh

EXPOSE 8080 8443

USER haproxy

ENTRYPOINT  ["/entrypoint.sh"]
