-- question_types
ALTER TABLE question_types ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE question_types TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON question_types FOR SELECT TO authenticated
USING (true);

-- categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE categories TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON categories FOR SELECT TO authenticated
USING (true);

-- question_sections
ALTER TABLE question_sections ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE question_sections TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON question_sections FOR SELECT TO authenticated
USING (true);

-- questions
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE questions TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON questions FOR SELECT TO authenticated
USING (true);

-- submissions
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT (category, event_key, match_key, season, team_num, scouted_for) ON TABLE submissions TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON submissions FOR SELECT TO authenticated
USING (true);

CREATE POLICY "'scout.{category}' can INSERT {category} entries"
ON submissions FOR INSERT TO authenticated
WITH CHECK (
  (SELECT is_not_disabled())
  AND
  has_permission(('scout.' || category)::citext)
);

-- submission_data
ALTER TABLE submission_data ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT ON TABLE submission_data TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON submission_data FOR SELECT TO authenticated
USING (true);

CREATE POLICY "Anyone can INSERT data for their submission"
ON submission_data FOR INSERT TO authenticated
WITH CHECK (
  (SELECT is_not_disabled())
  AND
  (SELECT auth.uid())
  =
  (SELECT scouted_by FROM submissions WHERE submissions.id = submission_id)
  AND
  -- Verified by BEFORE INSERT trigger
  -- Question is allowed for submission (same season, same category)
  true
);
