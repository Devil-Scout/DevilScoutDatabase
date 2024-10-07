CREATE FUNCTION sync.get_current_event_keys()
RETURNS citext[]
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
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE PROCEDURE sync.events(year smallint)
AS $$
DECLARE
  request_id bigint;
BEGIN
  -- Request all events for the given year
  SELECT INTO request_id
    sync.tba_request('/events/' || year);

  -- Wait for request to finish
  -- This implicitly commits
  CALL sync.await_responses(
    request_ids := ARRAY[request_id],
    timeout := INTERVAL '10 seconds'
  );

  -- Write results to database
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
      NULL AS district_key,
      -- (r.j->'district'->>'key')::citext AS district_key,
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
  INSERT INTO frc_events
  SELECT
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
  FROM events e
  ON CONFLICT (key) DO UPDATE SET
    key = EXCLUDED.key,
    name = EXCLUDED.name,
    name_short = EXCLUDED.name_short,
    season = EXCLUDED.season,
    code = EXCLUDED.code,
    district_key = EXCLUDED.district_key,
    type = EXCLUDED.type,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    timezone = EXCLUDED.timezone,
    week = EXCLUDED.week,
    website = EXCLUDED.website,
    location = EXCLUDED.location,
    address = EXCLUDED.address,
    city = EXCLUDED.city,
    province = EXCLUDED.province,
    country = EXCLUDED.country,
    postal_code = EXCLUDED.postal_code,
    coordinates = EXCLUDED.coordinates;

  PERFORM sync.write_etag('/events/' || year, request_id);
  COMMIT;
END;
$$ LANGUAGE plpgsql;
