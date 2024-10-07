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
  ),
  (
    'pick_lists',
    'Pick Lists',
   E'- Create, edit, and delete pick lists'
    '- Manage sharing lists with other teams'
  );

INSERT INTO
  categories (id, has_match)
VALUES
  ('match', TRUE),
  ('pit', FALSE),
  ('drive_team', TRUE);

INSERT INTO
  question_types (id, name, type)
VALUES
  ('toggle', 'Toggle', 'boolean'),
  ('counter', 'Counter', 'int'),
  ('number', 'Number Input', 'int'),
  ('range', 'Range', 'int'),
  ('checkboxes', 'Checkboxes', 'text'),
  ('dropdown', 'Dropdown', 'text'),
  ('radio', 'Radio', 'text');

INSERT INTO frc_event_types
  (id, is_district, is_championship, is_division, is_offseason, name, name_short)
VALUES
  (0, FALSE, FALSE, FALSE, FALSE, 'Regional Event', 'Regional'),
  (1, TRUE, FALSE, FALSE, FALSE, 'District Event', 'District'),
  (2, TRUE, TRUE, FALSE, FALSE, 'District Championship', 'District Championship'),
  (3, FALSE, TRUE, TRUE, FALSE, 'Championship Division', 'Division'),
  (4, FALSE, TRUE, FALSE, FALSE, 'Championship Finals', 'Championship'),
  (5, TRUE, TRUE, TRUE, FALSE, 'District Championship Division', 'District Division'),
  (6, FALSE, FALSE, FALSE, FALSE, 'Festival of Champions', 'Festival'),
  (7, FALSE, FALSE, FALSE, FALSE, 'Remote', 'Remote'),
  (99, FALSE, FALSE, FALSE, TRUE, 'Offseason', 'Offseason'),
  (100, FALSE, FALSE, FALSE, TRUE, 'Preseason', 'Preseason');

INSERT INTO frc_match_levels
  (id, name)
VALUES
  ('qm', 'Qualifier'),
  ('ef', 'Elimination Final'),
  ('qf', 'Quarterfinal'),
  ('sf', 'Semifinal'),
  ('f', 'Final');

INSERT INTO frc_seasons
  (year, game_name)
VALUES
  (2024, 'Crescendo'),
  (2025, 'Reefscape');
