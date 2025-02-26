-- Allow anyone to select anything from frc_*
DO $$
DECLARE
  row RECORD;
BEGIN
  FOR row IN (
    SELECT tablename
    FROM pg_tables AS t
    WHERE t.schemaname = 'public'
    AND t.tablename LIKE 'frc_%'
  )
  LOOP
    EXECUTE format(
      '
      GRANT SELECT ON TABLE %1$I TO authenticated;

      CREATE POLICY "Anyone can SELECT anything"
      ON %1$I FOR SELECT TO authenticated
      USING (true);
      ',
      row.tablename
    );
  END LOOP;
END;
$$;
