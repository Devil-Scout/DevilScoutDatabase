-- teams -------------------------------

ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can SELECT any team"
ON teams FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Team members with 'manage_team' can UPDATE their own team"
ON teams FOR UPDATE TO authenticated
USING (
  auth_user_has_permission('manage_team')
  AND
  auth_user_team_num() = teams.number
);

REVOKE UPDATE ON TABLE teams FROM public, anon, authenticated;
GRANT UPDATE (name) ON TABLE teams TO authenticated;

-- users -------------------------------

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can SELECT their team's members"
ON users FOR SELECT TO authenticated
USING (
  user_team_num(users.id) = auth_user_team_num()
);

CREATE POLICY "Anyone can SELECT, INSERT, or UPDATE themself"
ON users TO authenticated
USING (
  id = auth.uid()
);

REVOKE DELETE ON TABLE users FROM public, anon, authenticated;
REVOKE UPDATE ON TABLE users FROM public, anon, authenticated;
GRANT UPDATE (name) ON TABLE users TO authenticated;

-- team_users --------------------------

ALTER TABLE team_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Team members can SELECT each other"
ON team_users FOR SELECT TO authenticated
USING (
  auth_user_team_num() = team_users.team_num
);

CREATE POLICY "Anyone can DELETE themself from a team"
ON team_users FOR DELETE TO authenticated
USING (
  user_id = auth.uid()
);

CREATE POLICY "Team members with 'manage_team' can INSERT users"
ON team_users FOR INSERT TO authenticated
WITH CHECK (
  auth_user_has_permission('manage_team')
  AND
  auth_user_team_num() = team_users.team_num
  AND
  team_users.added_by = auth.uid()
);

-- team_requests -----------------------

ALTER TABLE team_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can SELECT, INSERT, or DELETE their request"
ON team_requests TO authenticated
USING (
  user_id = auth.uid()
)
WITH CHECK(
  user_id = auth.uid()
  AND
  auth_user_team_num() IS NULL
);

REVOKE UPDATE ON TABLE team_requests FROM public, anon, authenticated;

CREATE POLICY "Team members with 'manage_team' can SELECT their team's requests"
ON team_requests FOR SELECT TO authenticated
USING (
  auth_user_has_permission('manage_team')
  AND
  auth_user_team_num() = team_requests.team_num
);

CREATE POLICY "Team members with 'manage_team' can DELETE their team's requests"
ON team_requests FOR DELETE TO authenticated
USING (
  auth_user_has_permission('manage_team')
  AND
  auth_user_team_num() = team_requests.team_num
);
