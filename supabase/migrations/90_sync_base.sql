CREATE SCHEMA sync;

CREATE FUNCTION sync.frc_api_auth()
RETURNS jsonb STRICT
AS $$
  SELECT concat(
    '{ "Authorization": "Basic ',
    (
      SELECT
        decrypted_secret
      FROM vault.decrypted_secrets
      WHERE
        name = 'frc_api_auth'
    ),
    '" }'
  )::jsonb;
$$ LANGUAGE sql STABLE;

CREATE FUNCTION sync.current_year()
RETURNS smallint STRICT
AS $$
  SELECT extract(YEAR FROM now());
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE PROCEDURE sync.await_responses(
  request_ids bigint[],
  timeout interval
)
AS $$
DECLARE
  start_time CONSTANT timestamptz := now();
BEGIN
  DROP TABLE IF EXISTS remaining;
  CREATE TEMP TABLE remaining AS
  SELECT id
  FROM unnest(request_ids) requests(id);

  WHILE TRUE LOOP
    -- transactions prevent changes from appearing
    COMMIT;

    -- if a response has an error of any kind, abort
    IF EXISTS (
      SELECT 1
      FROM
        net._http_response response
        JOIN remaining request ON response.id = request.id
      WHERE
        response.timed_out OR
        response.error_msg IS NOT NULL OR
        NOT (response.status_code = 200 OR response.status_code = 304)
      LIMIT 1
    )
    THEN
      RAISE EXCEPTION 'server responded with error';
    END IF;

    -- if a request returned successfully, remove it from remaining
    DELETE FROM remaining
      USING net._http_response response
    WHERE remaining.id = response.id;

    -- if there are no more requests, return successfully
    IF (SELECT count(*) FROM remaining) = 0 THEN
      RETURN;
    END IF;

    -- timeout if this is taking too long
    IF now() - start_time >= timeout THEN
      RAISE EXCEPTION 'timeout while waiting for responses';
    END IF;

    -- wait for more responses
    PERFORM pg_sleep(0.1);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Returns all known events that are "currently running":
-- - current year's game
-- - within one day of the event's dates
CREATE FUNCTION sync.current_event_codes ()
RETURNS TABLE (
  season smallint,
  event_code citext
)
AS $$
DECLARE
  current_season CONSTANT smallint := sync.current_year();
BEGIN
  RETURN QUERY (
    SELECT
      event.season,
      event.code
    FROM frc_events event
    WHERE
      event.season = current_season AND
      now() >= (event.start_date - INTERVAL '1 day') AND
      now() <= (event.end_date + INTERVAL '1 day')
  );
END;
$$ LANGUAGE plpgsql STABLE;
