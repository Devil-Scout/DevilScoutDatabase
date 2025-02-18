-- https://supabase.com/docs/guides/database/postgres/custom-claims-and-role-based-access-control-rbac
CREATE FUNCTION public.jwt_claims_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  claims jsonb;
  user_team_num smallint;
  user_requested_team_num smallint;
  user_permissions public.permission_type[];
BEGIN
  claims := event->'claims';

  -- team
  SELECT team_num INTO user_team_num FROM public.team_users
    WHERE user_id = (event->>'user_id')::uuid;

  IF user_team_num IS NOT NULL THEN
    claims := jsonb_set(claims, '{team_num}', to_jsonb(user_team_num));
    claims := jsonb_set(claims, '{team_name}', to_jsonb(
      (
        SELECT name FROM public.teams t WHERE t.number = user_team_num
      )::text
    ));
  END IF;

  -- team request
  SELECT team_num INTO user_requested_team_num FROM public.team_requests
    WHERE user_id = (event->>'user_id')::uuid;

  IF user_requested_team_num IS NOT NULL THEN
    claims := jsonb_set(claims, '{requested_team_num}', to_jsonb(user_requested_team_num));
    claims := jsonb_set(claims, '{requested_team_name}', to_jsonb(
      (
        SELECT name FROM public.teams t WHERE t.number = user_requested_team_num
      )::text
    ));
  END IF;

  -- permissions
  SELECT array_agg(type) INTO user_permissions FROM public.permissions
    WHERE user_id = (event->>'user_id')::uuid;

  IF user_permissions IS NOT NULL THEN
    claims := jsonb_set(claims, '{permissions}', to_jsonb(user_permissions));
  END IF;

  -- Inject the claims into the event
  RETURN jsonb_set(event, '{claims}', claims);
END;
$$;

GRANT USAGE ON SCHEMA public TO supabase_auth_admin;

GRANT EXECUTE
  ON FUNCTION public.custom_access_token_hook
  TO supabase_auth_admin;

REVOKE EXECUTE
  ON FUNCTION public.custom_access_token_hook
  FROM authenticated, anon, public;

GRANT SELECT
  ON TABLE public.team_users
  TO supabase_auth_admin;

GRANT SELECT
  ON TABLE public.team_requests
  TO supabase_auth_admin;

GRANT SELECT
  ON TABLE public.permissions
  TO supabase_auth_admin;

CREATE POLICY "Supabase Auth can read team names" ON public.teams
  FOR SELECT TO supabase_auth_admin
  USING (true);

CREATE POLICY "Supabase Auth can read team numbers" ON public.team_users
  FOR SELECT TO supabase_auth_admin
  USING (true);

CREATE POLICY "Supabase Auth can read team requests" ON public.team_requests
  FOR SELECT TO supabase_auth_admin
  USING (true);

CREATE POLICY "Supabase Auth can read permissions" ON public.permissions
  FOR SELECT TO supabase_auth_admin
  USING (true);
