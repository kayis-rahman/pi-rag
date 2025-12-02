-- Generate enhanced December 2025 session records with varied realistic data
-- Uses the authenticated user ID: 67546cba-5ba0-4b83-84bf-5906af7b2708

SET TIME ZONE 'UTC';

DO $$
DECLARE
  d date := date '2025-12-01';  -- Start of December 2025
  endd date := date '2025-12-15'; -- First half of December
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

  -- More varied and realistic daily focus minutes for December
  daily_focus_minutes := ARRAY[
    420, 480, 360, 420, 480, 240, 180,  -- Week 1: Strong start, lighter weekend
    360, 480, 420, 480, 360, 240, 300,  -- Week 2: Consistent weekdays
    480, 360, 420, 480, 360, 180, 240   -- Week 3 start: Good performance
  ];

  WHILE d <= endd LOOP
    -- Get focus minutes for this day
    work_minutes := daily_focus_minutes[extract(day FROM d)::int];

    IF work_minutes = 0 THEN
      -- No sessions for this day
      d := d + interval '1 day';
      CONTINUE;
    END IF;

    -- Calculate sessions based on target minutes
    s := (d::timestamp + time '09:00')::timestamptz;
    DECLARE
      remaining_minutes int := work_minutes;
      cycle_count int := 0;
    BEGIN
      WHILE remaining_minutes >= 25 AND cycle_count < 12 LOOP
        -- Work session
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
        s := s + make_interval(secs => work_seconds);
        remaining_minutes := remaining_minutes - 25;
        cycle_count := cycle_count + 1;

        -- Add break if more work remaining
        IF remaining_minutes >= 25 THEN
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

        -- Lunch break around noon (after 3-4 work sessions)
        IF cycle_count = 4 AND extract(hour FROM s) >= 12 THEN
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, lunch_break, 'LONG_BREAK');
          s := s + make_interval(secs => lunch_break);
        END IF;
      END LOOP;
    END;

    d := d + interval '1 day';
  END LOOP;
END$$;

-- Verify the December data
SELECT
  DATE(started_at AT TIME ZONE 'UTC') as date,
  COUNT(*) as total_sessions,
  COUNT(CASE WHEN kind = 'WORK' THEN 1 END) as work_sessions,
  ROUND(SUM(CASE WHEN kind = 'WORK' THEN duration_seconds ELSE 0 END) / 60.0, 1) as work_minutes
FROM session_records
WHERE user_id = '67546cba-5ba0-4b83-84bf-5906af7b2708'::uuid
  AND started_at >= '2025-12-01'::timestamptz
GROUP BY DATE(started_at AT TIME ZONE 'UTC')
ORDER BY date;
