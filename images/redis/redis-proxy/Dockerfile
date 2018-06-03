FROM haproxy:1.8-alpine

WORKDIR /

LABEL maintainer="Alexander Sedelnikov <alexander.sedelnikov@ymail.com>"

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg.tmpl
COPY entrypoint.sh /
RUN addgroup haproxy && adduser -D -H -G haproxy haproxy && \
    chown -R haproxy:haproxy usr/local/etc/haproxy && \
    chmod oug+x /entrypoint.sh

USER haproxy

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]

ENTRYPOINT ["/entrypoint.sh"]
