-- question-info
CREATE POLICY "Allow anyone to SELECT anything from question-info"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'question-info'
);

-- custom application data
-- four levels of access:
-- - user-data: only the owner can read/write
-- - team-data: only team members can read/write
-- - shared-data: anyone can read, but only the owner can write
-- - public-data: anyone can read/write

CREATE POLICY "Allow users to do anything with their user-data"
ON storage.objects TO authenticated
USING (
  bucket_id = 'user-data'
  AND
  (storage.foldername(name))[1] = (SELECT auth.uid()::text)
);

CREATE POLICY "Allow team members to do anything with their team-data"
ON storage.objects TO authenticated
USING (
  bucket_id = 'team-data'
  AND
  (storage.foldername(name))[1] = (SELECT get_team_num()::text)
);

CREATE POLICY "Allow anyone to SELECT files from shared-data"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'shared-data'
);

CREATE POLICY "Allow anyone to INSERT files into shared-data"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'shared-data'
);

CREATE POLICY "Allow users to UPDATE their own files within shared-data"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'shared-data'
  AND
  owner = (SELECT auth.uid())
)
WITH CHECK (
  bucket_id = 'shared-data'
  AND
  owner = (SELECT auth.uid())
);

CREATE POLICY "Allow users to DELETE their own files within shared-data"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'shared-data'
  AND
  owner = (SELECT auth.uid())
);

CREATE POLICY "Allow anyone to do anything within public-data"
ON storage.objects TO authenticated
USING (
  bucket_id = 'public-data'
);
