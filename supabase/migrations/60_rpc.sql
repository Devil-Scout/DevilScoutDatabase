CREATE FUNCTION frc_teams_search(query text)
RETURNS SETOF smallint
LANGUAGE sql
STABLE
AS $$
  SELECT frc_teams.number
    FROM frc_teams
      LEFT JOIN teams ON frc_teams.number = teams.number
    ORDER BY greatest(
      similarity(frc_teams.number::text, query),
      similarity(frc_teams.name, query),
      similarity(teams.name, query)
    ) DESC, frc_teams.number ASC;
$$;

CREATE FUNCTION frc_events_search(year smallint, query text)
RETURNS SETOF citext
LANGUAGE sql
STABLE
AS $$
  SELECT e.key
    FROM frc_events e
    WHERE e.season = year
    ORDER BY greatest(
      similarity(e.key::text, query),
      similarity(e.name::text, query)
    ) DESC, e.key ASC;
$$;

CREATE OR REPLACE FUNCTION submit_scouting_data(
  category scouting_category,
  key text,
  team_num smallint,
  data json
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  submission_id uuid;
BEGIN
  -- Create the submission
  IF category = 'pit'::scouting_category THEN
    WITH submission AS (
      INSERT INTO submissions
        (category, season, scouted_team, event_key) VALUES
        (category, substring(key FROM 0 FOR 5)::smallint, team_num, key)
        RETURNING id
    )
    SELECT INTO submission_id submission.id FROM submission;
  ELSE
    WITH submission AS (
      INSERT INTO submissions
        (category, season, scouted_team, event_key, match_key) VALUES
        (category, substring(key FROM 0 FOR 5)::smallint, team_num, substring(key FROM '^(\w+)_'), key)
        RETURNING id
    )
    SELECT INTO submission_id submission.id FROM submission;
  END IF;

  WITH map AS (
    SELECT j.key, j.value
    FROM json_each(data) AS j(key, value)
  )
  INSERT INTO submission_data (submission_id, question_id, data)
    SELECT submission_id, map.key::uuid, map.value::jsonb
    FROM map;
END;
$$;
