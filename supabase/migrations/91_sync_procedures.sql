CREATE OR REPLACE PROCEDURE sync.seasons()
AS $$
DECLARE
  api_url CONSTANT text = 'https://frc-api.firstinspires.org/v3.0/';
  api_auth CONSTANT jsonb := sync.frc_api_auth();
  request_ids bigint[];
BEGIN
  -- Request every known season
  DROP TABLE IF EXISTS requests;
  CREATE TEMP TABLE requests AS
  SELECT
    year AS season,
    (
      net.http_get(
        url := concat('https://frc-api.firstinspires.org/v3.0/', year),
        headers := api_auth
      )
    ) AS id
  FROM frc_seasons;

  -- Wait for requests to finish
  -- This implicitly commits
  SELECT array_agg(requests.id)
  INTO request_ids
  FROM requests;

  CALL sync.await_responses(
    request_ids := request_ids,
    timeout := INTERVAL '10 seconds'
  );

  -- Write results to database
  UPDATE frc_seasons
  SET name = responses.name
  FROM (
    SELECT
      requests.season,
      response.content::jsonb ->> 'gameName'
    FROM
      requests
      JOIN net._http_response response ON requests.id = response.id
    WHERE
      response.status_code = 200
  ) AS responses(season, name)
  WHERE frc_seasons.year = responses.season;

  -- Clean up and commit
  DROP TABLE requests;
  COMMIT;
END;
$$ LANGUAGE plpgsql;
