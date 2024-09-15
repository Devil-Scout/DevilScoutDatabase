INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES
(
  '00000000-0000-0000-0000-000000000000',
  '01234567-89ab-cdef-0123-456789abcdef',
  'authenticated',
  'authenticated',
  'test_user@example.com',
  crypt ('password123', gen_salt ('bf')),
  current_timestamp,
  current_timestamp,
  current_timestamp,
  '{"provider":"email","providers":["email"]}',
  '{}',
  current_timestamp,
  current_timestamp,
  '',
  '',
  '',
  ''
);

INSERT INTO teams (number, name) VALUES
(1559, 'Devil Tech');

INSERT INTO users (id, name) VALUES
('01234567-89ab-cdef-0123-456789abcdef', 'Test User');

INSERT INTO team_users (user_id, team_num, added_by) VALUES
('01234567-89ab-cdef-0123-456789abcdef', 1559, '01234567-89ab-cdef-0123-456789abcdef');

INSERT INTO permissions (user_id, permission_type, granted_by) VALUES
('01234567-89ab-cdef-0123-456789abcdef', 'manage_team', '01234567-89ab-cdef-0123-456789abcdef');
