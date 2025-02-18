CREATE FUNCTION sync.connect()
RETURNS void
LANGUAGE sql
AS $$
  SELECT dblink_connect('sync_conn', 'postgresql://postgres.jlhplhsuiwwcmxrtbdhp:'
  || (
    SELECT decrypted_secret
    FROM vault.decrypted_secrets
    WHERE name = 'sync_dblink_password'
  ) ||
  '@aws-0-us-east-1.pooler.supabase.com:6543/postgres');
$$;

CREATE FUNCTION sync.disconnect()
RETURNS void
LANGUAGE sql
AS $$
  SELECT dblink_disconnect('sync_conn');
$$;

CREATE FUNCTION sync.exec(sql text)
RETURNS void
LANGUAGE sql
AS $$
  SELECT dblink_exec('sync_conn', sql, true);
$$;

CREATE FUNCTION sync.jsonb_merge_nullable(a jsonb, b jsonb)
RETURNS jsonb
IMMUTABLE
LANGUAGE sql
AS $$
  SELECT COALESCE(a || b, a, b);
$$;

CREATE FUNCTION sync.update_etag(endpoint text, request_id bigint)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  etag text;
BEGIN
  SELECT headers->>'etag'
  INTO etag
  FROM net._http_response
  WHERE
    id = request_id AND
    status_code = 200;

  IF etag IS NOT NULL THEN
    INSERT INTO sync.etags
      (key, value)
    VALUES
      (endpoint, etag)
    ON CONFLICT (key) DO UPDATE
    SET
      value = EXCLUDED.value,
      modified_at = EXCLUDED.modified_at;
  END IF;
END;
$$;

CREATE FUNCTION sync.etag_header(endpoint text)
RETURNS jsonb STRICT
STABLE
LANGUAGE sql
AS $$
  SELECT
    concat(
      '{ "If-None-Match": "',
      replace(value, '"', '\"'),
      '" }'
    )::jsonb
  FROM sync.etags
  WHERE
    etags.key = endpoint AND
    etags.value IS NOT NULL;
$$;

CREATE FUNCTION sync.tba_api_auth()
RETURNS jsonb
STABLE
LANGUAGE sql
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
$$;

CREATE FUNCTION sync.tba_request(endpoint text)
RETURNS bigint STRICT
LANGUAGE sql
AS $$
  SELECT net.http_get(
      url := concat('https://www.thebluealliance.com/api/v3', endpoint),
      headers := sync.jsonb_merge_nullable(
        sync.tba_api_auth(),
        sync.etag_header(endpoint)
      ),
      timeout_milliseconds := 10000
    )
$$;

CREATE FUNCTION sync.current_year()
RETURNS smallint STRICT
STABLE
LANGUAGE sql
AS $$
  SELECT extract(YEAR FROM now());
$$;

CREATE PROCEDURE sync.await_responses(
  request_ids bigint[]
)
LANGUAGE plpgsql
AS $$
DECLARE
  row RECORD;
BEGIN
  DROP TABLE IF EXISTS remaining;
  CREATE TEMP TABLE remaining AS
  SELECT id
  FROM unnest(request_ids) requests(id);

  WHILE TRUE LOOP
    -- transactions prevent changes from appearing
    COMMIT;

    -- if a response has an error of any kind, log it
    FOR row IN (
      SELECT response.id AS response_id
      FROM
        net._http_response response
        JOIN remaining request ON response.id = request.id
      WHERE
        response.timed_out OR
        response.error_msg IS NOT NULL OR
        NOT (response.status_code = 200 OR response.status_code = 304)
    )
    LOOP
      RAISE LOG 'error from request %', row.response_id;
    END LOOP;

    -- if a request returned successfully, remove it from remaining
    DELETE FROM remaining
      USING net._http_response response
    WHERE remaining.id = response.id;

    -- if there are no more requests, return successfully
    IF NOT EXISTS (SELECT 1 FROM remaining) THEN
      RETURN;
    END IF;

    -- wait for more responses
    PERFORM pg_sleep(0.1);
  END LOOP;
END;
$$;
