CREATE FUNCTION last_modified_frc()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.modified_at := now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION last_modified_frc FROM public, anon, authenticated;

-- Add trigger to every applicable frc_* table
DO $$
DECLARE
  excluded CONSTANT text[] := ARRAY[
    'frc_event_types',
    'frc_match_levels'
  ];
  row RECORD;
BEGIN
  FOR row IN (
    SELECT
      tablename
    FROM
      pg_tables AS t
    WHERE
      t.schemaname = 'public' AND
      t.tablename LIKE 'frc_%' AND
      t.tablename != all(excluded)
  )
  LOOP
    EXECUTE format(
      '
      CREATE TRIGGER
        last_modified
      BEFORE INSERT OR UPDATE ON
        %1$I
      FOR EACH ROW EXECUTE PROCEDURE
        last_modified_frc();
      ',
      row.tablename
    );
  END LOOP;
END;
$$;
