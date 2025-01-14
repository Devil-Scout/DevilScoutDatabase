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

CREATE FUNCTION frc_events_search(year smallint, query text)
RETURNS SETOF citext
LANGUAGE sql
STABLE
AS $$
  SELECT e.key
    FROM frc_events e
    WHERE e.season = year
    ORDER BY greatest(
      similarity(e.key::text, query),
      similarity(e.name::text, query)
    ) DESC, e.key ASC;
$$;
