INSERT INTO
  storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
  )
VALUES
  (
    'question-info',
    'question-info',
    FALSE,
    (1 * 1024 * 1024),
    '{ "text/markdown" }'
  ),
  (
    'user-data',
    'user-data',
    FALSE,
    (1 * 1024 * 1024),
    NULL
  ),
  (
    'team-data',
    'team-data',
    FALSE,
    (1 * 1024 * 1024),
    NULL
  ),
  (
    'shared-data',
    'shared-data',
    TRUE,
    (1 * 1024 * 1024),
    NULL
  ),
  (
    'public-data',
    'public-data',
    TRUE,
    (1 * 1024 * 1024),
    NULL
  )
ON CONFLICT (id) DO UPDATE
SET
  name = EXCLUDED.name,
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;
