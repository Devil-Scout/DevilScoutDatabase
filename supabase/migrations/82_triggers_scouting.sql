-- submissions
CREATE FUNCTION insert_submissions() RETURNS TRIGGER
AS $$
DECLARE
  category public.categories%ROWTYPE;
BEGIN
  SELECT * INTO category
  FROM public.categories
  WHERE id = NEW.category;

  IF (NEW.match_key IS NULL) AND (category.has_match) THEN
    RAISE EXCEPTION 'match_key required for category';
  ELSIF (NEW.match_key IS NOT NULL) AND (NOT category.has_match) THEN
    RAISE EXCEPTION 'match_key not allowed for category';
  END IF;

  NEW.created_at := now();
  NEW.scouted_by := COALESCE(auth.uid(), NEW.scouted_by);
  NEW.scouted_for := COALESCE(get_team_num(), NEW.scouted_for);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION insert_submissions FROM public, anon;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  submissions
FOR EACH ROW EXECUTE PROCEDURE
  insert_submissions();

-- submission_data
CREATE FUNCTION insert_submission_data() RETURNS TRIGGER
AS $$
DECLARE
  submission public.submissions%ROWTYPE;
  question public.questions%ROWTYPE;
  question_section public.question_sections%ROWTYPE;
  data_type public.data_type;
BEGIN
  SELECT * INTO submission
  FROM public.submissions
  WHERE id = NEW.submission_id;

  SELECT * INTO question
  FROM public.questions
  WHERE id = NEW.question_id;

  SELECT * INTO question_section
  FROM public.question_sections
  WHERE id = question.section_id;

  SELECT type INTO data_type
  FROM public.question_types
  WHERE id = question.type;

  -- ensure question is permitted in this submission

  IF submission.season != question_section.season THEN
    RAISE EXCEPTION 'invalid question season for submission';
  END IF;

  IF submission.category != question_section.category THEN
    RAISE EXCEPTION 'invalid question category for submission';
  END IF;

  -- Ensure the correct value type was entered

  IF (
    SELECT COUNT(*)
    FROM (
      VALUES (NEW.value_bool, NEW.value_int, NEW.value_text)
    ) AS v(col)
    WHERE v.col IS NOT NULL
  ) != 1 THEN
    RAISE EXCEPTION 'exactly one value type is required';
  END IF;

  IF (NEW.value_bool IS NULL AND data_type = 'boolean') OR
      (NEW.value_int IS NULL AND data_type = 'int') OR
      (NEW.value_text IS NULL AND data_type = 'text') THEN
    RAISE EXCEPTION 'incorrect value type for question';
  END IF;

  -- Logic to verify valid values
  -- CASE ...

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION insert_submission_data FROM public, anon;

CREATE TRIGGER
  on_insert
BEFORE INSERT ON
  submission_data
FOR EACH ROW EXECUTE PROCEDURE
  insert_submission_data();
