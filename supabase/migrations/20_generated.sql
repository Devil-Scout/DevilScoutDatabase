------------------------------
-- THIS IS A GENERATED FILE --
--  DO NOT MODIFY BY HAND   --
------------------------------

CREATE TYPE "frc_alliance" AS ENUM (
  'red',
  'blue'
);

CREATE TABLE "teams" (
  "number" smallint NOT NULL,
  "name" text NOT NULL,
  "created_at" timestamptz NOT NULL,
  PRIMARY KEY ("number") INCLUDE (name)
);

CREATE TABLE "users" (
  "id" uuid NOT NULL,
  "name" text NOT NULL,
  "created_at" timestamptz NOT NULL,
  PRIMARY KEY ("id") INCLUDE (name)
);

CREATE TABLE "team_users" (
  "user_id" uuid NOT NULL,
  "team_num" smallint NOT NULL,
  "added_by" uuid,
  "added_at" timestamptz NOT NULL,
  PRIMARY KEY ("user_id") INCLUDE (team_num)
);

CREATE TABLE "team_requests" (
  "user_id" uuid NOT NULL,
  "team_num" smallint NOT NULL,
  "requested_at" timestamptz NOT NULL,
  PRIMARY KEY ("user_id") INCLUDE (team_num, requested_at)
);

CREATE TABLE "disabled_users" (
  "user_id" uuid NOT NULL,
  "disabled_by" uuid NOT NULL,
  "disabled_at" timestamptz NOT NULL,
  PRIMARY KEY ("user_id")
);

CREATE TABLE "permission_types" (
  "id" citext NOT NULL,
  "name" text NOT NULL,
  "description" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "permissions" (
  "user_id" uuid NOT NULL,
  "permission_type" citext NOT NULL,
  "granted_by" uuid,
  "granted_at" timestamptz NOT NULL,
  PRIMARY KEY ("user_id", "permission_type")
);

CREATE TABLE "frc_seasons" (
  "year" smallint NOT NULL,
  "name" text NOT NULL,
  "team_count" smallint NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("year")
);

CREATE TABLE "frc_districts" (
  "season" smallint NOT NULL,
  "code" citext NOT NULL,
  "name" text NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("season", "code")
);

CREATE TABLE "frc_event_types" (
  "id" citext NOT NULL,
  "name" text NOT NULL,
  "frc_equivalents" text[] NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "frc_events" (
  "season" smallint NOT NULL,
  "code" citext NOT NULL,
  "type" citext NOT NULL,
  "name" text NOT NULL,
  "venue" text NOT NULL,
  "address" text NOT NULL,
  "city" text NOT NULL,
  "province" text NOT NULL,
  "country" text NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "district_code" citext,
  "website" text,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("season", "code")
);

CREATE TABLE "frc_teams" (
  "season" smallint NOT NULL,
  "number" smallint NOT NULL,
  "name" text NOT NULL,
  "rookie_season" smallint NOT NULL,
  "schools" text[] NOT NULL,
  "sponsors" text[] NOT NULL,
  "city" text NOT NULL,
  "province" text NOT NULL,
  "country" text NOT NULL,
  "district_code" citext,
  "website" text,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("season", "number")
);

CREATE TABLE "frc_event_teams" (
  "season" smallint NOT NULL,
  "event_code" citext NOT NULL,
  "team_num" smallint NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("season", "event_code", "team_num")
);

CREATE TABLE "frc_match_levels" (
  "id" citext NOT NULL,
  "name" citext NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "frc_matches" (
  "key" citext NOT NULL
    GENERATED ALWAYS AS
      (season || event_code || '_' || level || 's' || set || 'm' || number)
      STORED,
  "season" smallint NOT NULL,
  "event_code" citext NOT NULL,
  "level" citext NOT NULL,
  "set" smallint NOT NULL,
  "number" smallint NOT NULL,
  "name" text NOT NULL,
  "scheduled_for" timestamp NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("key")
);

CREATE TABLE "frc_match_teams" (
  "match_key" citext NOT NULL,
  "team_num" smallint NOT NULL,
  "alliance" frc_alliance NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("match_key", "team_num")
);

CREATE TABLE "frc_match_results" (
  "match_key" citext NOT NULL,
  "red_score" smallint NOT NULL,
  "blue_score" smallint NOT NULL,
  "red_breakdown" jsonb NOT NULL,
  "blue_breakdown" jsonb NOT NULL,
  "finished_at" timestamp NOT NULL,
  "video_url" text,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("match_key")
);

CREATE TABLE "question_types" (
  "id" citext NOT NULL,
  "name" text NOT NULL,
  "description" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "categories" (
  "id" citext NOT NULL,
  "has_match" bool NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "question_sections" (
  "id" uuid NOT NULL,
  "season" smallint NOT NULL,
  "category" citext NOT NULL,
  "index" smallint NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "questions" (
  "id" uuid NOT NULL,
  "section_id" uuid NOT NULL,
  "index" smallint NOT NULL,
  "prompt" text NOT NULL,
  "type" citext NOT NULL,
  "config" jsonb NOT NULL DEFAULT '{}',
  "info_filepath" text,
  PRIMARY KEY ("id")
);

CREATE TABLE "submissions" (
  "id" uuid NOT NULL,
  "category" citext NOT NULL,
  "season" smallint NOT NULL,
  "event_code" citext NOT NULL,
  "match_key" citext,
  "team_num" smallint NOT NULL,
  "scouted_by" uuid,
  "scouted_for" smallint,
  "created_at" timestamptz NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "submission_data" (
  "submission_id" uuid NOT NULL,
  "question_id" uuid NOT NULL,
  "value" text NOT NULL,
  PRIMARY KEY ("submission_id", "question_id")
);

CREATE UNIQUE INDEX ON "team_users" ("team_num", "user_id");

CREATE INDEX ON "team_users" ("team_num", "added_at");

CREATE INDEX ON "team_users" ("added_by");

CREATE INDEX ON "team_requests" ("team_num", "requested_at") INCLUDE (user_id);

CREATE INDEX ON "disabled_users" ("disabled_by");

CREATE INDEX ON "permissions" ("granted_by", "granted_at");

CREATE INDEX ON "frc_seasons" ("modified_at");

CREATE INDEX ON "frc_districts" ("modified_at");

CREATE INDEX ON "frc_events" ("season", "type", "code");

CREATE INDEX ON "frc_events" ("season", "name");

CREATE INDEX ON "frc_events" ("season", "country", "province");

CREATE INDEX ON "frc_events" ("season", "start_date", "end_date");

CREATE INDEX ON "frc_events" ("season", "district_code");

CREATE INDEX ON "frc_events" ("type");

CREATE INDEX ON "frc_events" ("modified_at");

CREATE UNIQUE INDEX ON "frc_teams" ("number", "season");

CREATE INDEX ON "frc_teams" ("season", "name");

CREATE INDEX ON "frc_teams" ("season", "rookie_season");

CREATE INDEX ON "frc_teams" ("season", "country", "province");

CREATE INDEX ON "frc_teams" ("season", "district_code");

CREATE INDEX ON "frc_teams" ("modified_at");

CREATE UNIQUE INDEX ON "frc_event_teams" ("team_num", "season", "event_code");

CREATE INDEX ON "frc_event_teams" ("season", "team_num");

CREATE INDEX ON "frc_event_teams" ("modified_at");

CREATE UNIQUE INDEX ON "frc_match_levels" ("name");

CREATE UNIQUE INDEX ON "frc_matches" ("season", "event_code", "level", "set", "number");

CREATE INDEX ON "frc_matches" ("season", "event_code", "scheduled_for");

CREATE INDEX ON "frc_matches" ("modified_at");

CREATE INDEX ON "frc_matches" ("level");

CREATE INDEX ON "frc_match_teams" ("team_num", "match_key");

CREATE INDEX ON "frc_match_teams" ("modified_at");

CREATE INDEX ON "frc_match_results" ("modified_at");

CREATE INDEX ON "frc_match_results" ("finished_at");

CREATE UNIQUE INDEX ON "question_sections" ("season", "category", "index");

COMMENT ON TABLE "teams" IS 'A team utilizing the platform';

COMMENT ON TABLE "users" IS 'A user of the platform';

COMMENT ON TABLE "team_users" IS 'A user''s association with a team';

COMMENT ON TABLE "team_requests" IS 'A user''s request to join a team';

COMMENT ON TABLE "disabled_users" IS 'A user whose privileges have been temporarily revoked';

COMMENT ON TABLE "permission_types" IS 'Types of permissions users may hold';

COMMENT ON TABLE "permissions" IS 'A user''s permission';

COMMENT ON TABLE "frc_seasons" IS 'A competition season with a unique game';

COMMENT ON TABLE "frc_districts" IS 'A district designation for a particular season';

COMMENT ON TABLE "frc_event_types" IS 'A type of competition event';

COMMENT ON TABLE "frc_events" IS 'An event or competition';

COMMENT ON TABLE "frc_teams" IS 'A team competing in a particular season';

COMMENT ON TABLE "frc_event_teams" IS 'A team competing in an event';

COMMENT ON TABLE "frc_match_levels" IS 'A level of competition for matches';

COMMENT ON TABLE "frc_matches" IS 'A match at an event';

COMMENT ON TABLE "frc_match_teams" IS 'A team competing in a match';

COMMENT ON TABLE "frc_match_results" IS 'The official results from the FMS for a match';

COMMENT ON TABLE "question_types" IS 'A type of scouting question shown to the user';

COMMENT ON TABLE "categories" IS 'A type of scouting data users can submit';

COMMENT ON TABLE "question_sections" IS 'A section within a set of scouting questions';

COMMENT ON TABLE "questions" IS 'A scouting question that users must answer';

COMMENT ON TABLE "submissions" IS 'A scouting data submission';

COMMENT ON TABLE "submission_data" IS 'A submission''s scouting data';

ALTER TABLE "team_users" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "team_users" ADD FOREIGN KEY ("team_num") REFERENCES "teams" ("number") ON DELETE CASCADE;

ALTER TABLE "team_users" ADD FOREIGN KEY ("added_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "team_requests" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "team_requests" ADD FOREIGN KEY ("team_num") REFERENCES "teams" ("number") ON DELETE CASCADE;

ALTER TABLE "disabled_users" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "disabled_users" ADD FOREIGN KEY ("disabled_by") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("permission_type") REFERENCES "permission_types" ("id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("granted_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "frc_districts" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("type") REFERENCES "frc_event_types" ("id") ON DELETE RESTRICT;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("season", "district_code") REFERENCES "frc_districts" ("season", "code") ON DELETE SET NULL;

ALTER TABLE "frc_teams" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_teams" ADD FOREIGN KEY ("season", "district_code") REFERENCES "frc_districts" ("season", "code") ON DELETE SET NULL;

ALTER TABLE "frc_event_teams" ADD FOREIGN KEY ("season", "event_code") REFERENCES "frc_events" ("season", "code") ON DELETE CASCADE;

ALTER TABLE "frc_event_teams" ADD FOREIGN KEY ("season", "team_num") REFERENCES "frc_teams" ("season", "number") ON DELETE CASCADE;

ALTER TABLE "frc_matches" ADD FOREIGN KEY ("season", "event_code") REFERENCES "frc_events" ("season", "code") ON DELETE CASCADE;

ALTER TABLE "frc_matches" ADD FOREIGN KEY ("level") REFERENCES "frc_match_levels" ("id") ON DELETE RESTRICT;

ALTER TABLE "frc_match_teams" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_results" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key");

ALTER TABLE "question_sections" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "questions" ADD FOREIGN KEY ("section_id") REFERENCES "question_sections" ("id");

ALTER TABLE "questions" ADD FOREIGN KEY ("type") REFERENCES "question_types" ("id") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("season", "event_code") REFERENCES "frc_events" ("season", "code") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("season", "team_num") REFERENCES "frc_teams" ("season", "number") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_for") REFERENCES "teams" ("number") ON DELETE SET NULL;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("submission_id") REFERENCES "submissions" ("id") ON DELETE CASCADE;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("question_id") REFERENCES "questions" ("id") ON DELETE RESTRICT;
