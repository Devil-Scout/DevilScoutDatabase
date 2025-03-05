-- submissions
CREATE FUNCTION check_submission_match_key()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  no_match_categories CONSTANT scouting_category[] := ARRAY['pit'];
BEGIN
  IF (NEW.match_key IS NULL) != (NEW.category = ANY(no_match_categories)) THEN
    IF NEW.match_key IS NULL THEN
      RAISE EXCEPTION 'Submissions for category % require match_key', NEW.category;
    ELSE
      RAISE EXCEPTION 'Submissions for category % must not have match_key', NEW.category;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION check_submission_match_key FROM public, anon;

CREATE TRIGGER check_match_key
  BEFORE INSERT ON submissions
  FOR EACH ROW EXECUTE PROCEDURE check_submission_match_key();

-- submission_data
CREATE FUNCTION json_to_array(arr json)
RETURNS text[]
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT coalesce(
    array_agg(e),
    CASE
      WHEN arr IS NULL THEN NULL
      ELSE ARRAY[]::text[]
    END
  )
  FROM json_array_elements_text(arr) j(e);
$$;

CREATE FUNCTION jsonb_to_array(arr jsonb)
RETURNS text[]
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT coalesce(
    array_agg(e),
    CASE
      WHEN arr IS NULL THEN NULL
      ELSE ARRAY[]::text[]
    END
  )
  FROM jsonb_array_elements_text(arr) j(e);
$$;

CREATE FUNCTION validate_submission_data()
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
    RAISE EXCEPTION 'Question from season % does not match submission season %', question.season, submission.season;
  END IF;

  IF submission.category != question.category THEN
    RAISE EXCEPTION 'Question category % does not match submission category %', question.category, submission.category;
  END IF;

  -- ensure correct value type was entered

  IF (
    (NEW.data_num IS NOT NULL AND question.data_type != 'number') OR
    (NEW.data_bool IS NOT NULL AND question.data_type != 'boolean') OR
    (NEW.data_str IS NOT NULL AND question.data_type != 'string') OR
    (NEW.data_arr IS NOT NULL AND question.data_type != 'array')
  ) THEN
    RAISE EXCEPTION 'Question % expects data_type % but submission contained %', question.id, question.data_type, NEW.data_type;
  END IF;

  IF (
    NEW.data_num IS NULL AND
    NEW.data_bool IS NULL AND
    NEW.data_str IS NULL AND
    NEW.data_arr IS NULL
  ) THEN
    RAISE EXCEPTION 'Question % expects non-null data_type % but submission contained NULL', question.id, question.data_type;
  END IF;

  -- Logic to verify valid values
  CASE
    WHEN NEW.data_bool IS NOT NULL THEN
      -- nothing: already valid

    WHEN NEW.data_num IS NOT NULL THEN
      IF question.config ? 'min' AND NEW.data_num < (question.config->'min')::numeric THEN
        RAISE EXCEPTION 'Number for question % expected to be at least % but submission contained %', question.id, (question.config->'min'), NEW.data;
      ELSIF question.config ? 'max' AND NEW.data_num > (question.config->'max')::numeric THEN
        RAISE EXCEPTION 'Number for question % expected to be at least % but submission contained %', question.id, (question.config->'max'), NEW.data;
      ELSIF question.config ? 'step' AND NEW.data_num % (question.config->'step')::numeric != 0 THEN
        RAISE EXCEPTION 'Number for question % expected to be a multiple of % but submission contained %', question.id, (question.config->'step'), NEW.data;
      END IF;

    WHEN NEW.data_str IS NOT NULL THEN
      IF question.config ? 'len' AND length(NEW.data_str) > (question.config->'len')::numeric THEN
        RAISE EXCEPTION 'String for question % expected to be no longer than % characters', question.id, (question.config->'len');
      ELSIF question.config ? 'regex' AND regexp_count(NEW.data_str, question.config->>'regex') < 1 THEN
        RAISE EXCEPTION 'String for question % expected to match regex %', question.id, (question.config->'regex');
      ELSIF question.config ? 'options' AND NOT (question.config->'options') ? NEW.data_str THEN
        RAISE EXCEPTION 'String for question % expected one of the provided options', question.id;
      END IF;

    WHEN NEW.data_arr IS NOT NULL THEN
      IF question.config ? 'options' AND NOT jsonb_to_array(question.config->'options') @> NEW.data_arr THEN
        RAISE EXCEPTION 'Array for question % expected a subset of the provided options', question.id;
      END IF;

    ELSE
      RAISE EXCEPTION 'assert: invalid data_type % for submission_data', NEW.data_type;
  END CASE;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION validate_submission_data FROM public, anon;

CREATE TRIGGER validate
  AFTER INSERT ON submission_data
  FOR EACH ROW EXECUTE PROCEDURE validate_submission_data();
