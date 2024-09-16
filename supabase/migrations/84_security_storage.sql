-- question-info
CREATE POLICY "Allow anyone to SELECT anything from question-info"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'question-info');
