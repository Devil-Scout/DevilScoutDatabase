-- To allow overriding user_id on inserts iff auth.uid() is null:
-- ... := COALESCE(auth.uid(), NEW.user_id)
-- If auth.uid() is null, this indicates the user is not authenticated
-- But we only grant insert to authenticated, so the user must be service_role or higher
-- Also, we use a null id to indicate rows inserted by server maintainers
-- This allows null ids (where applicable) by simply omitting them

-- teams
CREATE FUNCTION register_team()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF auth.uid() IS NOT NULL
  THEN
    -- Make the user a member
    INSERT INTO team_users
      (user_id, team_num) VALUES
      (auth.uid(), NEW.number);

    -- Grant them all permissions
    INSERT INTO permissions
      (user_id, team_num, type)
      (
        SELECT
          (SELECT auth.uid()),
          NEW.number,
          type
        FROM unnest(enum_range(NULL::permission_type)) AS type
      );
  END IF;

  IF NOT NEW.verified
  THEN
    -- Notify developers of new unverified team via email
    PERFORM net.http_post(
      url := 'https://api.resend.com/emails',
      body := jsonb_build_object(
        'from', 'Devil Scout Notifier <notify@devilscout.org>',
        'to', 'devilscoutfrc@gmail.com',
        'subject', 'Unverified Team Created',
        'html', format(
          '<p>Dear Developer,</p>'
          '<p>A user just registered team %s, which is marked as unverified in the database. Please review the team''s owner and mark the team as verified.</p>'
          '<p>Best, Devil Scout''s Database</p>', NEW.number
        )
      ),
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || (
          SELECT decrypted_secret
          FROM vault.decrypted_secrets
          WHERE name = 'resend_api_key'
        )
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION register_team FROM public, anon;

CREATE TRIGGER register
  AFTER INSERT ON teams
  FOR EACH ROW EXECUTE PROCEDURE register_team();

-- auth.users
-- profiles table is read-only for clients
CREATE FUNCTION create_user_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.profiles
    (user_id, name, created_at) VALUES
    (
      NEW.id,
      NEW.raw_user_meta_data->>'full_name',
      NEW.created_at
    );
  RETURN NEW;
END;
$$;

CREATE FUNCTION update_user_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.profiles
    SET
      name = NEW.raw_user_meta_data->>'full_name'
    WHERE
      user_id = NEW.id;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION create_user_profile FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION update_users FROM public, anon, authenticated;

CREATE TRIGGER create_profile
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE PROCEDURE create_user_profile();

CREATE TRIGGER update_profile
AFTER UPDATE ON auth.users
FOR EACH ROW EXECUTE PROCEDURE update_user_profile();

-- team_users
CREATE FUNCTION delete_team_request()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM public.team_requests request
    WHERE request.user_id = NEW.user_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER delete_request
  AFTER INSERT ON public.team_users
  FOR EACH ROW EXECUTE PROCEDURE delete_team_request();

-- team_requests
CREATE FUNCTION validate_team_request()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.team_users
    WHERE user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'Team member % cannot request to join a team', NEW.user_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate
  BEFORE INSERT ON public.team_requests
  FOR EACH ROW EXECUTE PROCEDURE validate_team_request();

-- permissions
CREATE FUNCTION require_admin()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF (
    OLD.type = 'team.admin'::public.permission_type
  ) AND NOT EXISTS (
    SELECT 1 FROM public.permissions
    WHERE
      team_num = OLD.team_num AND
      type = 'team.admin'::public.permission_type
  ) AND EXISTS (
    SELECT 1 FROM public.teams
    WHERE number = OLD.team_num
  ) THEN
    RAISE EXCEPTION 'Team % must have at least one member with team.admin permission', OLD.team_num;
  END IF;

  RETURN NEW;
END;
$$;

GRANT SELECT ON TABLE teams TO supabase_auth_admin;

-- deferrable for deleting a team
CREATE CONSTRAINT TRIGGER on_delete
  AFTER DELETE ON permissions DEFERRABLE
  FOR EACH ROW EXECUTE PROCEDURE require_admin();
