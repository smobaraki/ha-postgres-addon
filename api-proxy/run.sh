#!/usr/bin/env bash
set -euo pipefail

OPTIONS=/data/options.json

DB_URL=$(jq -r '.database_url // empty' "$OPTIONS")
API_KEY=$(jq -r '.api_key // empty' "$OPTIONS")

export DATABASE_URL="$DB_URL"
export API_KEY="$API_KEY"

echo "=== PostgreSQL API Proxy ==="
echo "Port: 5000"
echo "DB: ${DATABASE_URL%%@*}@***"

exec node /app/server.js
