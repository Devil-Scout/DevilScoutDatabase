CREATE FUNCTION has_permission(p_type permission_type)
RETURNS boolean STRICT
STABLE
SECURITY DEFINER
LANGUAGE sql
RETURN p_type IN (
  SELECT type
    FROM permissions
    WHERE user_id = (SELECT auth.uid())
);

CREATE FUNCTION get_team_num()
RETURNS smallint
STABLE
SECURITY DEFINER
LANGUAGE sql
RETURN (
  SELECT team_num
    FROM team_users
    WHERE user_id = (SELECT auth.uid())
);

CREATE FUNCTION is_user_on_same_team(id_user uuid)
RETURNS boolean STRICT
STABLE
SECURITY DEFINER
LANGUAGE sql
RETURN SELECT (SELECT get_team_num()) = (
  SELECT team_num
    FROM team_users
    WHERE team_users.user_id = id_user
);

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public
FROM public, anon;

-- Restrict every public table by default
DO $$
DECLARE
  row RECORD;
BEGIN
  FOR row IN (
    SELECT tablename
      FROM pg_tables AS t
      WHERE t.schemaname = 'public'
  )
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', row.tablename);
  END LOOP;
END;
$$;

REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
FROM public, anon, authenticated;
