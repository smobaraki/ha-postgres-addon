ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk update && apk add --no-cache \
    --repository=https://dl-cdn.alpinelinux.org/alpine/v3.21/community \
    --repository=https://dl-cdn.alpinelinux.org/alpine/v3.20/community \
    --repository=https://dl-cdn.alpinelinux.org/alpine/v3.19/community \
    postgresql16 \
    postgresql16-client

RUN mkdir -p /var/lib/postgresql /run/postgresql && \
    chown postgres:postgres /var/lib/postgresql /run/postgresql

ENV PGDATA=/data/postgresql

COPY run.sh /
COPY init.sql /init.sql
RUN chmod a+x /run.sh

EXPOSE 5432
CMD ["/run.sh"]
