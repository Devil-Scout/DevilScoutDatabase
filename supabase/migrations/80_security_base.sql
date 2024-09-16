CREATE FUNCTION has_permission (permission_type citext) RETURNS BOOLEAN STRICT
SET
  search_path TO '' STABLE SECURITY DEFINER LANGUAGE SQL RETURN (
    permission_type IN (
      SELECT
        permission_type
      FROM
        permissions
      WHERE
        user_id = (
          SELECT
            auth.uid ()
        )
    )
  );

CREATE FUNCTION is_not_disabled () RETURNS BOOLEAN
SET
  search_path TO '' STABLE SECURITY DEFINER LANGUAGE SQL RETURN (
    NOT EXISTS (
      SELECT
        1
      FROM
        disabled_users
      WHERE
        user_id = (
          SELECT
            auth.uid ()
        )
    )
  );

CREATE FUNCTION get_team_num () RETURNS SMALLINT
SET
  search_path TO '' STABLE SECURITY DEFINER LANGUAGE SQL RETURN (
    SELECT
      team_num
    FROM
      team_users
    WHERE
      user_id = (
        SELECT
          auth.uid ()
      )
  );

CREATE FUNCTION is_user_on_same_team (user_id uuid) RETURNS BOOLEAN STRICT
SET
  search_path TO '' STABLE SECURITY DEFINER LANGUAGE SQL RETURN (
    EXISTS (
      SELECT
        1
      FROM
        team_users
      WHERE
        team_users.user_id = user_id
        AND team_users.team_num = (
          SELECT
            get_team_num ()
        )
    )
  );

REVOKE
EXECUTE ON ALL FUNCTIONS IN SCHEMA public
FROM
  public,
  anon;

REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
FROM
  public,
  anon,
  authenticated;
