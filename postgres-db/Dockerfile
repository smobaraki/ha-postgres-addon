ARG BUILD_ARCH
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base:3.21

RUN apk add --no-cache \
    --repository=https://dl-cdn.alpinelinux.org/alpine/v3.21/community \
    postgresql16 \
    postgresql16-client \
    jq

RUN mkdir -p /var/lib/postgresql /run/postgresql && \
    chown postgres:postgres /var/lib/postgresql /run/postgresql

ENV PGDATA=/data/postgresql

COPY run.sh /
COPY init.sql /init.sql
RUN chmod a+x /run.sh

EXPOSE 5432
ENTRYPOINT []
CMD ["/run.sh"]
