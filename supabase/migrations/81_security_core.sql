-- teams -------------------------------

ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE teams FROM public, anon, authenticated;
GRANT SELECT, UPDATE(name) ON TABLE teams TO authenticated;

CREATE POLICY "Anyone can SELECT any team"
ON teams FOR SELECT TO authenticated
USING (true);

CREATE POLICY "'manage_team' can UPDATE their team"
ON teams FOR UPDATE TO authenticated
USING (
  (SELECT user_has_permission('manage_team'))
  AND
  user_on_team(teams.number)
);

-- users -------------------------------

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE users FROM public, anon, authenticated;
GRANT SELECT, INSERT(name), UPDATE(name) ON TABLE users TO authenticated;

CREATE POLICY "Anyone can SELECT their team's members"
ON users FOR SELECT TO authenticated
USING (
  user_on_same_team(users.id)
);

CREATE POLICY "Anyone can SELECT, INSERT, or UPDATE themself"
ON users TO authenticated
USING (
  id = (SELECT auth.uid())
);

-- team_users --------------------------

ALTER TABLE team_users ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE team_users FROM public, anon, authenticated;
GRANT SELECT, DELETE, INSERT ON TABLE team_users TO authenticated;

CREATE POLICY "Team members can SELECT each other"
ON team_users FOR SELECT TO authenticated
USING (
  user_on_team(team_users.team_num)
);

CREATE POLICY "Anyone can DELETE themself from a team"
ON team_users FOR DELETE TO authenticated
USING (
  user_id = (SELECT auth.uid())
);

CREATE POLICY "'manage_team' can INSERT users"
ON team_users FOR INSERT TO authenticated
WITH CHECK (
  (SELECT user_has_permission('manage_team'))
  AND
  user_on_team(team_users.team_num)
  AND
  team_users.added_by = (SELECT auth.uid())
);

-- team_requests -----------------------

ALTER TABLE team_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE team_requests FROM public, anon, authenticated;
GRANT SELECT, DELETE, INSERT(team_num) ON TABLE team_requests TO public, anon, authenticated;

CREATE POLICY "Anyone can SELECT, INSERT, or DELETE their request"
ON team_requests TO authenticated
USING (
  user_id = (SELECT auth.uid())
)
WITH CHECK(
  (SELECT user_team_num() IS NULL)
  AND
  user_id = (SELECT auth.uid())
);

CREATE POLICY "'manage_team' can SELECT requests"
ON team_requests FOR SELECT TO authenticated
USING (
  (SELECT user_has_permission('manage_team'))
  AND
  user_on_team(team_requests.team_num)
);

CREATE POLICY "'manage_team' can DELETE requests"
ON team_requests FOR DELETE TO authenticated
USING (
  (SELECT user_has_permission('manage_team'))
  AND
  user_on_team(team_requests.team_num)
);

-- disabled_users ----------------------

ALTER TABLE disabled_users ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE disabled_users FROM public, anon, authenticated;
GRANT SELECT, DELETE, INSERT(user_id) ON TABLE disabled_users TO authenticated;

CREATE POLICY "Anyone can SELECT their own entry"
ON disabled_users FOR SELECT TO authenticated
USING (
  user_id = (SELECT auth.uid())
);

CREATE POLICY "'manage_team' can SELECT, INSERT, or DELETE entries"
ON disabled_users TO authenticated
USING (
  (SELECT user_has_permission('manage_team'))
  AND
  user_on_same_team(disabled_users.user_id)
) WITH CHECK (
  (SELECT user_has_permission('manage_team'))
  AND
  user_on_same_team(disabled_users.user_id)
);

-- permission_types --------------------

ALTER TABLE permission_types ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE permission_types FROM public, anon, authenticated;
GRANT SELECT ON TABLE permission_types TO authenticated;

CREATE POLICY "Anyone can SELECT any permission type"
ON permission_types FOR SELECT TO authenticated
USING (true);

-- permissions -------------------------

ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
REVOKE ALL PRIVILEGES ON TABLE permissions FROM public, anon, authenticated;
GRANT SELECT, DELETE, INSERT(user_id, type) ON TABLE permissions TO authenticated;

CREATE POLICY "Anyone can SELECT their own permissions"
ON permissions FOR SELECT TO authenticated
USING (
  user_id = (SELECT auth.uid())
);

CREATE POLICY "'manage_team' can SELECT, INSERT, or DELETE permissions"
ON permissions TO authenticated
USING (
  (SELECT user_has_permission('manage_team'))
  AND
  user_on_same_team(permissions.user_id)
)
