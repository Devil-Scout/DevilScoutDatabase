-- teams -------------------------------
GRANT SELECT, UPDATE(name) ON TABLE teams TO authenticated;

CREATE POLICY "Anyone can SELECT any team"
ON teams FOR SELECT TO authenticated
USING (true);

CREATE POLICY "'manage_team' can UPDATE their team"
ON teams FOR UPDATE TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  (SELECT is_not_disabled())
  AND
  number = (SELECT get_team_num())
);

-- users -------------------------------
GRANT SELECT, INSERT(name), UPDATE(name) ON TABLE users TO authenticated;

CREATE POLICY "Anyone can SELECT their team's members"
ON users FOR SELECT TO authenticated
USING (
  is_user_on_same_team(users.id)
);

CREATE POLICY "Anyone can SELECT, INSERT, or UPDATE themself"
ON users TO authenticated
USING (
  id = (SELECT auth.uid())
)
WITH CHECK (
  -- Controlled by BEFORE INSERT
  -- id = (SELECT auth.uid())
  true
);

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

CREATE POLICY "'manage_team' can INSERT users by request"
ON team_users FOR INSERT TO authenticated
WITH CHECK (
  (SELECT has_permission('manage_team'))
  AND
  (SELECT is_not_disabled())
  AND
  (
    SELECT
      team_requests.team_num
    FROM
      team_requests
    WHERE team_requests.user_id = team_users.user_id
  ) = (SELECT get_team_num())
  AND
  -- Controlled by BEFORE INSERT trigger
  -- team_num = (SELECT get_team_num())
  -- AND
  -- team_users.added_by = (SELECT auth.uid())
  true
);

-- team_requests -----------------------
GRANT SELECT, DELETE, INSERT(team_num) ON TABLE team_requests TO public, anon, authenticated;

CREATE POLICY "Anyone can SELECT, INSERT, or DELETE their request"
ON team_requests TO authenticated
USING (
  user_id = (SELECT auth.uid())
)
WITH CHECK(
  -- Can only join a team if you aren't on a team
  (SELECT get_team_num() IS NULL)
  AND
  -- Controlled by BEFORE INSERT trigger
  -- user_id = (SELECT auth.uid())
  true
);

CREATE POLICY "'manage_team' can SELECT requests"
ON team_requests FOR SELECT TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  (SELECT is_not_disabled())
  AND
  team_num = (SELECT get_team_num())
);

CREATE POLICY "'manage_team' can DELETE requests"
ON team_requests FOR DELETE TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  (SELECT is_not_disabled())
  AND
  team_num = (SELECT get_team_num())
);

-- disabled_users ----------------------
GRANT SELECT, DELETE, INSERT(user_id) ON TABLE disabled_users TO authenticated;

CREATE POLICY "Anyone can SELECT their own entry"
ON disabled_users FOR SELECT TO authenticated
USING (
  user_id = (SELECT auth.uid())
);

CREATE POLICY "'manage_team' can SELECT, INSERT, or DELETE entries"
ON disabled_users TO authenticated
USING (
  (SELECT has_permission('manage_team'))
  AND
  (SELECT is_not_disabled())
  AND
  is_user_on_same_team(disabled_users.user_id)
)
WITH CHECK (
  (SELECT has_permission('manage_team'))
  AND
  (SELECT is_not_disabled())
  AND
  is_user_on_same_team(disabled_users.user_id)
);

-- permission_types --------------------
GRANT SELECT ON TABLE permission_types TO authenticated;

CREATE POLICY "Anyone can SELECT any permission type"
ON permission_types FOR SELECT TO authenticated
USING (true);

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
  (SELECT is_not_disabled())
  AND
  is_user_on_same_team(permissions.user_id)
)
WITH CHECK (
  (SELECT has_permission('manage_team'))
  AND
  (SELECT is_not_disabled())
  AND
  is_user_on_same_team(permissions.user_id)
);
