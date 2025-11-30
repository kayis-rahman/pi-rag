-- Generate a month of Pomodoro-style session records into `session_records`.
-- Assumptions:
--  * PostgreSQL is used (pgcrypto extension available or will be created by the script).
--  * Table `session_records` has columns: id (uuid), user_id (uuid), started_at (timestamptz), duration_seconds (integer), kind (string).
--  * We insert for user_id = '731a07ab-212c-4528-8844-fa6cf6c7e8ed' by default. Change the UUID below to target a different user.
--  * Timezone used is UTC; sessions start at 09:00 UTC each day.
--  * Weekdays use 8 pomodoro cycles (8 work sessions + breaks); weekends use 4 cycles (shorter schedule).
--  * Work = 25 minutes (1500s), short break = 5 minutes (300s), long break = 15 minutes (900s).
--  * The date range covered: 2025-10-20 .. 2025-11-18 (30 days up to 2025-11-18 inclusive). Adjust `start_date`/`end_date` if you want a different month.

SET TIME ZONE 'UTC';

-- Create pgcrypto if missing (to use gen_random_uuid()). If your DB already provides uuid generation functions (uuid-ossp), you can adapt accordingly.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  d date := date '2025-10-20';
  endd date := date '2025-11-18';
  s timestamptz;
  user_uuid uuid := '731a07ab-212c-4528-8844-fa6cf6c7e8ed';
  i int;
  work_seconds int := 1500;    -- 25 minutes
  short_break int := 300;      -- 5 minutes
  long_break int := 900;       -- 15 minutes (used as Pomodoro long break)
  lunch_break int := 1800;     -- 30 minutes lunch between morning/afternoon blocks
  cycles_before_long int := 4; -- after every 4th work session, insert a long break
  kind_text text;

BEGIN
  -- Safety check: ensure table exists
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = current_schema() AND table_name = 'session_records'
  ) THEN
    RAISE WARNING 'Table session_records does not exist in schema %; nothing will be inserted.', current_schema();
    RETURN;
  END IF;

  WHILE d <= endd LOOP
    -- Weekday behaviour: two pomodoro blocks (morning + afternoon)
    IF extract(dow FROM d) IN (1,2,3,4,5) THEN
      -- Morning block: 4 cycles starting at 09:00
      -- suppress the final break in the morning block because we'll insert an explicit lunch break below
      s := (d::timestamp + time '09:00')::timestamptz;
      FOR i IN 1..4 LOOP
        -- work
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
        s := s + make_interval(secs => work_seconds);

        -- Decide whether to insert a break after this work session.
        IF i = 4 THEN
          -- do not insert a break after the final work in this block
          CONTINUE;
        END IF;

        -- choose break: after every 4th work session in a row use LONG_BREAK, else SHORT_BREAK
        IF (i % cycles_before_long) = 0 THEN
          kind_text := 'LONG_BREAK';
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, long_break, kind_text);
          s := s + make_interval(secs => long_break);
        ELSE
          kind_text := 'SHORT_BREAK';
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, short_break, kind_text);
          s := s + make_interval(secs => short_break);
        END IF;
      END LOOP;

      -- Lunch gap (30 minutes) simulate a longer break/lunch
      -- We'll insert an explicit lunch long break entry at 12:30 if you want to reflect a lunch record
      INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
      VALUES (gen_random_uuid(), user_uuid, (d::timestamp + time '12:30')::timestamptz, lunch_break, 'LONG_BREAK');

      -- Afternoon block: 4 cycles starting at 13:30
      -- suppress the final break at end of day
      s := (d::timestamp + time '13:30')::timestamptz;
      FOR i IN 1..4 LOOP
        -- work
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
        s := s + make_interval(secs => work_seconds);

        -- Decide whether to insert a break after this work session.
        IF i = 4 THEN
          -- do not insert a break after the final work in this block
          CONTINUE;
        END IF;

        -- choose break: after every 4th work session in a row use LONG_BREAK, else SHORT_BREAK
        IF (i % cycles_before_long) = 0 THEN
          kind_text := 'LONG_BREAK';
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, long_break, kind_text);
          s := s + make_interval(secs => long_break);
        ELSE
          kind_text := 'SHORT_BREAK';
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, short_break, kind_text);
          s := s + make_interval(secs => short_break);
        END IF;
      END LOOP;

    ELSE
      -- Weekend behaviour: lighter schedule with two shorter blocks (2 cycles each)
      -- For weekend blocks we also suppress the final break so the blocks are separated by the explicit gap
      s := (d::timestamp + time '10:00')::timestamptz;
      FOR i IN 1..2 LOOP
        -- work
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
        s := s + make_interval(secs => work_seconds);

        -- Decide whether to insert a break after this work session.
        IF i = 2 THEN
          -- do not insert a break after the final work in this block
          CONTINUE;
        END IF;

        -- choose break: after every 4th work session in a row use LONG_BREAK, else SHORT_BREAK
        IF (i % cycles_before_long) = 0 THEN
          kind_text := 'LONG_BREAK';
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, long_break, kind_text);
          s := s + make_interval(secs => long_break);
        ELSE
          kind_text := 'SHORT_BREAK';
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, short_break, kind_text);
          s := s + make_interval(secs => short_break);
        END IF;
      END LOOP;
      -- short midday pause
      s := (d::timestamp + time '14:00')::timestamptz;
      FOR i IN 1..2 LOOP
        -- work
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
        s := s + make_interval(secs => work_seconds);

        -- Decide whether to insert a break after this work session.
        IF i = 2 THEN
          -- do not insert a break after the final work in this block
          CONTINUE;
        END IF;

        -- choose break: after every 4th work session in a row use LONG_BREAK, else SHORT_BREAK
        IF (i % cycles_before_long) = 0 THEN
          kind_text := 'LONG_BREAK';
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, long_break, kind_text);
          s := s + make_interval(secs => long_break);
        ELSE
          kind_text := 'SHORT_BREAK';
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, short_break, kind_text);
          s := s + make_interval(secs => short_break);
        END IF;
      END LOOP;
    END IF;

    d := d + interval '1 day';
  END LOOP;
END$$;

-- End of script

-- How to run (example):
-- psql -h localhost -p 5432 -U timebeam -d timebeam -f back-end/db/generate_month_session_records.sql
-- If your DB user requires a password set it via PGPASSWORD env var:
-- PGPASSWORD=yourpassword psql -h localhost -p 5432 -U timebeam -d timebeam -f back-end/db/generate_month_session_records.sql

-- Notes:
--  * If your PostgreSQL does not have pgcrypto, you can change gen_random_uuid() to uuid_generate_v4() and enable uuid-ossp instead:
--      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
--  * If your `started_at` column expects a different timezone handling, adjust SET TIME ZONE accordingly or change how s is built.
--  * To target a different user, replace the `user_uuid` value above.
