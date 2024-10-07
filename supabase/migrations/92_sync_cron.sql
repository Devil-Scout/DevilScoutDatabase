CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;

-- TBA Synchronization jobs
-- - Daily/weekly jobs run at 6am GMT (1am EST, 10pm PST)
--    - Optimal for FRC competitions in North America (the vast majority)
--    - International competitions will likely see slightly degraded performance
-- - Use ETag and If-None-Match headers to reduce traffic

-- Every 5 minutes, sync:
-- - For all current events:
--   - List of teams
--   - Match schedules & results
--   - Team rankings
SELECT cron.schedule(
  job_name := 'sync-rapid',
  schedule := '*/5 * * * *',
  command :=
  $$
  CALL sync.events(sync.current_year());
  $$
);

-- Once per day, sync:
-- - For this season only:
--   - All districts
--   - All events
--   - All teams
--   - For all non-current events:
--     - List of teams
--     - Match schedules & results
--     - Team rankings
--   - For all events:
--     - Awards
-- SELECT cron.schedule (
--   'sync-season',
--   '0 6 * * *',
--   $$
--   $$
-- );

-- Once per week on Mondays, sync:
-- - For all non-current seasons:
--   - All districts
--   - All events
--   - All teams
--   - For all events:
--     - List of teams
--     - Match schedules & results
--     - Team rankings
--     - Awards
-- SELECT cron.schedule (
--   'sync-archive',
--   '0 6 * * 1',
--   $$
--   $$
-- );

-- Once per day, run VACUUM ANALYZE
-- Runs an hour after daily/weekly syncs
-- SELECT cron.schedule(
--   'vacuum-analyze',
--   '0 7 * * *',
--   $$
--   VACUUM ANALYZE;
--   $$
-- );
