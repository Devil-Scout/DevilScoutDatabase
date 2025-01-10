ALTER TABLE profiles
ADD FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE;

CREATE FUNCTION frc_teams_search(query text)
RETURNS SETOF smallint
LANGUAGE sql
STABLE
AS $$
  SELECT frc_teams.number
    FROM frc_teams
      LEFT JOIN teams ON frc_teams.number = teams.number
    ORDER BY greatest(
      similarity(frc_teams.number::text, query),
      similarity(frc_teams.name, query),
      similarity(teams.name, query)
    ) DESC, frc_teams.number ASC;
$$;
