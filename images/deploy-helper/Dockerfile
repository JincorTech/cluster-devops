FROM docker:18 as docker_source

FROM python:2-alpine3.7

WORKDIR /usr/src/app
LABEL maintainer="Alexander Sedelnikov <alexander.sedelnikov@ymail.com>"

COPY --from=docker_source /usr/local/bin/docker /usr/local/bin/docker
COPY custom-entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod 755 /usr/local/bin/custom-entrypoint.sh && \
    pip install PyYAML==3.12 docker==3.3.0 jinja2==2.10 flask==1.0.2 jsonschema==2.6.0

COPY . .

EXPOSE 8000

CMD ["python", "web.py"]
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
