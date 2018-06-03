FROM redis:4-alpine

VOLUME /data
WORKDIR /data

LABEL maintainer="Alexander Sedelnikov <alexander.sedelnikov@ymail.com>"

RUN apk add --update --no-cache bind-tools

ENV SENTINEL_QUORUM 2
ENV SENTINEL_DOWN_AFTER 5000
ENV SENTINEL_FAILOVER 10000
ENV SENTINEL_PORT 26000


COPY entrypoint.sh /
COPY sentinel.conf /etc/sentinel/sentinel.conf
RUN chmod oug+x /entrypoint.sh && \
    chmod og+w /etc/sentinel/sentinel.conf && \
    chown -R redis:redis /etc/sentinel

USER redis

CMD ["redis-server"]

ENTRYPOINT ["/entrypoint.sh"]
