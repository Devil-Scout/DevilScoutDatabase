-- teams -------------------------------
GRANT SELECT, INSERT(number, name), UPDATE(name) ON TABLE teams TO authenticated;

CREATE POLICY "Anyone can SELECT any team"
ON teams FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Users not on a team can INSERT a new team"
ON teams FOR INSERT TO authenticated
WITH CHECK (
  (SELECT get_team_num() IS NULL)
);

CREATE POLICY "'manage_team' can UPDATE their team"
ON teams FOR UPDATE TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  number = (SELECT get_team_num())
);

CREATE POLICY "'manage_team' can DELETE their team"
  ON teams FOR DELETE TO  authenticated
  USING (
    (SELECT has_permission('manage_team'))
    AND
    number = (SELECT get_team_num())
  );

-- profiles -------------------------------
GRANT SELECT ON TABLE profiles TO authenticated;

CREATE POLICY "Anyone can SELECT themself or their team's members"
ON profiles FOR SELECT TO authenticated
USING (
  profiles.user_id = (SELECT auth.uid())
  OR
  is_user_on_same_team(profiles.user_id)
);

CREATE POLICY "'manage_team' can SELECT users requesting their team"
ON profiles FOR SELECT TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  EXISTS (
    SELECT 1 FROM team_requests
      WHERE
        team_requests.user_id = profiles.user_id AND
        team_requests.team_num = (SELECT get_team_num())
  )
);

GRANT ALL ON TABLE profiles TO supabase_auth_admin;

CREATE POLICY "Supabase Auth can read/write users"
ON profiles FOR ALL TO supabase_auth_admin
USING (true);

-- team_users --------------------------
GRANT SELECT, DELETE, INSERT (user_id, team_num) ON TABLE team_users TO authenticated;

CREATE POLICY "Team members can SELECT each other"
ON team_users FOR SELECT TO authenticated
USING (
  team_num = (SELECT get_team_num())
);

CREATE POLICY "Anyone can DELETE themself from their team"
ON team_users FOR DELETE TO authenticated
USING (
  user_id = (SELECT auth.uid())
);

CREATE POLICY "'manage_team' can DELETE users from their team"
ON team_users FOR DELETE TO authenticated
USING (
  team_num = (SELECT get_team_num())
);

CREATE POLICY "'manage_team' can INSERT users by request"
ON team_users FOR INSERT TO authenticated
WITH CHECK (
  (SELECT has_permission('manage_team'))
  AND
  (
    SELECT
      team_requests.team_num
    FROM
      team_requests
    WHERE team_requests.user_id = team_users.user_id
  ) = (SELECT get_team_num())
);

-- team_requests -----------------------
GRANT SELECT, DELETE, INSERT(team_num) ON TABLE team_requests TO authenticated;

CREATE POLICY "Anyone can SELECT, INSERT, or DELETE their request"
ON team_requests TO authenticated
USING (
  user_id = (SELECT auth.uid())
)
WITH CHECK(
  -- Not on a team already
  (SELECT get_team_num() IS NULL)
);

CREATE POLICY "'manage_team' can SELECT requests"
ON team_requests FOR SELECT TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  team_num = (SELECT get_team_num())
);

CREATE POLICY "'manage_team' can DELETE requests"
ON team_requests FOR DELETE TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  team_num = (SELECT get_team_num())
);

-- permissions -------------------------
GRANT SELECT, DELETE, INSERT(user_id, type) ON TABLE permissions TO authenticated;

CREATE POLICY "Anyone can SELECT their own permissions"
ON permissions FOR SELECT TO authenticated
USING (
  user_id = (SELECT auth.uid())
);

CREATE POLICY "'manage_team' can SELECT, INSERT, or DELETE permissions"
ON permissions TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  team_num = (SELECT get_team_num())
);
