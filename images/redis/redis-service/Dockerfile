FROM redis:4-alpine

VOLUME /data
WORKDIR /data

LABEL maintainer="Alexander Sedelnikov <alexander.sedelnikov@ymail.com>"

RUN apk add --update --no-cache bind-tools

COPY entrypoint.sh /
COPY redis.conf /etc/redis/redis.conf
RUN chmod oug+x /entrypoint.sh

USER redis

CMD ["redis-server"]

ENTRYPOINT ["/entrypoint.sh"]
