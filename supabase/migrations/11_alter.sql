ALTER TABLE profiles
ADD FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE;

ALTER TABLE team_users
  ALTER COLUMN team_num
  SET DEfAULT get_team_num();

ALTER TABLE permissions
  ALTER COLUMN team_num
  SET DEFAULT get_team_num();

ALTER TABLE submissions
  ALTER COLUMN scouting_team
  SET DEFAULT get_team_num();

-- Speed up fuzzy search

CREATE INDEX ON teams
  USING GIN(name gin_trgm_ops);

CREATE INDEX ON frc_teams
  USING GIN(name gin_trgm_ops);

CREATE INDEX ON frc_teams
  USING GIN((number::text) gin_trgm_ops);

CREATE INDEX ON frc_events
  USING GIN(name gin_trgm_ops);

CREATE INDEX ON frc_events
  USING GIN(key gin_trgm_ops);

-- Speed up data analysis

-- immutable wrapper
CREATE INDEX ON submission_data
  (question_id, data_num)
  WHERE data_num IS NOT NULL;

CREATE INDEX ON submission_data
  (question_id, data_bool)
  WHERE data_bool IS NOT NULL;

CREATE INDEX ON submission_data
  (question_id, data_str)
  WHERE data_str IS NOT NULL;

CREATE INDEX ON submission_data
  USING GIN(question_id, data_arr)
  WHERE data_arr IS NOT NULL;
