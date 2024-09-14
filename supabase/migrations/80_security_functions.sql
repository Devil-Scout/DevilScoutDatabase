CREATE OR REPLACE FUNCTION
auth_user_has_permission(permission_type citext)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT
RETURN EXISTS (
  SELECT 1 FROM permissions
  WHERE type = permission_type AND user_id = auth.uid()
);
REVOKE EXECUTE ON FUNCTION auth_user_has_permission FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION
user_team_num(user_id uuid)
RETURNS SMALLINT
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT
RETURN (SELECT team_num FROM team_users WHERE user_id = user_id);
REVOKE EXECUTE ON FUNCTION user_team_num FROM public, anon, authenticated;

CREATE OR REPLACE FUNCTION
auth_user_team_num()
RETURNS SMALLINT
LANGUAGE SQL
STABLE
RETURNS NULL ON NULL INPUT
RETURN user_team_num(auth.uid());
REVOKE EXECUTE ON FUNCTION auth_user_team_num FROM public, anon, authenticated;
