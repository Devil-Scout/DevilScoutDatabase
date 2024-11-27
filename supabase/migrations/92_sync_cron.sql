CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;

-- TBA Synchronization jobs
-- - Daily/weekly jobs run at 6am GMT (1am EST, 10pm PST)
--    - Optimal for FRC competitions in North America (the vast majority)
--    - International competitions will likely see slightly degraded performance
-- - Use ETag and If-None-Match headers to reduce traffic

CREATE PROCEDURE sync.current_dblink()
LANGUAGE sql
AS $$
  SELECT sync.connect();
  SELECT sync.exec('CALL sync.event_teams(sync.current_event_keys())');
  SELECT sync.exec('CALL sync.event_rankings(sync.current_event_keys())');
  SELECT sync.exec('CALL sync.matches(sync.current_event_keys())');
  SELECT sync.disconnect();
$$;

SELECT cron.schedule(
  job_name := 'sync-current',
  schedule := '*/5 * * * *',
  command :=
  $$
  CALL sync.current_dblink();
  $$
);

CREATE PROCEDURE sync.season_dblink()
LANGUAGE sql
AS $$
  SELECT sync.connect();
  SELECT sync.exec('CALL sync.districts(sync.current_year())');
  SELECT sync.exec('CALL sync.events(sync.current_year())');
  SELECT sync.exec('CALL sync.teams()');
  SELECT sync.exec('CALL sync.event_teams(sync.non_current_event_keys())');
  SELECT sync.exec('CALL sync.event_rankings(sync.non_current_event_keys())');
  SELECT sync.exec('CALL sync.matches(sync.non_current_event_keys())');
  SELECT sync.disconnect();
$$;

SELECT cron.schedule (
  'sync-season',
  '0 * * * *',
  $$
  CALL sync.season_dblink();
  $$
);

CREATE PROCEDURE sync.archive_dblink()
LANGUAGE sql
AS $$
  SELECT sync.connect();
  SELECT sync.exec('CALL sync.old_districts()');
  SELECT sync.exec('CALL sync.old_events()');
  SELECT sync.exec('CALL sync.old_event_teams()');
  SELECT sync.exec('CALL sync.old_event_rankings()');
  SELECT sync.exec('CALL sync.old_matches()');
  SELECT sync.disconnect();
$$;

SELECT cron.schedule (
  'sync-archive',
  '0 6 * * 1',
  $$
  CALL sync.archive_dblink();
  $$
);

SELECT cron.schedule(
  'vacuum-analyze',
  '0 7 * * *',
  $$
  VACUUM ANALYZE;
  $$
);
