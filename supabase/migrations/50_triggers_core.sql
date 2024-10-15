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
AS $$
BEGIN
  NEW.created_at := now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_team FROM public, anon, authenticated;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  teams
FOR EACH ROW EXECUTE PROCEDURE
  insert_team();

-- users
CREATE FUNCTION insert_user()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.id := COALESCE(auth.uid(), NEW.id);
  NEW.created_at := now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_user FROM public, anon;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  users
FOR EACH ROW EXECUTE PROCEDURE
  insert_user();

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
