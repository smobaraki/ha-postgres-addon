#!/usr/bin/with-contenv bashio

set -e

DATABASE=$(bashio::config 'database')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
POSTGRES_PASSWORD=$(bashio::config 'postgres_password')
EXTERNAL_ACCESS=$(bashio::config 'external_access')
EXTERNAL_SUBNET=$(bashio::config 'external_subnet')
MAX_CONNECTIONS=$(bashio::config 'max_connections')
SHARED_BUFFERS=$(bashio::config 'shared_buffers')

PGDATA="/data/postgresql"

if [ ! -d "$PGDATA" ]; then
    bashio::log.info "Initializing PostgreSQL data directory..."
    mkdir -p "$PGDATA"
    chown postgres:postgres "$PGDATA"
    su - postgres -c "initdb -D $PGDATA"
fi

bashio::log.info "Configuring postgresql.conf..."
cat > "$PGDATA/postgresql.conf" <<EOF
listen_addresses = '*'
port = 5432
max_connections = ${MAX_CONNECTIONS}
shared_buffers = ${SHARED_BUFFERS}
dynamic_shared_memory_type = posix
wal_level = replica
max_wal_senders = 0
log_timezone = 'UTC'
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'
EOF

bashio::log.info "Configuring pg_hba.conf..."
if bashio::var.true "$EXTERNAL_ACCESS"; then
    bashio::log.info "External access enabled — allowing connections from ${EXTERNAL_SUBNET}"
    cat > "$PGDATA/pg_hba.conf" <<EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             172.30.0.0/16           md5
host    all             all             ${EXTERNAL_SUBNET}      scram-sha-256
EOF
else
    cat > "$PGDATA/pg_hba.conf" <<EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             172.30.0.0/16           md5
EOF
fi

bashio::log.info "Starting PostgreSQL..."
su - postgres -c "pg_ctl -D $PGDATA -l $PGDATA/logfile start"

sleep 2

bashio::log.info "Configuring database and users..."

su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';\""

if ! su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${USERNAME}'\"" | grep -q 1; then
    su - postgres -c "psql -c \"CREATE USER ${USERNAME} WITH PASSWORD '${PASSWORD}';\""
fi

if ! su - postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${DATABASE}'\"" | grep -q 1; then
    su - postgres -c "psql -c \"CREATE DATABASE ${DATABASE} OWNER ${USERNAME};\""
    su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${DATABASE} TO ${USERNAME};\""
fi

su - postgres -c "psql -d ${DATABASE} -c \"GRANT ALL ON SCHEMA public TO ${USERNAME};\""

bashio::log.info "Running init.sql..."
su - postgres -c "psql -d ${DATABASE} -f /init.sql" || true

bashio::log.info "PostgreSQL is ready."
bashio::log.info "Database: ${DATABASE}"
bashio::log.info "Username: ${USERNAME}"

tail -f "$PGDATA/logfile"
