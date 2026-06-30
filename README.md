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

## Database Schema (from garmin-health-data)

The addon runs the full `tables_postgres.ddl` from [garmin-health-data](https://github.com/tcgoetz/garmin-health-data) on first start, creating the complete schema:

**Identity & Profiles**
- `user` — user identity and demographics
- `user_profile` — fitness metrics, VO2 max, physical characteristics

**Activities**
- `activity` — all activity types with core metrics (HR, speed, distance, calories, training effect etc.)
- `swimming_agg_metrics` — stroke data, SWOLF, pool info
- `cycling_agg_metrics` — power zones, TSS, cadence, elevation, temperature
- `running_agg_metrics` — running form, cadence, power, stride length
- `supplemental_activity_metric` — flexible key-value metrics
- `activity_ts_metric` — per-second time-series data from FIT files
- `activity_ts_metric_downsampled` — time-bucketed aggregates for long-term retention
- `activity_split_metric` — Garmin algorithmic split segments
- `activity_lap_metric` — device-triggered lap segments
- `activity_path` — GPS path as JSONB for map visualization

**Strength Training**
- `strength_exercise` — per-exercise aggregates (sets, reps, volume, weight)
- `strength_set` — per-set granular data (ACTIVE, REST, WARMUP etc.)

**Sleep**
- `sleep` — comprehensive sleep sessions with scores, stages, SpO2, HRV, respiration
- `sleep_level` — sleep stage intervals (Deep, Light, REM, Awake)
- `sleep_movement` — 1-minute movement intervals
- `sleep_restless_moment` — restless event timestamps
- `spo2` — 1-minute SpO2 readings during sleep
- `hrv` — 5-minute HRV readings during sleep
- `breathing_disruption` — breathing event severities during sleep

**Wellness Timeseries**
- `stress` — 3-minute stress levels (0-100)
- `body_battery` — 3-minute body battery levels (0-100)
- `heart_rate` — 2-minute heart rate (BPM)
- `steps` — 15-minute step counts with activity level
- `respiration` — 2-minute respiration rate (breaths/min)
- `intensity_minutes` — 15-minute moderate/vigorous activity
- `floors` — 15-minute floors ascended/descended

**Body Composition**
- `body_composition` — smart scale weigh-ins (weight, BMI, body fat, muscle, bone mass)

**Training Status**
- `vo2_max` — generic and cycling VO2 max
- `acclimation` — heat and altitude acclimation
- `training_load` — monthly load balance, ACWR, training status
- `training_readiness` — readiness score, recovery time, HRV status
- `race_predictions` — 5K/10K/half/full marathon predictions
- `personal_record` — personal bests across distances

**Menstrual Cycle**
- `menstrual_cycle_day` — per-day cycle state and user logs
- `menstrual_cycle_tag` — symptoms, moods, discharge tags
- `menstrual_cycle_summary` — per-cycle summaries (logged + predicted)

---

Schema source: `tables_postgres.ddl` from [tcgoetz/garmin-health-data](https://github.com/tcgoetz/garmin-health-data)
