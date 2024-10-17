CREATE FUNCTION sync.get_current_event_keys()
RETURNS citext[]
STABLE
LANGUAGE sql
AS $$
  SELECT ARRAY(
    SELECT
      event.key
    FROM frc_events event
    WHERE
      event.season = sync.current_year() AND
      now() >= (event.start_date - INTERVAL '1 day') AND
      now() <= (event.end_date + INTERVAL '1 day')
  );
$$;

CREATE FUNCTION sync.extract_match_teams(
  results jsonb[],
  alliance_color text
)
RETURNS TABLE (
  match_key citext,
  team_num smallint,
  alliance frc_alliance,
  is_surrogate boolean,
  is_disqualified boolean
)
LANGUAGE sql
AS $$
  WITH s AS (
    SELECT
      (r.j->>'key') AS match_key,
      jsonb_array_elements_text(
        r.j->'alliances'->alliance_color->'team_keys'
      ) AS team_key,
      (r.j->'alliances'->alliance_color) AS alliance,
      r.j AS j
    FROM unnest(results) r(j)
  )
  SELECT
    match_key::citext,
    substring(team_key FROM '\d+$')::smallint AS team_num,
    alliance_color::frc_alliance AS alliance,
    team_key IN (
      SELECT jsonb_array_elements_text(alliance->'surrogate_team_keys')
    ) AS is_surrogate,
    team_key IN (
      SELECT jsonb_array_elements_text(alliance->'dq_team_keys')
    ) AS is_disqualified
  FROM s;
$$;

CREATE OR REPLACE PROCEDURE sync.matches(event_keys citext[])
LANGUAGE plpgsql
AS $$
DECLARE
  endpoint_prefix CONSTANT text := '/event/';
  endpoint_suffix CONSTANT text := '/matches';
  request_ids bigint[];
  results jsonb[];
BEGIN
  DROP TABLE IF EXISTS requests;
  CREATE TEMP TABLE requests AS
  SELECT
    event_key,
    sync.tba_request(
      endpoint_prefix || event_key || endpoint_suffix
    ) AS request_id
  FROM unnest(event_keys) keys(event_key);

  SELECT INTO request_ids
  ARRAY(SELECT request_id FROM requests);
  CALL sync.await_responses(request_ids);

  SELECT INTO results
  ARRAY(
    SELECT
      jsonb_array_elements(response.content::jsonb) AS j
    FROM
      net._http_response response
      JOIN requests ON requests.request_id = response.id
    WHERE
      response.status_code = 200
  );

  DELETE FROM frc_matches
  WHERE
    event_key IN (
      SELECT (j->>'event_key')
      FROM unnest(results) r(j)
    ) AND
    key NOT IN (
      SELECT (j->>'key')
      FROM unnest(results) r(j)
    );

  WITH matches AS (
    SELECT
      (r.j->>'key') AS key,
      (r.j->>'event_key') AS event_key,
      (r.j->>'comp_level') AS level,
      (r.j->>'set_number')::smallint AS set,
      (r.j->>'match_number')::smallint AS number,
      to_timestamp((r.j->>'time')::float8) AS scheduled_time,
      to_timestamp((r.j->>'predicted_time')::float8) AS predicted_time,
      to_timestamp((r.j->>'actual_time')::float8) AS actual_time
    FROM unnest(results) r(j)
  )
  MERGE INTO frc_matches f
  USING matches m ON
    f.key = m.key
  WHEN NOT MATCHED THEN
    INSERT VALUES (
      m.key,
      m.event_key,
      m.level,
      m.set,
      m.number,
      m.scheduled_time,
      m.predicted_time,
      m.actual_time
    )
  WHEN MATCHED THEN
    UPDATE SET
      event_key = m.event_key,
      level = m.level,
      set = m.set,
      number = m.number,
      scheduled_time = m.scheduled_time,
      predicted_time = m.predicted_time,
      actual_time = m.actual_time;

  WITH match_results AS (
    SELECT
      (r.j->>'key') AS match_key,
      (r.j->'alliances'->'red'->>'score')::smallint AS red_score,
      (r.j->'alliances'->'blue'->>'score')::smallint AS blue_score,
      nullif(r.j->>'winning_alliance', '')::frc_alliance AS winning_alliance,
      ARRAY(SELECT jsonb_array_elements(r.j->'videos')) AS videos,
      (r.j->'score_breakdown') AS score_breakdown
    FROM unnest(results) r(j)
  )
  MERGE INTO frc_match_results f
  USING match_results r ON
    f.match_key = r.match_key
  WHEN NOT MATCHED THEN
    INSERT VALUES (
      r.match_key,
      r.red_score,
      r.blue_score,
      r.winning_alliance,
      r.videos,
      r.score_breakdown
    )
  WHEN MATCHED THEN
    UPDATE SET
      red_score = r.red_score,
      blue_score = r.blue_score,
      winning_alliance = r.winning_alliance,
      videos = r.videos,
      score_breakdown = r.score_breakdown;

  DROP TABLE IF EXISTS match_teams;
  CREATE TEMP TABLE match_teams AS
  (
    SELECT * FROM
      sync.extract_match_teams(
        results,
        alliance_color := 'red'
      )
    UNION SELECT * FROM
      sync.extract_match_teams(
        results,
        alliance_color := 'blue'
      )
  );

  MERGE INTO frc_match_teams f
  USING match_teams m ON
    m.match_key = f.match_key AND
    m.team_num = f.team_num
  -- Need PG 17 for WHEN NOT MATCHED BY SOURCE
  -- Currently handled by following DELETE clause
  WHEN NOT MATCHED THEN
    INSERT
      (match_key, team_num, alliance, is_surrogate, is_disqualified)
    VALUES
      (m.match_key, m.team_num, m.alliance, m.is_surrogate, m.is_disqualified)
  WHEN MATCHED THEN
    UPDATE SET
      alliance = m.alliance,
      is_surrogate = m.is_surrogate,
      is_disqualified = m.is_disqualified;

  DELETE FROM frc_match_teams
  WHERE
    match_key IN (
      SELECT DISTINCT match_key
      FROM match_teams
    ) AND
    NOT EXISTS (
      SELECT 1
      FROM match_teams
      WHERE
        match_teams.match_key = frc_match_teams.match_key AND
        match_teams.team_num = frc_match_teams.team_num
    );

  PERFORM
    sync.update_etag(
      endpoint_prefix || event_key || endpoint_suffix,
      request_id
    )
  FROM requests;

  DROP TABLE requests;
  DROP TABLE match_teams;
  COMMIT;
END;
$$;

CREATE PROCEDURE sync.event_teams(event_keys citext[])
LANGUAGE plpgsql
AS $$
DECLARE
  endpoint_prefix CONSTANT text := '/event/';
  endpoint_suffix CONSTANT text := '/teams/keys';
  request_ids bigint[];
BEGIN
  DROP TABLE IF EXISTS requests;
  CREATE TEMP TABLE requests AS
  SELECT
    event_key,
    sync.tba_request(
      endpoint_prefix || event_key || endpoint_suffix
    ) AS request_id
  FROM unnest(event_keys) keys(event_key);

  SELECT INTO request_ids
  ARRAY(SELECT request_id FROM requests);
  CALL sync.await_responses(request_ids);

  DROP TABLE IF EXISTS results;
  CREATE TEMP TABLE results AS
  (
    SELECT
      substring(
        jsonb_array_elements_text(response.content::jsonb) FROM '\d+$'
      )::smallint AS team_num,
      requests.event_key AS event_key
    FROM
      net._http_response response
      JOIN requests ON requests.request_id = response.id
    WHERE
      response.status_code = 200
  );

  MERGE INTO frc_event_teams f
  USING results r ON
    f.team_num = r.team_num AND
    f.event_key = r.event_key
  WHEN NOT MATCHED THEN
    INSERT VALUES (
      r.team_num,
      r.event_key
    )
  WHEN MATCHED THEN
    DO NOTHING;

  DELETE FROM frc_event_teams
  WHERE
    event_key IN (
      SELECT event_key
      FROM results
    ) AND
    NOT EXISTS (
      SELECT 1
      FROM results
      WHERE
        results.event_key = frc_event_teams.event_key AND
        results.team_num = frc_event_teams.team_num
    );

  PERFORM
    sync.update_etag(
      endpoint_prefix || event_key || endpoint_suffix,
      request_id
    )
  FROM requests;

  DROP TABLE requests;
  COMMIT;
END;
$$;

CREATE PROCEDURE sync.teams()
LANGUAGE plpgsql
AS $$
DECLARE
  endpoint CONSTANT text := '/teams/';
  request_ids bigint[];
BEGIN
  DROP TABLE IF EXISTS requests;

  CREATE TEMP TABLE requests AS
  SELECT
    page_num,
    sync.tba_request(endpoint || page_num) AS request_id
  FROM generate_series(0, 21) pages(page_num);

  SELECT INTO request_ids
  ARRAY(SELECT request_id FROM requests);
  CALL sync.await_responses(request_ids);

  WITH responses AS (
    SELECT jsonb_array_elements(response.content::jsonb) AS j
    FROM
      net._http_response response
      JOIN requests ON requests.request_id = response.id
    WHERE
      response.status_code = 200
  ), teams AS (
    SELECT
      (r.j->>'team_number')::smallint AS number,
      (r.j->>'nickname') AS name,
      (r.j->>'rookie_year')::smallint AS rookie_season,
      (r.j->>'website') AS website,
      (r.j->>'city') AS city,
      (r.j->>'state_prov') AS province,
      (r.j->>'country') AS country,
      (r.j->>'postal_code') AS postal_code,
      point(
        (r.j->>'lat')::float8,
        (r.j->>'lng')::float8
      ) AS coordinates
    FROM responses r
  )
  MERGE INTO frc_teams f
  USING teams t ON
    f.number = t.number
  WHEN NOT MATCHED THEN
    INSERT VALUES (
      t.number,
      t.name,
      t.rookie_season,
      t.website,
      t.city,
      t.province,
      t.country,
      t.postal_code,
      t.coordinates
    )
  WHEN MATCHED THEN
    UPDATE SET
      name = t.name,
      rookie_season = t.rookie_season,
      website = t.website,
      city = t.city,
      province = t.province,
      country = t.country,
      postal_code = t.postal_code,
      coordinates = t.coordinates;

  PERFORM
    sync.update_etag(endpoint || page_num, request_id)
  FROM requests;

  DROP TABLE requests;
  COMMIT;
END;
$$;

CREATE PROCEDURE sync.districts(year smallint)
LANGUAGE plpgsql
AS $$
DECLARE
  endpoint CONSTANT text := '/districts/' || year;
  request_id bigint;
BEGIN
  SELECT INTO request_id
    sync.tba_request(endpoint);

  CALL sync.await_responses(ARRAY[request_id]);

  WITH responses AS (
    SELECT jsonb_array_elements(response.content::jsonb) AS j
    FROM net._http_response response
    WHERE
      response.id = request_id AND
      response.status_code = 200
  ), districts AS (
    SELECT
      (r.j->>'key')::citext AS key,
      (r.j->>'year')::smallint AS season,
      (r.j->>'abbreviation')::citext AS code,
      (r.j->>'display_name') AS name
    FROM responses r
  )
  MERGE INTO frc_districts f
  USING districts d ON
    f.key = d.key
  WHEN NOT MATCHED THEN
    INSERT VALUES (
      d.key,
      d.season,
      d.code,
      d.name
    )
  WHEN MATCHED THEN
    UPDATE SET
      season = d.season,
      code = d.code,
      name = d.name;

  PERFORM sync.update_etag(endpoint, request_id);

  COMMIT;
END;
$$;

CREATE PROCEDURE sync.events(year smallint)
LANGUAGE plpgsql
AS $$
DECLARE
  endpoint CONSTANT text := '/events/' || year;
  request_id bigint;
BEGIN
  SELECT INTO request_id
    sync.tba_request(endpoint);

  CALL sync.await_responses(ARRAY[request_id]);

  WITH responses AS (
    SELECT jsonb_array_elements(response.content::jsonb) AS j
    FROM net._http_response response
    WHERE
      response.id = request_id AND
      response.status_code = 200
  ), events AS (
    SELECT
      (r.j->>'key')::citext AS key,
      (r.j->>'name') AS name,
      (r.j->>'short_name') AS name_short,
      (r.j->>'year')::smallint AS season,
      (r.j->>'event_code')::citext AS code,
      (r.j->'district'->>'key')::citext AS district_key,
      (r.j->>'event_type')::smallint AS type,
      (r.j->>'start_date')::date AS start_date,
      (r.j->>'end_date')::date AS end_date,
      (r.j->>'timezone') AS timezone,
      (r.j->>'week')::smallint + 1 AS week,
      (r.j->>'website') AS website,
      (r.j->>'location_name') AS location,
      (r.j->>'address') AS address,
      (r.j->>'city') AS city,
      (r.j->>'state_prov') AS province,
      (r.j->>'country') AS country,
      (r.j->>'postal_code') AS postal_code,
      point(
        (r.j->>'lat')::float8,
        (r.j->>'lng')::float8
      ) AS coordinates
    FROM responses r
  )
  MERGE INTO frc_events f
  USING events e ON
    e.key = f.key
  WHEN NOT MATCHED THEN
    INSERT VALUES (
      e.key,
      e.name,
      e.name_short,
      e.season,
      e.code,
      e.district_key,
      e.type,
      e.start_date,
      e.end_date,
      e.timezone,
      e.week,
      e.website,
      e.location,
      e.address,
      e.city,
      e.province,
      e.country,
      e.postal_code,
      e.coordinates
    )
  WHEN MATCHED THEN
    UPDATE SET
      key = e.key,
      name = e.name,
      name_short = e.name_short,
      season = e.season,
      code = e.code,
      district_key = e.district_key,
      type = e.type,
      start_date = e.start_date,
      end_date = e.end_date,
      timezone = e.timezone,
      week = e.week,
      website = e.website,
      location = e.location,
      address = e.address,
      city = e.city,
      province = e.province,
      country = e.country,
      postal_code = e.postal_code,
      coordinates = e.coordinates;

  PERFORM sync.update_etag(endpoint, request_id);

  COMMIT;
END;
$$;
