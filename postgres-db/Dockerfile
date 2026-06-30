ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    postgresql16 \
    postgresql16-client

ENV PGDATA=/data/postgresql

COPY run.sh /
COPY init.sql /init.sql
RUN chmod a+x /run.sh

VOLUME ["/data"]

EXPOSE 5432

CMD ["/run.sh"]
