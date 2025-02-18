-- Auto update sync.etags timestamps
CREATE FUNCTION sync.etags_modified_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD IS NULL OR OLD.value != NEW.value THEN
    NEW.modified_at := now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER modified_at
BEFORE INSERT OR UPDATE ON sync.etags
FOR EACH ROW EXECUTE FUNCTION sync.etags_modified_at();
