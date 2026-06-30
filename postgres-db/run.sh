#!/bin/bash
set -e

OPTIONS=/data/options.json

DATABASE=$(jq -r '.database' "$OPTIONS")
USERNAME=$(jq -r '.username' "$OPTIONS")
PASSWORD=$(jq -r '.password' "$OPTIONS")
POSTGRES_PASSWORD=$(jq -r '.postgres_password' "$OPTIONS")
EXTERNAL_ACCESS=$(jq -r '.external_access' "$OPTIONS")
EXTERNAL_SUBNET=$(jq -r '.external_subnet' "$OPTIONS")
MAX_CONNECTIONS=$(jq -r '.max_connections' "$OPTIONS")
SHARED_BUFFERS=$(jq -r '.shared_buffers' "$OPTIONS")

PGDATA="/data/postgresql"
export PGDATA
export PATH="/usr/bin:$PATH"

echo "[postgres] Starting..."

if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "[postgres] Initializing data directory..."
    mkdir -p "$PGDATA"
    chown postgres:postgres "$PGDATA"
    su postgres -c "initdb -D \"$PGDATA\""
fi

echo "[postgres] Writing postgresql.conf..."
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

echo "[postgres] Writing pg_hba.conf..."
if [ "$EXTERNAL_ACCESS" = "true" ]; then
    echo "[postgres] External access enabled — subnet: ${EXTERNAL_SUBNET}"
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

chown -R postgres:postgres "$PGDATA"

echo "[postgres] Starting PostgreSQL..."
su postgres -c "pg_ctl -D \"$PGDATA\" -l \"$PGDATA/logfile\" start"

sleep 2

echo "[postgres] Setting up users..."
su postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';\""

su postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${USERNAME}'\"" | grep -q 1 || \
    su postgres -c "psql -c \"CREATE USER ${USERNAME} WITH PASSWORD '${PASSWORD}';\""

su postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${DATABASE}'\"" | grep -q 1 || {
    su postgres -c "psql -c \"CREATE DATABASE ${DATABASE} OWNER ${USERNAME};\""
    su postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${DATABASE} TO ${USERNAME};\""
}

su postgres -c "psql -d ${DATABASE} -c \"GRANT ALL ON SCHEMA public TO ${USERNAME};\""

echo "[postgres] Running init.sql..."
su postgres -c "psql -d ${DATABASE} -f /init.sql" || true

echo "[postgres] Granting table privileges and ownership to ${USERNAME}..."
su postgres -c "psql -d ${DATABASE}" <<SQL
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${USERNAME};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${USERNAME};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${USERNAME};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${USERNAME};
ALTER DEFAULT PRIVILEGES FOR ROLE ${USERNAME} IN SCHEMA public GRANT ALL ON TABLES TO ${USERNAME};
ALTER DEFAULT PRIVILEGES FOR ROLE ${USERNAME} IN SCHEMA public GRANT ALL ON SEQUENCES TO ${USERNAME};
DO \$\$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname='public' AND tableowner='postgres' LOOP
    EXECUTE 'ALTER TABLE ' || quote_ident(r.tablename) || ' OWNER TO ${USERNAME}';
  END LOOP;
  FOR r IN SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema='public' LOOP
    EXECUTE 'ALTER SEQUENCE ' || quote_ident(r.sequence_name) || ' OWNER TO ${USERNAME}';
  END LOOP;
END
\$\$;
SQL

echo "==================================="
echo "PostgreSQL is ready"
echo "Database: ${DATABASE}"
echo "Username: ${USERNAME}"
echo "==================================="

tail -f "$PGDATA/logfile"
