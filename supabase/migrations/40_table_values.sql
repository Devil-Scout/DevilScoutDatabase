INSERT INTO
  permission_types (id, name, description)
VALUES
  (
    'manage_team',
    'Manage Team',
   E'- Approve requests to join your team\n'
    '- Disable/re-enable team members'
  ),
  (
    'scout.match',
    'Match Scouting',
   E'- Submit match scouting data'
  ),
  (
    'scout.pit',
    'Pit Scouting',
   E'- Submit pit scouting data'
  ),
  (
    'scout.drive_team',
    'Drive Team Scouting',
   E'- Submit drive team scouting data'
  );

INSERT INTO
  categories (id, has_match)
VALUES
  ('match', TRUE),
  ('pit', FALSE),
  ('drive_team', TRUE);
