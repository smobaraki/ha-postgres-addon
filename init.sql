-- Garmin Sync — aktiviteter
CREATE TABLE IF NOT EXISTS garmin_activities (
    id              SERIAL PRIMARY KEY,
    activity_id     BIGINT UNIQUE NOT NULL,
    activity_type   VARCHAR(50),
    name            VARCHAR(255),
    start_time      TIMESTAMPTZ,
    duration_sec    INTEGER,
    distance_m      DOUBLE PRECISION,
    avg_hr          INTEGER,
    max_hr          INTEGER,
    calories        INTEGER,
    elevation_gain  DOUBLE PRECISION,
    created_at      TIMESTAMPTZ DEFAULT now()
);

-- Garmin Sync — daglig helse (steps, hr, sleep osv.)
CREATE TABLE IF NOT EXISTS garmin_daily_health (
    id              SERIAL PRIMARY KEY,
    date            DATE NOT NULL,
    steps           INTEGER,
    resting_hr      INTEGER,
    avg_stress      INTEGER,
    sleep_duration  INTEGER,
    sleep_quality   VARCHAR(20),
    body_battery_low  INTEGER,
    body_battery_high INTEGER,
    UNIQUE(date)
);

-- Garmin Sync — vekt og kroppsdata
CREATE TABLE IF NOT EXISTS garmin_weight (
    id              SERIAL PRIMARY KEY,
    date            TIMESTAMPTZ NOT NULL,
    weight_kg       DOUBLE PRECISION,
    bmi             DOUBLE PRECISION,
    body_fat_pct    DOUBLE PRECISION,
    muscle_mass_kg  DOUBLE PRECISION,
    bone_mass_kg    DOUBLE PRECISION,
    body_water_pct  DOUBLE PRECISION,
    UNIQUE(date)
);
