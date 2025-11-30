-- Generate analytics-focused mock data for TimeBeam
-- Creates 35 days of session records ending today that demonstrate:
-- 1. A 35+ day productive streak (every day has ≥1 WORK session)
-- 2. Clear peak productivity hours (9-11 AM and 2-4 PM)
--
-- Assumptions:
-- * PostgreSQL with pgcrypto extension
-- * Table `session_records` exists with columns: id (uuid), user_id (uuid), started_at (timestamptz), duration_seconds (integer), kind (string)
-- * Uses same user_id as existing scripts for consistency

SET TIME ZONE 'UTC';

-- Create pgcrypto if missing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  -- Configuration
  d date := CURRENT_DATE - INTERVAL '34 days';  -- Start 34 days ago to get 35 days total
  endd date := CURRENT_DATE;                    -- End today
  user_uuid uuid := '67546cba-5ba0-4b83-84bf-5906af7b2708';

  -- Session parameters
  work_seconds int := 1500;    -- 25 minutes work
  short_break int := 300;      -- 5 minutes break
  long_break int := 900;       -- 15 minutes break

  -- Peak hour configuration (hours where most sessions occur)
  morning_peak_start int := 9;   -- 9 AM
  morning_peak_end int := 11;    -- 11 AM
  afternoon_peak_start int := 14; -- 2 PM
  afternoon_peak_end int := 16;   -- 4 PM

  -- Variables
  s timestamptz;
  session_count int;
  hour_of_day int;
  is_peak_hour boolean;
  kind_text text;

BEGIN
  -- Safety check
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = current_schema() AND table_name = 'session_records'
  ) THEN
    RAISE WARNING 'Table session_records does not exist; nothing inserted.';
    RETURN;
  END IF;

  RAISE NOTICE 'Generating analytics demo data from % to %', d, endd;

  WHILE d <= endd LOOP
    -- Every day gets at least 1 WORK session to maintain streak
    -- Plus additional sessions based on peak hours

    -- Morning peak: 9-11 AM (most productive)
    session_count := 0;
    FOR hour_of_day IN morning_peak_start..morning_peak_end LOOP
      -- 60-80% chance of session in peak hours
      IF random() < 0.7 THEN
        s := (d::timestamp + make_interval(hours => hour_of_day, mins => (random() * 59)::int))::timestamptz;

        -- Insert WORK session
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');

        session_count := session_count + 1;

        -- Sometimes add a break after work
        IF random() < 0.3 THEN
          s := s + make_interval(secs => work_seconds);
          kind_text := CASE WHEN random() < 0.5 THEN 'SHORT_BREAK' ELSE 'LONG_BREAK' END;
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s,
                  CASE WHEN kind_text = 'SHORT_BREAK' THEN short_break ELSE long_break END,
                  kind_text);
        END IF;
      END IF;
    END LOOP;

    -- Afternoon peak: 2-4 PM (secondary peak)
    FOR hour_of_day IN afternoon_peak_start..afternoon_peak_end LOOP
      -- 40-60% chance of session in afternoon peak
      IF random() < 0.5 THEN
        s := (d::timestamp + make_interval(hours => hour_of_day, mins => (random() * 59)::int))::timestamptz;

        -- Insert WORK session
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');

        session_count := session_count + 1;

        -- Sometimes add a break after work
        IF random() < 0.4 THEN
          s := s + make_interval(secs => work_seconds);
          kind_text := CASE WHEN random() < 0.6 THEN 'SHORT_BREAK' ELSE 'LONG_BREAK' END;
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s,
                  CASE WHEN kind_text = 'SHORT_BREAK' THEN short_break ELSE long_break END,
                  kind_text);
        END IF;
      END IF;
    END LOOP;

    -- Guarantee at least one WORK session per day for streak
    IF session_count = 0 THEN
      -- Add a guaranteed session at a random peak hour
      hour_of_day := CASE WHEN random() < 0.6 THEN morning_peak_start + (random() * 2)::int
                         ELSE afternoon_peak_start + (random() * 2)::int END;
      s := (d::timestamp + make_interval(hours => hour_of_day, mins => (random() * 59)::int))::timestamptz;

      INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
      VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
    END IF;

    -- Occasionally add sessions in non-peak hours (10% chance)
    IF random() < 0.1 THEN
      hour_of_day := CASE WHEN random() < 0.5 THEN 12 + (random() * 2)::int  -- Lunch time
                         ELSE 17 + (random() * 3)::int END; -- Evening
      s := (d::timestamp + make_interval(hours => hour_of_day, mins => (random() * 59)::int))::timestamptz;

      INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
      VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
    END IF;

    d := d + interval '1 day';
  END LOOP;

  RAISE NOTICE 'Analytics demo data generation complete. Created sessions for 35 days.';
END$$;

-- Verification queries (uncomment to run after insertion)
/*
-- Check streak (should be 35+)
SELECT COUNT(*) as productive_days FROM (
  SELECT DISTINCT DATE(sr.started_at) as work_date
  FROM session_records sr
  WHERE sr.user_id = '731a07ab-212c-4528-8844-fa6cf6c7e8ed'
    AND sr.kind = 'WORK'
) productive_days;

-- Check peak hours distribution
SELECT
  EXTRACT(HOUR FROM sr.started_at) as hour,
  COUNT(*) as session_count
FROM session_records sr
WHERE sr.user_id = '731a07ab-212c-4528-8844-fa6cf6c7e8ed'
  AND sr.kind = 'WORK'
GROUP BY EXTRACT(HOUR FROM sr.started_at)
ORDER BY hour;
*/

-- Usage example:
-- psql -h localhost -p 5432 -U timebeam -d timebeam -f back-end/db/generate_analytics_demo_session_records.sql
