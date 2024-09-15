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
user_team_num()
RETURNS SMALLINT
LANGUAGE SQL
SET search_path = ''
STABLE
RETURNS NULL ON NULL INPUT
RETURN (SELECT team_num FROM team_users WHERE user_id = (SELECT auth.uid()));
REVOKE EXECUTE ON FUNCTION user_team_num FROM public, anon;

CREATE OR REPLACE FUNCTION
user_on_team(team_num smallint)
RETURNS BOOLEAN
LANGUAGE SQL
SET search_path = ''
STABLE
RETURNS NULL ON NULL INPUT
RETURN (SELECT user_team_num()) = team_num;
REVOKE EXECUTE ON FUNCTION user_on_team FROM public, anon;

CREATE OR REPLACE FUNCTION
user_on_same_team(user_id uuid)
RETURNS BOOLEAN
LANGUAGE SQL
SET search_path = ''
STABLE
RETURNS NULL ON NULL INPUT
RETURN user_id IN (
  SELECT user_id FROM team_users WHERE team_num = (SELECT user_team_num())
);
REVOKE EXECUTE ON FUNCTION user_on_same_team FROM public, anon;
