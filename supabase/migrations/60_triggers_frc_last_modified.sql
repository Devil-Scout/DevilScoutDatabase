CREATE FUNCTION last_modified() RETURNS TRIGGER AS $$
BEGIN
  NEW.last_modified := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION last_modified FROM public, anon, authenticated;

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_seasons
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_districts
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_events
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_district_events
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_teams
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_district_teams
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_event_teams
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_matches
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_match_teams
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_match_results
FOR EACH ROW EXECUTE PROCEDURE
  last_modified();
