CREATE FUNCTION auth_delete_user()
RETURNS VOID
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM auth.users
    WHERE id = (SELECT auth.uid());
END;
$$;

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

CREATE FUNCTION submit_scouting_data(
  category scouting_category,
  key text,
  team_num smallint,
  data json
)
RETURNS void
LANGUAGE plpgsql
AS $$
#variable_conflict use_variable
DECLARE
  submission_id uuid;
  year smallint;
BEGIN
  year := substring(key FROM 0 FOR 5)::smallint;

  -- Create the submission
  IF category = 'pit'::scouting_category THEN
    WITH submission AS (
      INSERT INTO submissions
        (category, season, scouted_team, event_key) VALUES
        (category, year, team_num, key)
        RETURNING id
    )
    SELECT INTO submission_id submission.id FROM submission;
  ELSE
    WITH submission AS (
      INSERT INTO submissions
        (category, season, scouted_team, event_key, match_key) VALUES
        (category, year, team_num, substring(key FROM '^(\w+)_'), key)
        RETURNING id
    )
    SELECT INTO submission_id submission.id FROM submission;
  END IF;

  -- numbers
  WITH qs AS (
    SELECT q.id
    FROM questions q
    WHERE
      q.season = year AND
      q.category = category AND
      q.data_type = 'number'::data_type
  )
  INSERT INTO submission_data (submission_id, question_id, data_num)
    SELECT submission_id, q.id, (data->>(q.id::text))::numeric
    FROM qs q;

  -- booleans
  WITH qs AS (
    SELECT q.id
    FROM questions q
    WHERE
      q.season = year AND
      q.category = category AND
      q.data_type = 'boolean'::data_type
  )
  INSERT INTO submission_data (submission_id, question_id, data_bool)
    SELECT submission_id, q.id, (data->>(q.id::text))::boolean
    FROM qs q;

  -- strings
  WITH qs AS (
    SELECT q.id
    FROM questions q
    WHERE
      q.season = year AND
      q.category = category AND
      q.data_type = 'string'
  )
  INSERT INTO submission_data (submission_id, question_id, data_str)
    SELECT submission_id, q.id, (data->>(q.id::text))
    FROM qs q;

  -- arrays
  WITH qs AS (
    SELECT q.id
    FROM questions q
    WHERE
      q.season = year AND
      q.category = category AND
      q.data_type = 'array'
  )
  INSERT INTO submission_data (submission_id, question_id, data_arr)
    SELECT submission_id, q.id, json_to_array(data->(q.id::text))
    FROM qs q;
END;
$$;
