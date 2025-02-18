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
CREATE FUNCTION jsonb_typeof_i(data jsonb)
RETURNS data_type
IMMUTABLE
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN jsonb_typeof(data)::data_type;
END;
$$;

ALTER TABLE public.submission_data
  ADD COLUMN data_type data_type NOT NULL
GENERATED ALWAYS AS (jsonb_typeof_i(data)) STORED;

CREATE INDEX ON submission_data
  (question_id, (data::numeric))
  WHERE data_type = 'number'::data_type;

CREATE INDEX ON submission_data
  (question_id, (data::boolean))
  WHERE data_type = 'boolean'::data_type;

CREATE INDEX ON submission_data
  (question_id, (data::text))
  WHERE data_type = 'string'::data_type;

CREATE INDEX ON submission_data
  USING GIN(question_id, data)
  WHERE data_type = 'array'::data_type;
