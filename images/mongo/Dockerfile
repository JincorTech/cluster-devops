FROM mongo:3.7

VOLUME /data/db /data/configdb
WORKDIR /

LABEL maintainer="Alexander Sedelnikov <alexander.sedelnikov@ymail.com>"

RUN apt-get update && \
    apt-get install -y netcat && \
    rm -rf /var/lib/apt/lists/*

COPY init-db.sh /docker-entrypoint-initdb.d/init-db.sh
COPY init-ha.sh .
COPY custom-entrypoint.sh /
RUN chmod oug+x /custom-entrypoint.sh

EXPOSE 27017

USER mongodb

CMD ["mongod"]
ENTRYPOINT ["/custom-entrypoint.sh"]
