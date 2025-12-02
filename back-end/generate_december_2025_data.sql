-- Generate December 2025 session records for current month analytics
-- Uses the authenticated user ID: 67546cba-5ba0-4b83-84bf-5906af7b2708

SET TIME ZONE 'UTC';

DO $$
DECLARE
  d date := date '2025-12-01';  -- Start of December 2025
  endd date := date '2025-12-15'; -- First half of December (up to today-ish)
  s timestamptz;
  user_uuid uuid := '67546cba-5ba0-4b83-84bf-5906af7b2708'; -- Authenticated user
  work_minutes int[];
  i int;
  work_seconds int := 1500;    -- 25 minutes
  short_break int := 300;      -- 5 minutes
  long_break int := 900;       -- 15 minutes
  lunch_break int := 1800;     -- 30 minutes lunch
  cycles_before_long int := 4;
  kind_text text;
BEGIN
  -- Safety check: ensure table exists
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = current_schema() AND table_name = 'session_records'
  ) THEN
    RAISE WARNING 'Table session_records does not exist; nothing will be inserted.';
    RETURN;
  END IF;

  -- Define realistic daily work minutes (simulating actual usage)
  work_minutes := ARRAY[0, 180, 240, 300, 360, 420, 480]; -- Minutes per day for Mon-Sun
  
  WHILE d <= endd LOOP
    -- Skip weekends for lighter schedule
    IF extract(dow FROM d) IN (0,6) THEN  -- 0=Sun, 6=Sat
      -- Weekend: just 1-2 short sessions
      s := (d::timestamp + time '11:00')::timestamptz;
      FOR i IN 1..2 LOOP
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
        s := s + make_interval(secs => work_seconds + short_break);
      END LOOP;
    ELSE
      -- Weekday: full Pomodoro schedule
      s := (d::timestamp + time '09:00')::timestamptz;
      
      -- Morning block: 4 cycles
      FOR i IN 1..4 LOOP
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
        s := s + make_interval(secs => work_seconds);

        IF i < 4 THEN
          kind_text := CASE WHEN (i % cycles_before_long) = 0 THEN 'LONG_BREAK' ELSE 'SHORT_BREAK' END;
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, 
                  CASE WHEN kind_text = 'LONG_BREAK' THEN long_break ELSE short_break END, kind_text);
          s := s + make_interval(secs => 
                CASE WHEN kind_text = 'LONG_BREAK' THEN long_break ELSE short_break END);
        END IF;
      END LOOP;

      -- Lunch break
      INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
      VALUES (gen_random_uuid(), user_uuid, (d::timestamp + time '12:30')::timestamptz, lunch_break, 'LONG_BREAK');

      -- Afternoon block: 3 cycles
      s := (d::timestamp + time '13:30')::timestamptz;
      FOR i IN 1..3 LOOP
        INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
        VALUES (gen_random_uuid(), user_uuid, s, work_seconds, 'WORK');
        s := s + make_interval(secs => work_seconds);

        IF i < 3 THEN
          kind_text := CASE WHEN ((i + 4) % cycles_before_long) = 0 THEN 'LONG_BREAK' ELSE 'SHORT_BREAK' END;
          INSERT INTO session_records(id, user_id, started_at, duration_seconds, kind)
          VALUES (gen_random_uuid(), user_uuid, s, 
                  CASE WHEN kind_text = 'LONG_BREAK' THEN long_break ELSE short_break END, kind_text);
          s := s + make_interval(secs => 
                CASE WHEN kind_text = 'LONG_BREAK' THEN long_break ELSE short_break END);
        END IF;
      END LOOP;
    END IF;

    d := d + interval '1 day';
  END LOOP;
END$$;

-- Verify the data was inserted
SELECT 
  DATE(started_at AT TIME ZONE 'UTC') as date,
  COUNT(*) as total_sessions,
  COUNT(CASE WHEN kind = 'WORK' THEN 1 END) as work_sessions,
  ROUND(SUM(CASE WHEN kind = 'WORK' THEN duration_seconds ELSE 0 END) / 60.0, 1) as work_minutes
FROM session_records 
WHERE user_id = '67546cba-5ba0-4b83-84bf-5906af7b2708'::uuid
  AND started_at >= '2025-12-01'::timestamptz
GROUP BY DATE(started_at AT TIME ZONE 'UTC')
ORDER BY date DESC;
