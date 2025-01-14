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
  WHERE data_type = 'string[]'::data_type;
