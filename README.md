# PostgreSQL Addon for Home Assistant

Self-hosted PostgreSQL database that persists data and is reachable from:

- **Other HA addons** via `postgres_db:5432` (internal Docker network)
- **External services** (e.g. Next.js on AWS Amplify) via router port-forwarding

## Installation

```bash
# Place this folder in your Home Assistant addons directory:
# /addons/postgres-addon/
# Then install via Supervisor → Add-on Store → Local add-ons
```

## Configuration

| Option             | Default        | Description                                                |
|--------------------|----------------|------------------------------------------------------------|
| `database`         | `garmin_sync`  | Database name                                              |
| `username`         | `garmin_user`  | Database user                                              |
| `password`         | `""`           | Password for the application user                          |
| `postgres_password`| `""`           | Password for the `postgres` superuser                      |
| `external_access`  | `false`        | Enable remote connections from the internet                |
| `external_subnet`  | `0.0.0.0/0`   | Allowed external subnet (when `external_access` is true)   |
| `max_connections`  | `100`          | Maximum concurrent connections                             |
| `shared_buffers`   | `128MB`        | PostgreSQL shared buffer size                              |

## Connecting from HA Addons (e.g. Garmin Sync)

Use the addon slug as hostname:

```
Host:     postgres_db
Port:     5432
Database: garmin_sync
User:     garmin_user
Password: <your configured password>
```

## Connecting from External Services (e.g. AWS Amplify / Next.js)

### 1. Enable external access in addon config

```yaml
external_access: true
external_subnet: "0.0.0.0/0"   # or restrict to specific IPs
```

### 2. Port-forward on your router

Forward port `5432` (TCP) from your router to your Raspberry Pi's IP address.

### 3. Connect from your application

```env
DATABASE_URL=postgresql://garmin_user:<password>@<your-public-ip>:5432/garmin_sync
```

For production, consider using Cloudflare Tunnel or Tailscale for secure remote access instead of exposing the port directly.

## Data Persistence

All PostgreSQL data lives in `/data/postgresql` which is mapped to the HA `share` folder and survives addon restarts and reinstalls.

## Initial Tables

The addon pre-creates three tables ready for Garmin Sync data:

- `garmin_activities` — runs, rides, swims etc.
- `garmin_daily_health` — steps, HR, stress, sleep, body battery
- `garmin_weight` — weight, BMI, body fat, muscle/bone mass
