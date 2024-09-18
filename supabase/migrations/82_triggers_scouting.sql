-- submissions
CREATE FUNCTION insert_submissions() RETURNS TRIGGER
AS $$
DECLARE
  category categories%ROWTYPE;
BEGIN
  SELECT * INTO category
  FROM categories
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
  question questions%ROWTYPE;
  submission submissions%ROWTYPE;
BEGIN
  SELECT * INTO question
  FROM questions
  WHERE id = NEW.question_id;
  SELECT * INTO submission
  FROM submissions
  WHERE id = NEW.submission_id;

  IF submission.category <> category.category THEN
    RAISE EXCEPTION 'invalid question category for submission';
  END IF;

  IF submission.season <> (SELECT season FROM question_sections WHERE id = question.section_id) THEN
    RAISE EXCEPTION 'invalid question season for submission';
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
