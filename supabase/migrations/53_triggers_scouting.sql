-- submissions
CREATE FUNCTION check_submission_match_key()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  no_match_categories CONSTANT scouting_category[] := ARRAY['pit'];
BEGIN
  IF (NEW.match_key IS NULL) != (NEW.category = ANY(no_match_categories)) THEN
    RAISE EXCEPTION 'invalid match_key for category %', NEW.category;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION check_submission_match_key FROM public, anon;

CREATE TRIGGER check_match_key
  BEFORE INSERT ON submissions
  FOR EACH ROW EXECUTE PROCEDURE check_submission_match_key();

-- submission_data
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
    RAISE EXCEPTION 'invalid question season for submission';
  END IF;

  IF submission.category != question.category THEN
    RAISE EXCEPTION 'invalid question category for submission';
  END IF;

  -- ensure correct value type was entered
  IF NEW.data_type != question.data_type THEN
    RAISE EXCEPTION 'improper data type for question';
  END IF;

  -- Logic to verify valid values
  CASE NEW.data_type
    WHEN 'boolean'::data_type THEN
      -- nothing: already valid
    WHEN 'number'::data_type THEN
      IF question.config ? 'min' AND NEW.data::numeric < (question.config->'min')::numeric THEN
        RAISE EXCEPTION 'data (number) may not be less than min';
      ELSIF question.config ? 'max' AND NEW.data::numeric > (question.config->'max')::numeric THEN
        RAISE EXCEPTION 'data (number) may not be greater than max';
      ELSIF question.config ? 'step' AND NEW.data::numeric % (question.config->'step')::numeric != 0 THEN
        RAISE EXCEPTION 'data (number) must be a multiple of step';
      END IF;

    WHEN 'string'::data_type THEN
      IF question.config ? 'len' AND length(NEW.data::text) > (question.config->'len')::numeric THEN
        RAISE EXCEPTION 'data (string) may not be longer than len';
      ELSIF question.config ? 'regex' AND regexp_count(NEW.data::text, question.config->>'regex') < 1 THEN
        RAISE EXCEPTION 'data (string) must match regex';
      ELSIF question.config ? 'options' AND NOT (question.config->'options') ? NEW.data::text THEN
        RAISE EXCEPTION 'data (string) must be one of options';
      END IF;

    WHEN 'array'::data_type THEN
      IF question.config ? 'options' AND NOT (question.config->'options')::text[] @> NEW.data::text[] THEN
        RAISE EXCEPTION 'data (array) must be subset of options';
      END IF;

    ELSE
      RAISE EXCEPTION 'unimplemented submission data type %', NEW.data_type;
  END CASE;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION validate_submission_data FROM public, anon;

-- must be after to compute data_type
CREATE TRIGGER validate
  AFTER INSERT ON submission_data
  FOR EACH ROW EXECUTE PROCEDURE validate_submission_data();
