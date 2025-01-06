-- questions
GRANT SELECT ON TABLE questions TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON questions FOR SELECT TO authenticated
USING (true);

-- submissions
GRANT SELECT, INSERT (category, event_key, match_key, season, scouted_team) ON TABLE submissions TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON submissions FOR SELECT TO authenticated
USING (true);

CREATE POLICY "'scout.{category}' can INSERT {category} entries"
ON submissions FOR INSERT TO authenticated
WITH CHECK (
  has_permission(('scout.' || category)::citext)
);

-- submission_data
GRANT SELECT, INSERT ON TABLE submission_data TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON submission_data FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Anyone can INSERT data for their submission"
ON submission_data FOR INSERT TO authenticated
WITH CHECK (
  (
    SELECT
      (scouting_user = (SELECT auth.uid())) AND has_permission(('scout.' || category)::citext)
      FROM submissions
      WHERE submissions.id = submission_id
  )
);
