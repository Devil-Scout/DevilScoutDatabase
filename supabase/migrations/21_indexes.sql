CREATE INDEX
ON submission_data
  (question_id, value_bool)
WHERE
  value_bool IS NOT NULL;

CREATE INDEX
ON submission_data
  (question_id, value_int)
WHERE
  value_int IS NOT NULL;

CREATE INDEX
ON submission_data
USING GIN
  (question_id, value_text)
WHERE
  value_text IS NOT NULL;

CREATE INDEX
ON frc_events
USING GIST
  (coordinates);
