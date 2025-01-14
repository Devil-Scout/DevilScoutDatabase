-- submissions
ALTER TABLE submissions
  ALTER COLUMN scouting_team
  SET DEFAULT get_team_num();

CREATE FUNCTION insert_submissions()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  no_match_categories CONSTANT scouting_category[] := ARRAY['pit'];
BEGIN
  IF (NEW.match_key IS NULL) != (NEW.category = ANY(no_match_categories)) THEN
    RAISE EXCEPTION 'invalid match_key for category %s', NEW.category;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_submissions FROM public, anon;

CREATE TRIGGER on_insert
  BEFORE INSERT ON submissions
  FOR EACH ROW EXECUTE PROCEDURE insert_submissions();

-- submission_data
CREATE FUNCTION insert_submission_data()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  submission public.submissions%ROWTYPE;
  question public.questions%ROWTYPE;
BEGIN
  SELECT * INTO submission
  FROM public.submissions
  WHERE id = NEW.submission_id;

  SELECT * INTO question
  FROM public.questions
  WHERE id = NEW.question_id;

  -- ensure question is permitted in this submission

  IF submission.season != question.season THEN
    RAISE EXCEPTION 'invalid question season for submission';
  END IF;

  IF submission.category != question.category THEN
    RAISE EXCEPTION 'invalid question category for submission';
  END IF;

  -- Ensure the correct value type was entered

  -- Logic to verify valid values
  -- CASE ...

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION insert_submission_data FROM public, anon;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  submission_data
FOR EACH ROW EXECUTE PROCEDURE
  insert_submission_data();
