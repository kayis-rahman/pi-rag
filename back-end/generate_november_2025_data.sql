-- Generate November 2025 session records for historical analytics data
-- Uses the authenticated user ID: 67546cba-5ba0-4b83-84bf-5906af7b2708

SET TIME ZONE 'UTC';

DO $$
DECLARE
  d date := date '2025-11-01';  -- Start of November 2025
  endd date := date '2025-11-30'; -- Full month of November
  s timestamptz;
  user_uuid uuid := '67546cba-5ba0-4b83-84bf-5906af7b2708'; -- Authenticated user
  work_minutes int;
  i int;
  work_seconds int := 1500;    -- 25 minutes
  short_break int := 300;      -- 5 minutes
  long_break int := 900;       -- 15 minutes
  lunch_break int := 1800;     -- 30 minutes lunch
  cycles_before_long int := 4;
  kind_text text;
  daily_focus_minutes int[];
BEGIN
  -- Safety check: ensure table exists
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = current_schema() AND table_name = 'session_records'
  ) THEN
    RAISE WARNING 'Table session_records does not exist; nothing will be inserted.';
    RETURN;
  END IF;

  -- Realistic daily focus minutes for November (building up focus habit)
  daily_focus_minutes := ARRAY[
    0, 120, 180, 240, 300, 360, 420,  -- Week 1 (gradually increasing)
    240, 300, 360, 420, 480, 360, 240, -- Week 2 (good consistency)
    300, 420, 480, 360, 420, 480, 360, -- Week 3 (peak performance)
    420, 480, 360, 420, 480, 360, 300, -- Week 4 (slight dip)
    360, 420, 480                         -- Week 5 start
  ];

  WHILE d <= endd LOOP
    -- Get focus minutes for this day (0 = weekend/rest day)
    work_minutes := daily_focus_minutes[extract(day FROM d)::int];

    IF work_minutes = 0 THEN
      -- Weekend or rest day - maybe just 1-2 light sessions
      IF random() < 0.3 THEN  -- 30% chance of weekend session
        s := (d::timestamp + time '11:00')::timestamptz;
        FOR i IN 1..2 LOOP
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
          s := s + make_interval(secs => work_seconds + short_break);
        END LOOP;
      END IF;
    ELSE
      -- Weekday: structured Pomodoro sessions based on target minutes
      s := (d::timestamp + time '09:00')::timestamptz;

      -- Calculate how many full Pomodoro cycles we need
      -- Each cycle = 25min work + 5min break, but long break every 4 cycles
      DECLARE
        total_cycles int := (work_minutes / 25); -- Rough estimate
        cycle_count int := 0;
      BEGIN
        WHILE cycle_count < total_cycles AND cycle_count < 12 LOOP -- Max 12 cycles per day
          -- Work session
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
          s := s + make_interval(secs => work_seconds);
          cycle_count := cycle_count + 1;

          -- Break after work (unless it's the last session)
          IF cycle_count < total_cycles THEN
            IF cycle_count % cycles_before_long = 0 THEN
              INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
              VALUES (gen_random_uuid(), user_uuid, s, long_break, 'LONG_BREAK');
              s := s + make_interval(secs => long_break);
            ELSE
              INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
              VALUES (gen_random_uuid(), user_uuid, s, short_break, 'SHORT_BREAK');
              s := s + make_interval(secs => short_break);
            END IF;
          END IF;

          -- Lunch break around noon
          IF cycle_count = 4 AND extract(hour FROM s) >= 12 THEN
            INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
            VALUES (gen_random_uuid(), user_uuid, s, lunch_break, 'LONG_BREAK');
            s := s + make_interval(secs => lunch_break);
          END IF;
        END WHILE;
      END;
    END IF;

    d := d + interval '1 day';
  END LOOP;
END$$;

-- Verify the November data was inserted
SELECT
  DATE(started_at AT TIME ZONE 'UTC') as date,
  COUNT(*) as total_sessions,
  COUNT(CASE WHEN kind = 'WORK' THEN 1 END) as work_sessions,
  ROUND(SUM(CASE WHEN kind = 'WORK' THEN duration_seconds ELSE 0 END) / 60.0, 1) as work_minutes
FROM session_records
WHERE user_id = '67546cba-5ba0-4b83-84bf-5906af7b2708'::uuid
  AND started_at >= '2025-11-01'::timestamptz
  AND started_at < '2025-12-01'::timestamptz
GROUP BY DATE(started_at AT TIME ZONE 'UTC')
ORDER BY date;
