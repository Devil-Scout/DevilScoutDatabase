-- A team's name
SELECT
  name
FROM
  teams
WHERE
  number = ?;

-- List of teams' names and numbers, sorted
SELECT
  number,
  name
FROM
  teams
ORDER BY
  number;

-- A user's name
SELECT
  name
FROM
  users
WHERE
  id = ?;

-- A user's team number
SELECT
  team_num
FROM
  team_users
WHERE
  user_id = ?;

-- List of a team's users
SELECT
  users.id,
  users.name
FROM
  users
  INNER JOIN team_users ON users.id = team_users.user_id
WHERE
  team_users.team_num = ?;

-- A user's join request
SELECT
  team_num,
  requested_at
FROM
  team_requests
WHERE
  user_id = ?;

-- List of join requests for a team
SELECT
  users.user_id,
  users.name
FROM
  team_requests
  INNER JOIN users ON users.id = team_requests.user_id
WHERE
  team_requests.team_num = ?;

-- A user's disabled state
SELECT
  disabled_by IS NOT NULL AS is_disabled,
  disabled_by
FROM
  disabled_users
WHERE
  user_id = ?;

-- List of a team's users and disabled state
SELECT
  users.id,
  users.name,
  (disabled_users.disabled_by IS NOT NULL) AS is_disabled,
  disabled_users.disabled_by
FROM
  users
  INNER JOIN team_users ON users.id = team_users.user_id
  LEFT JOIN disabled_users ON users.id = disabled_users.user_id
WHERE
  team_users.team_num = ?;

-- List of a user's permissions
SELECT
  permission_type
FROM
  permissions
WHERE
  user_id = ?;

-- List of permissions on a team
SELECT
  permissions.user_id,
  users.name,
  permissions.permission_type
FROM
  permissions
  INNER JOIN users ON users.id = permissions.user_id
  INNER JOIN team_users ON users.id = team_users.user_id
WHERE
  team_users.team_num = ?;
