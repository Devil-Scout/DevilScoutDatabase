-- To allow overriding user_id on inserts iff auth.uid() is null:
-- ... := COALESCE(auth.uid(), NEW.user_id)
-- If auth.uid() is null, this indicates the user is not authenticated
-- But we only grant insert to authenticated, so the user must be service_role or higher
-- Also, we use a null id to indicate rows inserted by server maintainers
-- This allows null ids (where applicable) by simply omitting them

-- teams
CREATE FUNCTION insert_team()
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

REVOKE EXECUTE ON FUNCTION insert_team FROM public, anon;

CREATE TRIGGER on_insert
  AFTER INSERT ON teams
  FOR EACH ROW EXECUTE PROCEDURE insert_team();

-- auth.users
-- profiles table is read-only for clients
CREATE FUNCTION insert_users()
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

CREATE FUNCTION update_users()
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
ALTER TABLE team_users
  ALTER COLUMN team_num
  SET DEfAULT get_team_num();

CREATE FUNCTION insert_team_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM team_requests
    WHERE user_id = NEW.user_id;

  UPDATE auth.users
    SET raw_user_meta_data = jsonb_set(
      raw_user_meta_data,
      '{team_num}',
      NEW.team_num
    )
    WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$;

CREATE FUNCTION delete_team_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE auth.users
    SET raw_user_meta_data = jsonb_set(
      raw_user_meta_data,
      '{team_num}',
      NULL
    )
    WHERE id = OLD.user_id;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_team_users FROM public, anon;
REVOKE EXECUTE ON FUNCTION delete_team_users FROM public, anon;

CREATE TRIGGER on_insert
  AFTER INSERT ON team_users
  FOR EACH ROW EXECUTE PROCEDURE insert_team_users();

CREATE TRIGGER on_delete
  AFTER DELETE ON team_users
  FOR EACH ROW EXECUTE PROCEDURE delete_team_users();

-- permissions
ALTER TABLE permissions
  ALTER COLUMN team_num
  SET DEFAULT get_team_num();
