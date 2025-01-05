-- To allow overriding user_id on inserts iff auth.uid() is null:
-- ... := COALESCE(auth.uid(), NEW.user_id)
-- If auth.uid() is null, this indicates the user is not authenticated
-- But we only grant insert to authenticated, so the user must be service_role or higher
-- Also, we use a null id to indicate rows inserted by server maintainers
-- This allows null ids (where applicable) by simply omitting them

-- teams
CREATE FUNCTION pre_insert_team()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.created_at := now();
  NEW.created_by := auth.uid();
  RETURN NEW;
END;
$$;

CREATE FUNCTION post_insert_team()
RETURNS TRIGGER
LANGUAGE plpgsql
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
          id
        FROM permission_types
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

REVOKE EXECUTE ON FUNCTION pre_insert_team FROM public, anon;
REVOKE EXECUTE ON FUNCTION post_insert_team FROM public, anon;

CREATE TRIGGER
  pre_insert
BEFORE INSERT ON
  teams
FOR EACH ROW EXECUTE PROCEDURE
  pre_insert_team();

CREATE TRIGGER
  post_insert
BEFORE INSERT ON
  teams
FOR EACH ROW EXECUTE PROCEDURE
  post_insert_team();

-- auth.users
-- users table is read-only for clients
CREATE FUNCTION insert_users()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.users
    (id, name, created_at) VALUES
    (
      NEW.id,
      NEW.raw_user_meta_data->>'full_name',
      NEW.created_at
    );
  RETURN NEW;
END;
$$;

CREATE FUNCTION update_users()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.users
    SET
      name = NEW.raw_user_meta_data->>'full_name'
    WHERE
      id = NEW.id;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_users FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION update_users FROM public, anon, authenticated;

CREATE TRIGGER
  on_insert
AFTER INSERT ON
  auth.users
FOR EACH ROW EXECUTE PROCEDURE
  insert_users();

CREATE TRIGGER
  on_update
AFTER UPDATE ON
  auth.users
FOR EACH ROW EXECUTE PROCEDURE
  update_users();

-- team_users
CREATE FUNCTION insert_team_users()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.added_by := COALESCE(auth.uid(), NEW.added_by);
  NEW.added_at := now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_team_users FROM public, anon;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  team_users
FOR EACH ROW EXECUTE PROCEDURE
  insert_team_users();

-- team_requests
CREATE FUNCTION insert_team_requests()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.user_id := COALESCE(auth.uid(), NEW.user_id);
  NEW.requested_at := now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_team_requests FROM public, anon;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  team_requests
FOR EACH ROW EXECUTE PROCEDURE
  insert_team_requests();

-- disabled_users
CREATE FUNCTION insert_disabled_users()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.disabled_by := COALESCE(auth.uid(), NEW.disabled_by);
  NEW.disabled_at := now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_disabled_users FROM public, anon;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  disabled_users
FOR EACH ROW EXECUTE PROCEDURE
  insert_disabled_users();

-- permissions
CREATE FUNCTION insert_permissions()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.granted_by := COALESCE(auth.uid(), NEW.granted_by);
  NEW.granted_at := now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_permissions FROM public, anon;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  permissions
FOR EACH ROW EXECUTE PROCEDURE
  insert_permissions();
