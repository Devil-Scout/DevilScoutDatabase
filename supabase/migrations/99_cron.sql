-- Required to begin synchronizing
-- Names will be null until
INSERT INTO frc_seasons (year)
SELECT *
FROM generate_series(2006, 2025);

-- FRC Synchronization jobs
-- make sure to use Last-Modified and FMS-OnlyModifiedSince headers
-- to only return modifications
-- also, the api has an odd caching bug when changing headers. Add a random query param to avoid.

-- Every 5 minutes:
-- - in our db, search for events that are currently running:
--   - event is in the current (maximum) season
--   - current date is in the range [(start - 1 day) to (end + 1 day)]
-- - for each of these events (bulk update):
--   - sync match schedules (1 transaction)
--     - practice
--     - qual
--     - playoff
--   - sync match results (1 transaction)
--     - qual
--     - playoff
--   - sync score details (1 transaction)
--     - qual
--     - playoff
--   - sync event rankings (1 transaction)
SELECT cron.schedule(
  'sync-rapid',
  '*/5 * * * *',
  $$
  $$
);

-- Every 4 hours:
-- - refresh current season events
-- Synchronize all current season data every 4 hours:
-- - season
-- - districts
-- - events
-- - teams
-- - awards
-- - etc
SELECT cron.schedule (
  'frc-sync-season',
  '0 */4 * * *',
  $$
  $$
);

-- Synchronize twice per week (Sunday and Wednesday):
-- - all data from any season
-- Also, perform VACUUM ANALYZE
-- 6am GMT (1am EST, 10pm PST) is optimal for the majority of
-- FRC competitions (which tend to take place in North America)
SELECT cron.schedule (
  'frc-sync-all',
  '0 6 * * *',
  $$
  CALL sync.seasons();
  VACUUM ANALYZE;
  $$
);
