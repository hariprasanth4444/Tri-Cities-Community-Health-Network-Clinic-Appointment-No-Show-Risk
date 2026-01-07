-- Appendix — SQL (DDL, View, and Analysis Queries)

CREATE OR REPLACE TABLE clinic_ops.appointments AS
SELECT
  appt_id,
  DATE(date) AS dt,
  TIME(time) AS appt_time,
  UPPER(city) AS city,
  clinic,
  zip,
  visit_type,
  new_or_return,
  DATE(booked_date) AS booked_dt,
  status
FROM clinic_ops.appointments_staging;

CREATE OR REPLACE TABLE clinic_ops.weather AS
SELECT DATE(dt) AS dt, UPPER(city) AS city, tmax_c, tmin_c, prcp_mm
FROM clinic_ops.weather_staging;

CREATE OR REPLACE TABLE clinic_ops.twitter AS
SELECT DATE(dt) AS dt, UPPER(city) AS city, tweet_count_symptoms, sentiment_avg
FROM clinic_ops.twitter_staging;

CREATE OR REPLACE TABLE clinic_ops.zip_city AS
SELECT zip, UPPER(city) AS city
FROM clinic_ops.zip_city_staging;

CREATE OR REPLACE VIEW clinic_ops.fact_day AS
WITH base AS (
  SELECT
    a.dt, a.city, a.clinic, a.visit_type,
    IF(LOWER(a.new_or_return)='new', 1, 0) AS is_new_patient,
    IF(LOWER(a.status)='no_show', 1, 0) AS no_show,
    TIMESTAMP_DIFF(TIMESTAMP(a.dt, a.appt_time), TIMESTAMP(a.booked_dt, TIME '00:00:00'), DAY) AS lead_time_days,
    CASE
      WHEN EXTRACT(HOUR FROM a.appt_time) BETWEEN 7 AND 11 THEN 'AM'
      WHEN EXTRACT(HOUR FROM a.appt_time) BETWEEN 12 AND 16 THEN 'PM'
      ELSE 'Late'
    END AS hour_bucket
  FROM clinic_ops.appointments a
)
SELECT
  b.*,
  w.tmax_c, w.tmin_c, w.prcp_mm,
  CASE WHEN w.prcp_mm > 0 THEN 1 ELSE 0 END AS rain_flag,
  CASE WHEN w.tmax_c >= 30 THEN 'Hot' WHEN w.tmax_c <= 5 THEN 'Cold' ELSE 'Mild' END AS temp_bucket,
  t.tweet_count_symptoms, t.sentiment_avg
FROM base b
LEFT JOIN clinic_ops.weather w USING (dt, city)
LEFT JOIN clinic_ops.twitter t USING (dt, city);

-- Lead time
SELECT
  CASE
    WHEN lead_time_days <= 2 THEN '0-2'
    WHEN lead_time_days <= 7 THEN '3-7'
    ELSE '8+'
  END AS lead_bucket,
  ROUND(AVG(no_show) * 100, 1) AS no_show_rate_pct,
  COUNT(*) AS n
FROM clinic_ops.fact_day
GROUP BY lead_bucket
ORDER BY lead_bucket;

-- Weather × time
SELECT
  temp_bucket, hour_bucket,
  ROUND(AVG(no_show) * 100, 1) AS no_show_rate_pct,
  COUNT(*) AS n
FROM clinic_ops.fact_day
GROUP BY temp_bucket, hour_bucket
ORDER BY temp_bucket, hour_bucket;

-- Chatter (global 75th percentile)
WITH with_bucket AS (
  SELECT
    *,
    CASE
      WHEN tweet_count_symptoms >= PERCENTILE_CONT(tweet_count_symptoms, 0.75) OVER() THEN 'High'
      ELSE 'Normal'
    END AS chatter_bucket
  FROM clinic_ops.fact_day
)
SELECT chatter_bucket,
       ROUND(AVG(no_show) * 100, 1) AS no_show_rate_pct,
       COUNT(*) AS n
FROM with_bucket
GROUP BY chatter_bucket
ORDER BY chatter_bucket;

-- Top segments (>=20 rows)
SELECT
  clinic, visit_type, hour_bucket, temp_bucket,
  ROUND(AVG(no_show) * 100, 1) AS no_show_rate_pct,
  COUNT(*) AS n
FROM clinic_ops.fact_day
GROUP BY clinic, visit_type, hour_bucket, temp_bucket
HAVING COUNT(*) >= 20
ORDER BY no_show_rate_pct DESC
LIMIT 15;
