CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE FUNCTION sync.jsonb_merge_nullable(a jsonb, b jsonb)
RETURNS jsonb
AS $$
  SELECT COALESCE(a || b, a, b);
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION sync.etag_header(endpoint text)
RETURNS jsonb STRICT
AS $$
  SELECT
    concat(
      '{ "If-None-Match": "',
      replace(value, '"', '\"'),
      '" }'
    )::jsonb
  FROM sync.etags
  WHERE
    etags.endpoint = endpoint AND
    etags.value IS NOT NULL;
$$ LANGUAGE sql STABLE;

CREATE FUNCTION sync.tba_api_auth()
RETURNS jsonb
AS $$
  SELECT concat(
    '{ "X-TBA-Auth-Key": "',
    (
      SELECT
        decrypted_secret
      FROM vault.decrypted_secrets
      WHERE
        name = 'tba_api_key'
    ),
    '" }'
  )::jsonb;
$$ LANGUAGE sql STABLE;

CREATE FUNCTION sync.tba_request(endpoint text)
RETURNS bigint STRICT
AS $$
  SELECT net.http_get(
      url := concat('https://www.thebluealliance.com/api/v3', endpoint),
      headers := sync.jsonb_merge_nullable(
        sync.tba_api_auth(),
        sync.etag_header(endpoint)
      )
    )
$$ LANGUAGE sql;

CREATE FUNCTION sync.write_etag(endpoint text, request_id bigint)
RETURNS VOID
AS $$
  INSERT INTO sync.etags
    (endpoint, value)
  VALUES
    (
      endpoint,
      (
        SELECT headers->>'etag'
        FROM net._http_response
        WHERE id = request_id
      )
    )
  ON CONFLICT (endpoint) DO UPDATE
  SET
    value = EXCLUDED.value;
$$ LANGUAGE sql;

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
