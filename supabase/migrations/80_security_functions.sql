CREATE OR REPLACE FUNCTION
user_has_permission(permission_type citext)
RETURNS BOOLEAN
LANGUAGE SQL
SET search_path = ''
STABLE
RETURNS NULL ON NULL INPUT
RETURN permission_type IN (
  SELECT permission_type FROM permissions WHERE user_id = (SELECT auth.uid())
);
REVOKE EXECUTE ON FUNCTION user_has_permission FROM public, anon;

CREATE OR REPLACE FUNCTION
user_is_not_disabled()
RETURNS BOOLEAN
LANGUAGE SQL
SET search_path = ''
STABLE
RETURN NOT EXISTS (
  SELECT 1 FROM disabled_users WHERE user_id = (SELECT auth.uid())
);
REVOKE EXECUTE ON FUNCTION user_is_not_disabled FROM public, anon;

CREATE OR REPLACE FUNCTION
user_team_num()
RETURNS SMALLINT
LANGUAGE SQL
SET search_path = ''
STABLE
RETURN (SELECT team_num FROM team_users WHERE user_id = (SELECT auth.uid()));
REVOKE EXECUTE ON FUNCTION user_team_num FROM public, anon;

CREATE OR REPLACE FUNCTION
get_user_team_num(user_id uuid)
RETURNS SMALLINT
LANGUAGE SQL
SET search_path = ''
STABLE
RETURNS NULL ON NULL INPUT
RETURN (SELECT team_num FROM team_users WHERE team_users.user_id = user_id);
REVOKE EXECUTE ON FUNCTION get_user_team_num FROM public, anon;
