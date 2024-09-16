INSERT INTO
  auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  )
VALUES
  (
    '00000000-0000-0000-0000-000000000000',
    '01234567-89ab-cdef-0123-456789abcdef',
    'authenticated',
    'authenticated',
    'test_user@example.com',
    crypt ('password123', gen_salt ('bf')),
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

INSERT INTO
  teams (number, name)
VALUES
  (1559, 'Devil Tech');

INSERT INTO
  users (id, name)
VALUES
  (
    '01234567-89ab-cdef-0123-456789abcdef',
    'Test User'
  );

INSERT INTO
  team_users (user_id, team_num)
VALUES
  ('01234567-89ab-cdef-0123-456789abcdef', 1559);

INSERT INTO
  permissions (user_id, permission_type)
VALUES
  (
    '01234567-89ab-cdef-0123-456789abcdef',
    'manage_team'
  );
