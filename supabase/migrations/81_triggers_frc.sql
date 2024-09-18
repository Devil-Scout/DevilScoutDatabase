CREATE FUNCTION last_modified_frc() RETURNS TRIGGER
SET search_path TO ''
AS $$
BEGIN
  NEW.modified_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION last_modified_frc FROM public, anon, authenticated;

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_seasons
FOR EACH ROW EXECUTE PROCEDURE
  last_modified_frc();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_districts
FOR EACH ROW EXECUTE PROCEDURE
  last_modified_frc();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_events
FOR EACH ROW EXECUTE PROCEDURE
  last_modified_frc();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_teams
FOR EACH ROW EXECUTE PROCEDURE
  last_modified_frc();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_event_teams
FOR EACH ROW EXECUTE PROCEDURE
  last_modified_frc();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_matches
FOR EACH ROW EXECUTE PROCEDURE
  last_modified_frc();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_match_teams
FOR EACH ROW EXECUTE PROCEDURE
  last_modified_frc();

CREATE TRIGGER
  last_modified
BEFORE INSERT OR UPDATE ON
  frc_match_results
FOR EACH ROW EXECUTE PROCEDURE
  last_modified_frc();
