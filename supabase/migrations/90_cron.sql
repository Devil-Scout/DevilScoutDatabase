-- Vacuum every night at 6am GMT (1am EST, 10pm PST)
-- This is optimal for the majority of FRC competitions (North America and Europe)
SELECT cron.schedule (
  'nightly-vacuum',
  '0 6 * * *',
  $$ VACUUM ANALYZE $$
);

-- FRC Synchronization jobs
-- make sure to use Last-Modified and FMS-OnlyModifiedSince headers
-- to only return modifications

-- Synchronize every 5 minutes:
-- - for each event in the current season (read from db) (typically around 250):
--   - match schedules & results
--   - rankings
SELECT cron.schedule (
  'frc-synchronize-rapid',
  '*/5 * * * *',
  $$ $$
);

-- Synchronize every 4 hours:
-- - seasons
-- - all current season data
--   - districts
--   - events
--   - teams
--   - awards
--   - etc
SELECT cron.schedule (
  'frc-synchronize-season',
  '0 */4 * * *',
  $$ $$
);

-- Synchronize twice per week (Sunday and Wednesday):
-- - all data from any season
-- Also, perform VACUUM ANALYZE
-- 6am GMT (1am EST, 10pm PST) is optimal for the majority of
-- FRC competitions (which tend to take place in North America)
SELECT cron.schedule (
  'frc-synchronize-everything-and-vacuum',
  '0 6 * * *',
  $$ $$
);
