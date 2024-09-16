-- frc_seasons -------------------------
ALTER TABLE frc_seasons ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_seasons TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_seasons FOR SELECT TO authenticated
USING (true);

-- frc_districts -----------------------
ALTER TABLE frc_districts ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_districts TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_districts FOR SELECT TO authenticated
USING (true);

-- frc_events -----------------------
ALTER TABLE frc_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_events TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_events FOR SELECT TO authenticated
USING (true);

-- frc_district_events -----------------------
ALTER TABLE frc_district_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_district_events TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_district_events FOR SELECT TO authenticated
USING (true);

-- frc_teams -----------------------
ALTER TABLE frc_teams ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_teams TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_teams FOR SELECT TO authenticated
USING (true);

-- frc_district_teams -----------------------
ALTER TABLE frc_district_teams ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_district_teams TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_district_teams FOR SELECT TO authenticated
USING (true);

-- frc_event_teams -----------------------
ALTER TABLE frc_event_teams ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_event_teams TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_event_teams FOR SELECT TO authenticated
USING (true);

-- frc_matches -----------------------
ALTER TABLE frc_matches ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_matches TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_matches FOR SELECT TO authenticated
USING (true);

-- frc_match_teams -----------------------
ALTER TABLE frc_match_teams ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_match_teams TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_match_teams FOR SELECT TO authenticated
USING (true);

-- frc_match_results -----------------------
ALTER TABLE frc_match_results ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE frc_match_results TO authenticated;

CREATE POLICY "Anyone can SELECT anything"
ON frc_match_results FOR SELECT TO authenticated
USING (true);
